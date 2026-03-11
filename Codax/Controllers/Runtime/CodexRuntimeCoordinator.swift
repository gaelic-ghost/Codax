//
//  CodexRuntimeCoordinator.swift
//  Codax
//
//  Created by Gale Williams on 3/11/26.
//

import Foundation

// MARK: Runtime Coordinator

public actor CodexRuntimeCoordinator {
	public struct StartupContext: Sendable {
		public let transport: any CodexTransport
		public let debugSnapshot: CodexCLIProbe.DebugSnapshot?

		public init(
			transport: any CodexTransport,
			debugSnapshot: CodexCLIProbe.DebugSnapshot? = nil
		) {
			self.transport = transport
			self.debugSnapshot = debugSnapshot
		}
	}

	typealias TransportFactory = @Sendable ([String]) async throws -> StartupContext

	private struct ClosureServerRequestResponder: CodexServerRequestResponder {
		let handleRequest: @Sendable (ServerRequestEnvelope) async -> ServerRequestResponse

		func handle(_ request: ServerRequestEnvelope) async -> ServerRequestResponse {
			await handleRequest(request)
		}
	}

	private let transportFactory: TransportFactory

	private var activeConnection: CodexConnection?
	private var notificationTask: Task<Void, Never>?
	private var notificationContinuations: [UUID: AsyncStream<ServerNotificationEnvelope>.Continuation] = [:]
	private var serverRequestContinuations: [UUID: AsyncStream<ServerRequestEnvelope>.Continuation] = [:]
	private var startupDebugSnapshot: CodexCLIProbe.DebugSnapshot?

	public init() {
		self.transportFactory = { arguments in
			let transport = try await LocalCodexTransport.launch(arguments: arguments)
			let debugSnapshot = await transport.startupProbeDebugSnapshot()
			return StartupContext(transport: transport, debugSnapshot: debugSnapshot)
		}
	}

	internal init(
		transportFactory: @escaping TransportFactory
	) {
		self.transportFactory = transportFactory
	}

	public func start(arguments: [String] = []) async throws -> CodexCLIProbe.DebugSnapshot? {
		guard activeConnection == nil else {
			return startupDebugSnapshot
		}

		let responder = ClosureServerRequestResponder { [weak self] request in
			guard let self else { return .unhandled }
			await self.yield(serverRequest: request)
			return .unhandled
		}
		let startup = try await transportFactory(arguments)
		let connection = CodexConnection(transport: startup.transport, requestResponder: responder)
		activeConnection = connection
		startupDebugSnapshot = startup.debugSnapshot

		await connection.start()
		startNotificationForwarding(for: connection)
		return startupDebugSnapshot
	}

	public func stop() async {
		await shutdownRuntime()
	}

	public func notifications() -> AsyncStream<ServerNotificationEnvelope> {
		AsyncStream { continuation in
			let id = UUID()
			guard activeConnection != nil || notificationTask != nil else {
				continuation.finish()
				return
			}

			notificationContinuations[id] = continuation
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
			guard activeConnection != nil || notificationTask != nil else {
				continuation.finish()
				return
			}

			serverRequestContinuations[id] = continuation
			continuation.onTermination = { _ in
				Task {
					await self.removeServerRequestContinuation(id: id)
				}
			}
		}
	}

	public func startupProbeDebugSnapshot() -> CodexCLIProbe.DebugSnapshot? {
		startupDebugSnapshot
	}
}

extension CodexRuntimeCoordinator {
	func requireConnection() throws -> CodexConnection {
		guard let activeConnection else {
			throw CodexConnectionError.disconnected
		}
		return activeConnection
	}

	func startNotificationForwarding(for connection: CodexConnection) {
		notificationTask?.cancel()
		notificationTask = Task { [weak self] in
			guard let self else { return }
			let stream = await connection.notifications()
			for await notification in stream {
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

		let connection = activeConnection
		activeConnection = nil
		startupDebugSnapshot = nil

		let notificationContinuations = Array(notificationContinuations.values)
		self.notificationContinuations.removeAll()
		let serverRequestContinuations = Array(serverRequestContinuations.values)
		self.serverRequestContinuations.removeAll()

		if let connection {
			await connection.stop()
		}

		finish(continuations: notificationContinuations)
		finish(continuations: serverRequestContinuations)
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

	func removeNotificationContinuation(id: UUID) {
		notificationContinuations.removeValue(forKey: id)
	}

	func removeServerRequestContinuation(id: UUID) {
		serverRequestContinuations.removeValue(forKey: id)
	}

	func finish<Element>(continuations: [AsyncStream<Element>.Continuation]) {
		for continuation in continuations {
			continuation.finish()
		}
	}
}
