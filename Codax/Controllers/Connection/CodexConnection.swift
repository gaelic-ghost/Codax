//
//  CodexConnection.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import AsyncAlgorithms
import Foundation

	// MARK: - Connection Layer Actor

public actor CodexConnection {
	private final class OneShotReply: Sendable {
		private let channel = AsyncThrowingChannel<Data, Error>()

		func wait() async throws -> Data {
			var iterator = channel.makeAsyncIterator()
			guard let data = try await iterator.next() else {
				throw CodexConnectionError.disconnected
			}
			return data
		}

		func succeed(_ data: Data) async {
			await channel.send(data)
			channel.finish()
		}

		func fail(_ error: Error) {
			channel.fail(error)
		}

		func finish() {
			channel.finish()
		}
	}

	private struct RetryConfiguration: Sendable {
		let maxRetryCount: Int
		let baseDelayNanos: UInt64
		let maxDelayNanos: UInt64
		let jitterRatio: Double

		static let `default` = RetryConfiguration(
			maxRetryCount: 3,
			baseDelayNanos: 250_000_000,
			maxDelayNanos: 2_000_000_000,
			jitterRatio: 0.2
		)
	}

	private enum ConnectionStatus {
		case idle
		case running
		case stopping
	}

	typealias Sleep = @Sendable (UInt64) async throws -> Void
	typealias Random = @Sendable () -> Double

	let trans: CodexTransport
	let reqHandler: CodexServerRequestHandler?
	private let encoder = JSONEncoder()
	private let decoder = JSONDecoder()
	private let retryConfiguration: RetryConfiguration
	private let sleep: Sleep
	private let random: Random

	private var nextNumericRequestID: Int64 = 0
	private var pendingRequests: [JSONRPCID: OneShotReply] = [:]
	private var receiveLoopTask: Task<Void, Never>?
	private var notificationContinuations: [UUID: AsyncStream<ServerNotificationEnvelope>.Continuation] = [:]
	private var status: ConnectionStatus = .idle

	public init(
		transport tr: any CodexTransport,
		requestHandler rH: (any CodexServerRequestHandler)? = nil
	) {
		self.trans = tr
		self.reqHandler = rH
		self.retryConfiguration = .default
		self.sleep = { try await Task.sleep(nanoseconds: $0) }
		self.random = { Double.random(in: 0 ..< 1) }
	}

	internal init(
		transport tr: any CodexTransport,
		requestHandler rH: (any CodexServerRequestHandler)? = nil,
		maxRetryCount: Int,
		retryBaseDelayNanos: UInt64,
		retryMaxDelayNanos: UInt64,
		retryJitterRatio: Double,
		sleep: @escaping Sleep,
		random: @escaping Random
	) {
		self.trans = tr
		self.reqHandler = rH
		self.retryConfiguration = RetryConfiguration(
			maxRetryCount: maxRetryCount,
			baseDelayNanos: retryBaseDelayNanos,
			maxDelayNanos: retryMaxDelayNanos,
			jitterRatio: retryJitterRatio
		)
		self.sleep = sleep
		self.random = random
	}

	public func start() async {
		guard status == .idle else { return }
		status = .running
		receiveLoopTask = Task {
			await self.runReceiveLoop()
		}
	}

	public func stop() async {
		guard status != .idle else { return }

		status = .stopping
		let task = receiveLoopTask
		receiveLoopTask = nil
		let pending = pendingRequests
		pendingRequests.removeAll()
		let continuations = Array(notificationContinuations.values)
		notificationContinuations.removeAll()
		status = .idle

		task?.cancel()
		await trans.close()
		fail(pending: pending, with: CodexConnectionError.disconnected)
		finish(continuations: continuations)
	}

	public func request<Params: Encodable, Result: Decodable>(
		method: String,
		params: Params,
		as resultType: Result.Type
	) async throws -> Result {
		await start()

		var attempt = 0
		var lastOverloadError: CodexConnectionError?

		while true {
			do {
				return try await requestOnce(method: method, params: params, as: resultType)
			} catch let error as CodexConnectionError {
				guard error.isRetryableOverload else {
					throw error
				}
				lastOverloadError = error
				guard attempt < retryConfiguration.maxRetryCount else {
					throw lastOverloadError ?? error
				}
				guard status == .running else {
					throw CodexConnectionError.disconnected
				}
				try await sleep(retryDelayNanos(forAttempt: attempt))
				guard status == .running else {
					throw CodexConnectionError.disconnected
				}
				attempt += 1
			} catch {
				throw error
			}
		}
	}

	public func notify<Params: Encodable>(
		method: String,
		params: Params
	) async throws {
		await start()
		let payload = try encoder.encode(JSONRPCNotificationMessage(method: method, params: params))
		try await trans.send(payload)
	}

	public func notify(method: String) async throws {
		await start()
		let payload = try encoder.encode(JSONRPCClientNotificationMessage(method: method))
		try await trans.send(payload)
	}

	public nonisolated func notifications() -> AsyncStream<ServerNotificationEnvelope> {
		AsyncStream { continuation in
			let id = UUID()

			Task {
				let shouldFinishImmediately = await self.addNotificationContinuation(continuation, id: id)
				if shouldFinishImmediately {
					continuation.finish()
				}
			}

			continuation.onTermination = { _ in
				Task {
					await self.removeNotificationContinuation(id: id)
				}
			}
		}
	}
}

// MARK: - Internal Helpers

private extension CodexConnection {
	private func addNotificationContinuation(
		_ continuation: AsyncStream<ServerNotificationEnvelope>.Continuation,
		id: UUID
	) -> Bool {
		guard status != .stopping else { return true }
		notificationContinuations[id] = continuation
		return false
	}

	private func requestOnce<Params: Encodable, Result: Decodable>(
		method: String,
		params: Params,
		as resultType: Result.Type
	) async throws -> Result {
		guard status == .running else {
			throw CodexConnectionError.disconnected
		}

		let id = makeRequestID()
		let waiter = OneShotReply()
		pendingRequests[id] = waiter

		do {
			let payload = try encoder.encode(JSONRPCRequestMessage(id: id, method: method, params: params))
			try await trans.send(payload)
			let data = try await waiter.wait()
			pendingRequests.removeValue(forKey: id)
			return try decoder.decode(Result.self, from: data)
		} catch {
			pendingRequests.removeValue(forKey: id)
			waiter.finish()
			throw error
		}
	}

	private func makeRequestID() -> JSONRPCID {
		defer { nextNumericRequestID += 1 }
		return .int(nextNumericRequestID)
	}

	private func retryDelayNanos(forAttempt attempt: Int) -> UInt64 {
		let exponent = min(attempt, 16)
		let multiplier = UInt64(1 << exponent)
		let cappedBase = retryConfiguration.baseDelayNanos.multipliedReportingOverflow(by: multiplier)
		let rawDelay = cappedBase.overflow
			? retryConfiguration.maxDelayNanos
			: min(cappedBase.partialValue, retryConfiguration.maxDelayNanos)

		let jitterScale = max(0, min(1, retryConfiguration.jitterRatio))
		let offset = (random() * 2) - 1
		let jitterMultiplier = max(0, 1 + (offset * jitterScale))
		let jittered = Double(rawDelay) * jitterMultiplier
		return min(UInt64(jittered.rounded()), retryConfiguration.maxDelayNanos)
	}

	private func runReceiveLoop() async {
		do {
			while !Task.isCancelled {
				let message = try await trans.receive()
				try await handleInboundMessage(message)
			}
		} catch {
			await finishReceiveLoop(with: error)
		}
	}

	private func finishReceiveLoop(with error: Error) async {
		guard status != .idle else {
			receiveLoopTask = nil
			return
		}

		status = .stopping
		receiveLoopTask = nil
		let pending = pendingRequests
		pendingRequests.removeAll()
		let continuations = Array(notificationContinuations.values)
		notificationContinuations.removeAll()
		status = .idle

		await trans.close()
		fail(pending: pending, with: error)
		finish(continuations: continuations)
	}

	private func handleInboundMessage(_ message: Data) async throws {
		guard
			let object = try JSONSerialization.jsonObject(with: message, options: [.fragmentsAllowed]) as? [String: Any]
		else {
			throw CodexConnectionError.invalidMessage
		}

		if object["method"] != nil {
			try await handleInboundMethodObject(object)
			return
		}

		let id = try object["id"].map(JSONRPCID.init(rawValue:))

		if let result = object["result"] {
			guard let id else {
				throw CodexConnectionError.invalidMessage
			}
			await completePendingRequest(id: id, with: try rawData(from: result))
			return
		}

		if let errorObject = object["error"] {
			let error = try decoder.decode(JSONRPCErrorObject.self, from: try rawData(from: errorObject))
			if let id {
				failPendingRequest(id: id, error: CodexConnectionError.serverError(error))
			}
			return
		}

		throw CodexConnectionError.invalidMessage
	}

	private func handleInboundMethodObject(_ object: [String: Any]) async throws {
		guard let method = object["method"] as? String else {
			throw CodexConnectionError.invalidMessage
		}

		let paramsData = try rawData(from: object["params"] ?? [:])

		if let idValue = object["id"] {
			let requestID = try JSONRPCID(rawValue: idValue)
			let request = try ServerRequestEnvelope.decode(
				method: method,
				id: requestID,
				params: paramsData,
				decoder: decoder
			)
			try await handleServerRequest(request)
		} else {
			let notification = try ServerNotificationEnvelope.decode(
				method: method,
				params: paramsData,
				decoder: decoder
			)
			yield(notification: notification)
		}
	}

	private func handleServerRequest(_ request: ServerRequestEnvelope) async throws {
		guard let reqHandler else {
			try await sendErrorResponse(
				id: request.id,
				error: JSONRPCErrorObject(code: -32601, message: "No server request handler is installed.")
			)
			return
		}

		switch await reqHandler.handle(request) {
		case let .commandApproval(response):
			try await sendResponse(id: request.id, result: response)
		case let .fileChangeApproval(response):
			try await sendResponse(id: request.id, result: response)
		case let .userInput(response):
			try await sendResponse(id: request.id, result: response)
		case let .mcpServerElicitation(response):
			try await sendResponse(id: request.id, result: response)
		case let .dynamicToolCall(response):
			try await sendResponse(id: request.id, result: response)
		case let .chatgptAuthRefresh(response):
			try await sendResponse(id: request.id, result: response)
		case let .applyPatchApproval(response):
			try await sendResponse(id: request.id, result: response)
		case let .execCommandApproval(response):
			try await sendResponse(id: request.id, result: response)
		case .unhandled:
			try await sendErrorResponse(
				id: request.id,
				error: JSONRPCErrorObject(code: -32601, message: "Unhandled server request.")
			)
		}
	}

	private func sendResponse<Result: Encodable>(id: JSONRPCID, result: Result) async throws {
		let payload = try encoder.encode(JSONRPCResponseEnvelope(id: id, result: result))
		try await trans.send(payload)
	}

	private func sendErrorResponse(id: JSONRPCID, error: JSONRPCErrorObject) async throws {
		let payload = try encoder.encode(JSONRPCErrorEnvelope(id: id, error: error))
		try await trans.send(payload)
	}

	private func rawData(from value: Any) throws -> Data {
		try JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed])
	}

	private func completePendingRequest(id: JSONRPCID, with data: Data) async {
		guard let waiter = pendingRequests.removeValue(forKey: id) else { return }
		await waiter.succeed(data)
	}

	private func failPendingRequest(id: JSONRPCID, error: Error) {
		guard let waiter = pendingRequests.removeValue(forKey: id) else { return }
		waiter.fail(error)
	}

	private func fail(pending: [JSONRPCID: OneShotReply], with error: Error) {
		for waiter in pending.values {
			waiter.fail(error)
		}
	}

	private func yield(notification: ServerNotificationEnvelope) {
		for continuation in notificationContinuations.values {
			continuation.yield(notification)
		}
	}

	private func finish(continuations: [AsyncStream<ServerNotificationEnvelope>.Continuation]) {
		for continuation in continuations {
			continuation.finish()
		}
	}

	private func removeNotificationContinuation(id: UUID) {
		notificationContinuations.removeValue(forKey: id)
	}
}
