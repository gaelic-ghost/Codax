//
//  CodexConnection.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import Foundation

public actor CodexConnection {
	private struct PendingRequest: Sendable {
		let succeed: @Sendable (Data) -> Void
		let fail: @Sendable (Error) -> Void
	}

	let trans: CodexTransport
	let reqHandler: CodexServerRequestHandler?
	private let encoder = JSONEncoder()
	private let decoder = JSONDecoder()
	private var nextNumericRequestID: Int64 = 0
	private var pendingRequests: [JSONRPCID: PendingRequest] = [:]
	private var receiveLoopTask: Task<Void, Never>?
	private var notificationContinuations: [UUID: AsyncStream<ServerNotificationEnvelope>.Continuation] = [:]

	public init(
		transport tr: any CodexTransport,
		requestHandler rH: (any CodexServerRequestHandler)? = nil
	) {
		self.trans = tr
		self.reqHandler = rH
	}

	public func start() async -> () {
		guard receiveLoopTask == nil else { return }
		receiveLoopTask = Task { [weak self] in
			await self?.runReceiveLoop()
		}
	}

	public func stop() async -> () {
		receiveLoopTask?.cancel()
		receiveLoopTask = nil
		await trans.close()
		failAllPending(with: CodexConnectionError.disconnected)
		finishNotifications()
	}

	public func request<Params: Encodable, Result: Decodable>(
		method: String,
		params: Params,
		as resultType: Result.Type
	) async throws -> Result {
		await start()
		let id = makeRequestID()
		let payload = try encoder.encode(JSONRPCRequestMessage(id: id, method: method, params: params))

		return try await withCheckedThrowingContinuation { continuation in
			pendingRequests[id] = PendingRequest(
				succeed: { [decoder] data in
					do {
						let result = try decoder.decode(Result.self, from: data)
						continuation.resume(returning: result)
					} catch {
						continuation.resume(throwing: error)
					}
				},
				fail: { error in
					continuation.resume(throwing: error)
				}
			)

			Task {
				do {
					try await self.trans.send(payload)
				} catch {
					await self.failPendingRequest(id: id, error: error)
				}
			}
		}
	}

	public func notify<Params: Encodable>(
		method: String,
		params: Params
	) async throws -> () {
		await start()
		let payload = try encoder.encode(JSONRPCNotificationMessage(method: method, params: params))
		try await trans.send(payload)
	}

	public func notify(method: String) async throws {
		await start()
		let payload = try encoder.encode(JSONRPCClientNotificationMessage(method: method))
		try await trans.send(payload)
	}

	public func notifications() -> AsyncStream<ServerNotificationEnvelope> {
		AsyncStream { continuation in
			let id = UUID()
			notificationContinuations[id] = continuation
			continuation.onTermination = { _ in
				Task {
					await self.removeNotificationContinuation(id: id)
				}
			}
		}
	}
}

private extension CodexConnection {
	func makeRequestID() -> JSONRPCID {
		defer { nextNumericRequestID += 1 }
		return .int(nextNumericRequestID)
	}

	func runReceiveLoop() async {
		do {
			while !Task.isCancelled {
				let message = try await trans.receive()
				try await handleInboundMessage(message)
			}
		} catch {
			failAllPending(with: error)
			finishNotifications()
		}
	}

	func handleInboundMessage(_ message: Data) async throws {
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
			completePendingRequest(id: id, with: try rawData(from: result))
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

	func handleInboundMethodObject(_ object: [String: Any]) async throws {
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

	func handleServerRequest(_ request: ServerRequestEnvelope) async throws {
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

	func sendResponse<Result: Encodable>(id: JSONRPCID, result: Result) async throws {
		let payload = try encoder.encode(JSONRPCResponseEnvelope(id: id, result: result))
		try await trans.send(payload)
	}

	func sendErrorResponse(id: JSONRPCID, error: JSONRPCErrorObject) async throws {
		let payload = try encoder.encode(JSONRPCErrorEnvelope(id: id, error: error))
		try await trans.send(payload)
	}

	func rawData(from value: Any) throws -> Data {
		try JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed])
	}

	func completePendingRequest(id: JSONRPCID, with data: Data) {
		guard let pending = pendingRequests.removeValue(forKey: id) else { return }
		pending.succeed(data)
	}

	func failPendingRequest(id: JSONRPCID, error: Error) {
		guard let pending = pendingRequests.removeValue(forKey: id) else { return }
		pending.fail(error)
	}

	func failAllPending(with error: Error) {
		let requests = pendingRequests
		pendingRequests.removeAll()
		for request in requests.values {
			request.fail(error)
		}
	}

	func yield(notification: ServerNotificationEnvelope) {
		for continuation in notificationContinuations.values {
			continuation.yield(notification)
		}
	}

	func finishNotifications() {
		for continuation in notificationContinuations.values {
			continuation.finish()
		}
		notificationContinuations.removeAll()
	}

	func removeNotificationContinuation(id: UUID) {
		notificationContinuations.removeValue(forKey: id)
	}
}
