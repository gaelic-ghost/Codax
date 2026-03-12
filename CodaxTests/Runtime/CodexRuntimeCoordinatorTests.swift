import Foundation
import Testing
@testable import Codax

struct CodexRuntimeCoordinatorTests {
	@Test func startReturnsStartupDebugSnapshot() async throws {
		let transport = RuntimeCoordinatorTestTransport()
		let snapshot = CodexCLIProbe.DebugSnapshot(
			inheritedPath: "/usr/bin",
			detectedCodexPath: "/usr/local/bin/codex",
			compatibility: .supported(
				version: CodexCLIVersion(major: 0, minor: 112, patch: 0),
				path: "/usr/local/bin/codex"
			),
			attempts: []
		)
		let coordinator = makeRuntimeCoordinator(transport: transport, debugSnapshot: snapshot)

		let startedSnapshot = try await coordinator.start()

		#expect(startedSnapshot == snapshot)
		await coordinator.stop()
	}

	@Test func notificationsStreamForwardsToMultipleSubscribers() async throws {
		let transport = RuntimeCoordinatorTestTransport()
		let coordinator = makeRuntimeCoordinator(transport: transport)
		_ = try await coordinator.start()

		var firstIterator = await coordinator.notifications().makeAsyncIterator()
		var secondIterator = await coordinator.notifications().makeAsyncIterator()

		try await transport.enqueueReceive(data: encodedJSONObject([
			"method": "thread/status/changed",
			"params": [
				"threadId": "thread-1",
				"status": [
					"type": "active",
					"activeFlags": ["waitingOnApproval"],
				],
			],
		]))

		let first = await firstIterator.next()
		let second = await secondIterator.next()

		guard case let .threadStatusChanged(firstNotification)? = first else {
			#expect(Bool(false))
			return
		}
		guard case let .threadStatusChanged(secondNotification)? = second else {
			#expect(Bool(false))
			return
		}

		#expect(firstNotification.threadId == "thread-1")
		#expect(secondNotification.threadId == "thread-1")

		await coordinator.stop()
	}

	@Test func serverRequestsStreamForwardsToMultipleSubscribers() async throws {
		let transport = RuntimeCoordinatorTestTransport()
		let coordinator = makeRuntimeCoordinator(transport: transport)
		_ = try await coordinator.start()

		var firstIterator = await coordinator.serverRequests().makeAsyncIterator()
		var secondIterator = await coordinator.serverRequests().makeAsyncIterator()

		try await transport.enqueueReceive(data: encodedJSONObject([
			"id": 17,
			"method": "execCommandApproval",
			"params": [
				"conversationId": "conversation-1",
				"callId": "call-1",
				"command": ["echo", "hi"],
				"cwd": "/tmp",
				"parsedCmd": [],
			],
		]))

		let first = await firstIterator.next()
		let second = await secondIterator.next()

		guard case let .execCommandApproval(firstParams, id: firstID)? = first else {
			#expect(Bool(false))
			return
		}
		guard case let .execCommandApproval(secondParams, id: secondID)? = second else {
			#expect(Bool(false))
			return
		}

		#expect(firstID == .int(17))
		#expect(secondID == .int(17))
		#expect(firstParams.callId == "call-1")
		#expect(secondParams.callId == "call-1")

		await coordinator.stop()
	}

	@Test func typedRequestsForwardThroughRuntimeBoundary() async throws {
		let transport = RuntimeCoordinatorTestTransport()
		let coordinator = makeRuntimeCoordinator(transport: transport)
		_ = try await coordinator.start()

		try await transport.enqueueReceive(data: encodedJSONObject([
			"id": 0,
			"result": ["userAgent": "runtime-test"],
		]))
		let initializeResponse = try await coordinator.initialize(
			InitializeParams(
				clientInfo: ClientInfo(name: "codax", title: "Codax", version: "0.0.0"),
				capabilities: InitializeCapabilities(experimentalApi: false, optOutNotificationMethods: nil)
			)
		)
		#expect(initializeResponse.userAgent == "runtime-test")

		try await transport.enqueueReceive(data: encodedJSONObject([
			"id": 1,
			"result": [
				"thread": makeThreadPayload(id: "thread-1"),
				"model": "gpt-5",
				"modelProvider": "openai",
				"serviceTier": NSNull(),
				"cwd": "/tmp",
				"approvalPolicy": "on-request",
				"sandbox": ["type": "dangerFullAccess"],
				"reasoningEffort": NSNull(),
			],
		]))
		let threadResponse = try await coordinator.threadStart(
			ThreadStartParams(
				model: nil,
				modelProvider: nil,
				serviceTier: nil,
				cwd: nil,
				approvalPolicy: nil,
				sandbox: nil,
				config: nil,
				serviceName: nil,
				baseInstructions: nil,
				developerInstructions: nil,
				personality: nil,
				ephemeral: nil,
				experimentalRawEvents: false,
				persistExtendedHistory: false
			)
		)
		#expect(threadResponse.thread.id == "thread-1")

		try await transport.enqueueReceive(data: encodedJSONObject([
			"id": 2,
			"result": ["thread": makeThreadPayload(id: "thread-1")],
		]))
		let readResponse = try await coordinator.threadRead(
			ThreadReadParams(threadId: "thread-1", includeTurns: true)
		)
		#expect(readResponse.thread.id == "thread-1")

		await coordinator.stop()
	}

	@Test func unhandledServerRequestsStillReturnMethodNotFound() async throws {
		let transport = RuntimeCoordinatorTestTransport()
		let coordinator = makeRuntimeCoordinator(transport: transport)
		_ = try await coordinator.start()

		var iterator = await coordinator.serverRequests().makeAsyncIterator()

		try await transport.enqueueReceive(data: encodedJSONObject([
			"id": 7,
			"method": "execCommandApproval",
			"params": [
				"conversationId": "conversation-1",
				"callId": "call-1",
				"command": ["echo"],
				"cwd": "/tmp",
				"parsedCmd": [],
			],
		]))

		guard case .execCommandApproval? = await iterator.next() else {
			#expect(Bool(false))
			return
		}

		let response = try await waitForSentMessage(at: 0, transport: transport)
		let object = try jsonObject(from: response)
		let error = object["error"] as? [String: Any]

		#expect((object["id"] as? Int) == 7)
		#expect((error?["code"] as? Int) == -32601)

		await coordinator.stop()
	}

	@Test func stopFinishesNotificationAndServerRequestStreams() async throws {
		let transport = RuntimeCoordinatorTestTransport()
		let coordinator = makeRuntimeCoordinator(transport: transport)
		_ = try await coordinator.start()

		var notificationIterator = await coordinator.notifications().makeAsyncIterator()
		var requestIterator = await coordinator.serverRequests().makeAsyncIterator()

		await coordinator.stop()

		let notification = await notificationIterator.next()
		let request = await requestIterator.next()

		#expect(notification == nil)
		#expect(request == nil)
	}
}

private func makeRuntimeCoordinator(
	transport: RuntimeCoordinatorTestTransport,
	debugSnapshot: CodexCLIProbe.DebugSnapshot? = nil
) -> CodexRuntimeCoordinator {
	CodexRuntimeCoordinator(
		transportFactory: { _ in
			CodexRuntimeCoordinator.StartupContext(
				transport: transport,
				debugSnapshot: debugSnapshot
			)
		}
	)
}

private actor RuntimeCoordinatorTestTransport: CodexTransport {
	private var sent: [Data] = []
	private var receiveQueue: [Result<Data, Error>] = []
	private var receiveContinuations: [CheckedContinuation<Data, Error>] = []

	func send(_ message: Data) async throws {
		sent.append(message)
	}

	func receive() async throws -> Data {
		if !receiveQueue.isEmpty {
			return try receiveQueue.removeFirst().get()
		}

		return try await withCheckedThrowingContinuation { continuation in
			receiveContinuations.append(continuation)
		}
	}

	func close() async {
		let continuations = receiveContinuations
		receiveContinuations.removeAll()
		for continuation in continuations {
			continuation.resume(throwing: CodexConnectionError.disconnected)
		}
	}

	func enqueueReceive(data: Data) {
		if !receiveContinuations.isEmpty {
			receiveContinuations.removeFirst().resume(returning: data)
		} else {
			receiveQueue.append(.success(data))
		}
	}

	func sentMessages() -> [Data] {
		sent
	}
}

private func waitForSentMessage(at index: Int, transport: RuntimeCoordinatorTestTransport) async throws -> Data {
	for _ in 0..<100 {
		let messages = await transport.sentMessages()
		if messages.indices.contains(index) {
			return messages[index]
		}
		try await Task.sleep(nanoseconds: 10_000_000)
	}

	throw TestFailure(message: "Timed out waiting for sent message \(index).")
}

private func encodedJSONObject(_ object: [String: Any]) throws -> Data {
	try JSONSerialization.data(withJSONObject: object, options: [.fragmentsAllowed])
}

private func jsonObject(from data: Data) throws -> [String: Any] {
	guard let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) as? [String: Any] else {
		throw TestFailure(message: "Expected JSON object payload.")
	}
	return object
}

private func makeThreadPayload(id: String) -> [String: Any] {
	[
		"id": id,
		"preview": "New thread",
		"ephemeral": false,
		"modelProvider": "openai",
		"createdAt": 1,
		"updatedAt": 1,
		"status": ["type": "idle"],
		"path": "/tmp/\(id)",
		"cwd": "/tmp",
		"cliVersion": "0.114.0",
		"source": "appServer",
		"agentNickname": NSNull(),
		"agentRole": NSNull(),
		"gitInfo": NSNull(),
		"name": "Thread \(id)",
		"turns": [],
	]
}
