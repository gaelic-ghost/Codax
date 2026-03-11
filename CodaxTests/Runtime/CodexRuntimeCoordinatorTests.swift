import Foundation
import Testing
@testable import Codax

struct CodexRuntimeCoordinatorTests {
	@Test func notificationsStreamForwardsToMultipleSubscribers() async throws {
		let transport = RuntimeCoordinatorTestTransport()
		let coordinator = makeRuntimeCoordinator(transport: transport)
		try await coordinator.start()

		var firstIterator = coordinator.notifications().makeAsyncIterator()
		var secondIterator = coordinator.notifications().makeAsyncIterator()

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

		#expect(firstNotification.threadCodexId == "thread-1")
		#expect(secondNotification.threadCodexId == "thread-1")

		await coordinator.stop()
	}

	@Test func serverRequestsStreamForwardsToMultipleSubscribers() async throws {
		let transport = RuntimeCoordinatorTestTransport()
		let coordinator = makeRuntimeCoordinator(transport: transport)
		try await coordinator.start()

		var firstIterator = coordinator.serverRequests().makeAsyncIterator()
		var secondIterator = coordinator.serverRequests().makeAsyncIterator()

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

	@Test func unhandledServerRequestsStillReturnMethodNotFound() async throws {
		let transport = RuntimeCoordinatorTestTransport()
		let coordinator = makeRuntimeCoordinator(transport: transport)
		try await coordinator.start()

		var iterator = coordinator.serverRequests().makeAsyncIterator()

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
		try await coordinator.start()

		var notificationIterator = coordinator.notifications().makeAsyncIterator()
		var requestIterator = coordinator.serverRequests().makeAsyncIterator()

		await coordinator.stop()

		let notification = await notificationIterator.next()
		let request = await requestIterator.next()

		#expect(notification == nil)
		#expect(request == nil)
	}
}

private func makeRuntimeCoordinator(transport: RuntimeCoordinatorTestTransport) -> CodexRuntimeCoordinator {
	CodexRuntimeCoordinator(
		processFactory: {
			CodexProcess(executableURL: URL(fileURLWithPath: "/usr/bin/true"), baseArguments: [])
		},
		transportLauncher: { _, _ in transport }
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
