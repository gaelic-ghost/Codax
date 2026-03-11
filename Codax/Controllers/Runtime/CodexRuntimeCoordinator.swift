//
//  CodexRuntimeCoordinator.swift
//  Codax
//
//  Created by Gale Williams on 3/11/26.
//

import Foundation

// MARK: Runtime Coordinator

public actor CodexRuntimeCoordinator {
	typealias TransportFactory = @Sendable ([String]) async throws -> any CodexTransport

	private final class DefaultServerRequestResponder: CodexServerRequestResponder {
		private let handleRequest: @Sendable (ServerRequestEnvelope) async -> ServerRequestResponse

		init(handleRequest: @escaping @Sendable (ServerRequestEnvelope) async -> ServerRequestResponse) {
			self.handleRequest = handleRequest
		}

		func handle(_ request: ServerRequestEnvelope) async -> ServerRequestResponse {
			await handleRequest(request)
		}
	}

	private let transportFactory: TransportFactory

	private var activeConnection: CodexConnection?
	private var notificationTask: Task<Void, Never>?
	private var notificationContinuations: [UUID: AsyncStream<ServerNotificationEnvelope>.Continuation] = [:]
	private var serverRequestContinuations: [UUID: AsyncStream<ServerRequestEnvelope>.Continuation] = [:]

	public init() {
		self.transportFactory = { arguments in
			try await LocalCodexTransport.launch(arguments: arguments)
		}
	}

	internal init(
		transportFactory: @escaping TransportFactory
	) {
		self.transportFactory = transportFactory
	}

	public func start(arguments: [String] = []) async throws {
		guard activeConnection == nil else { return }

		let responder = DefaultServerRequestResponder { [weak self] request in
			guard let self else { return .unhandled }
			await self.yield(serverRequest: request)
			return .unhandled
		}
		let transport = try await transportFactory(arguments)
		let connection = CodexConnection(transport: transport, requestResponder: responder)
		self.activeConnection = connection

		await connection.start()
		startNotificationForwarding(for: connection)
	}

	public func stop() async {
		await shutdownRuntime()
	}

	public func initialize(_ params: InitializeParams) async throws -> InitializeResponse {
		guard let activeConnection else {
			throw CodexConnectionError.disconnected
		}
		return try await activeConnection.initialize(params)
	}

	public func sendInitialized() async throws {
		guard let activeConnection else {
			throw CodexConnectionError.disconnected
		}
		try await activeConnection.initialized()
	}

	public func connection() -> CodexConnection? {
		activeConnection
	}

	public func notifications() -> AsyncStream<ServerNotificationEnvelope> {
		AsyncStream { continuation in
			let id = UUID()
			let shouldFinishImmediately = addNotificationContinuation(continuation, id: id)
			if shouldFinishImmediately {
				continuation.finish()
			}

			continuation.onTermination = { _ in
				Task {
					await self.removeNotificationContinuation(id: id)
				}
			}
		}
	}

	public func serverRequests() -> AsyncStream<ServerRequestEnvelope> {
		AsyncStream { continuation in
			let id = UUID()
			let shouldFinishImmediately = addServerRequestContinuation(continuation, id: id)
			if shouldFinishImmediately {
				continuation.finish()
			}

			continuation.onTermination = { _ in
				Task {
					await self.removeServerRequestContinuation(id: id)
				}
			}
		}
	}
}

private extension CodexRuntimeCoordinator {
	func startNotificationForwarding(for connection: CodexConnection) {
		notificationTask?.cancel()
		notificationTask = Task { [weak self] in
			guard let self else { return }
			for await notification in connection.notifications() {
				guard !Task.isCancelled else { break }
				await self.yield(notification: notification)
			}

			guard !Task.isCancelled else { return }
			await self.handleNotificationForwardingEnded()
		}
	}

	func handleNotificationForwardingEnded() async {
		await shutdownRuntime()
	}

	func shutdownRuntime() async {
		let task = notificationTask
		notificationTask = nil
		task?.cancel()

		let connection = self.activeConnection
		self.activeConnection = nil

		let notificationContinuations = Array(notificationContinuations.values)
		self.notificationContinuations.removeAll()
		let serverRequestContinuations = Array(serverRequestContinuations.values)
		self.serverRequestContinuations.removeAll()

		if let connection {
			await connection.stop()
		}

		finish(notificationContinuations: notificationContinuations)
		finish(serverRequestContinuations: serverRequestContinuations)
	}

	func addNotificationContinuation(
		_ continuation: AsyncStream<ServerNotificationEnvelope>.Continuation,
		id: UUID
	) -> Bool {
		guard activeConnection != nil || notificationTask != nil else { return true }
		notificationContinuations[id] = continuation
		return false
	}

	func addServerRequestContinuation(
		_ continuation: AsyncStream<ServerRequestEnvelope>.Continuation,
		id: UUID
	) -> Bool {
		guard activeConnection != nil || notificationTask != nil else { return true }
		serverRequestContinuations[id] = continuation
		return false
	}

	func removeNotificationContinuation(id: UUID) {
		notificationContinuations.removeValue(forKey: id)
	}

	func removeServerRequestContinuation(id: UUID) {
		serverRequestContinuations.removeValue(forKey: id)
	}

	func yield(notification: ServerNotificationEnvelope) {
		for continuation in notificationContinuations.values {
			continuation.yield(notification)
		}
	}

	func yield(serverRequest: ServerRequestEnvelope) {
		for continuation in serverRequestContinuations.values {
			continuation.yield(serverRequest)
		}
	}

	func finish(notificationContinuations: [AsyncStream<ServerNotificationEnvelope>.Continuation]) {
		for continuation in notificationContinuations {
			continuation.finish()
		}
	}

	func finish(serverRequestContinuations: [AsyncStream<ServerRequestEnvelope>.Continuation]) {
		for continuation in serverRequestContinuations {
			continuation.finish()
		}
	}
}
