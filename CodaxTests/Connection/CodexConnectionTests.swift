import Foundation
import Testing
@testable import Codax

struct CodexConnectionTests {
	@Test func jsonRPCErrorObjectDecodesJSONValueData() throws {
		let data = Data(
			"""
			{
			  "code": -32001,
			  "message": "overloaded",
			  "data": {
			    "retryAfterMs": 250,
			    "servers": ["a", "b"]
			  }
			}
			""".utf8
		)

		let error = try JSONDecoder().decode(JSONRPCErrorObject.self, from: data)

		#expect(error.data == .object([
			"retryAfterMs": .number(250),
			"servers": .array([.string("a"), .string("b")]),
		]))
	}

	@Test func requestResolvesMatchingResponse() async throws {
		let transport = TestTransport()
		let connection = CodexConnection(transport: transport)

		let task = Task {
			try await connection._request(method: "test/echo", params: EchoParams(value: "hello"), as: EchoResult.self)
		}

		let sent = try await waitForSentMessage(at: 0, transport: transport)
		let requestObject = try jsonObject(from: sent)
		#expect((requestObject["method"] as? String) == "test/echo")
		#expect(((requestObject["params"] as? [String: Any])?["value"] as? String) == "hello")

		try await transport.enqueueReceive(data: encodedJSONObject([
			"id": try rawID(from: sent),
			"result": ["value": "world"],
		]))

		let result = try await task.value
		#expect(result == EchoResult(value: "world"))
	}

	@Test func concurrentRequestsResolveOutOfOrder() async throws {
		let transport = TestTransport()
		let connection = CodexConnection(transport: transport)

		let firstTask = Task {
			try await connection._request(method: "test/first", params: EmptyParams(), as: EchoResult.self)
		}
		let secondTask = Task {
			try await connection._request(method: "test/second", params: EmptyParams(), as: EchoResult.self)
		}

		let firstSent = try await waitForSentMessage(at: 0, transport: transport)
		let secondSent = try await waitForSentMessage(at: 1, transport: transport)

		try await transport.enqueueReceive(data: encodedJSONObject([
			"id": try rawID(from: secondSent),
			"result": ["value": "second"],
		]))
		try await transport.enqueueReceive(data: encodedJSONObject([
			"id": try rawID(from: firstSent),
			"result": ["value": "first"],
		]))

		#expect(try await firstTask.value == EchoResult(value: "first"))
		#expect(try await secondTask.value == EchoResult(value: "second"))
	}

	@Test func requestFailsOnMatchingServerError() async throws {
		let transport = TestTransport()
		let connection = CodexConnection(transport: transport)

		let task = Task {
			try await connection._request(method: "test/error", params: EmptyParams(), as: EchoResult.self)
		}

		let sent = try await waitForSentMessage(at: 0, transport: transport)
		try await transport.enqueueReceive(data: encodedJSONObject([
			"id": try rawID(from: sent),
			"error": [
				"code": -32099,
				"message": "boom",
			],
		]))

		do {
			_ = try await task.value
			#expect(Bool(false))
		} catch let error as CodexConnectionError {
			guard case let .serverError(object) = error else {
				#expect(Bool(false))
				return
			}
			#expect(object.code == -32099)
			#expect(object.message == "boom")
		}
	}

	@Test func unknownResponseIDIsIgnored() async throws {
		let transport = TestTransport()
		let connection = CodexConnection(transport: transport)

		let task = Task {
			try await connection._request(method: "test/ignore", params: EmptyParams(), as: EchoResult.self)
		}

		let sent = try await waitForSentMessage(at: 0, transport: transport)
		try await transport.enqueueReceive(data: encodedJSONObject([
			"id": 999,
			"result": ["value": "wrong"],
		]))
		try await transport.enqueueReceive(data: encodedJSONObject([
			"id": try rawID(from: sent),
			"result": ["value": "right"],
		]))

		#expect(try await task.value == EchoResult(value: "right"))
	}

	@Test func stopFailsPendingRequestsWithDisconnected() async throws {
		let transport = TestTransport()
		let connection = CodexConnection(transport: transport)

		let task = Task {
			try await connection._request(method: "test/stop", params: EmptyParams(), as: EchoResult.self)
		}

		_ = try await waitForSentMessage(at: 0, transport: transport)
		await connection.stop()

		do {
			_ = try await task.value
			#expect(Bool(false))
		} catch let error as CodexConnectionError {
			guard case .disconnected = error else {
				#expect(Bool(false))
				return
			}
		}
	}

	@Test func notificationsDecodeTypedCases() async throws {
		let transport = TestTransport()
		let connection = CodexConnection(transport: transport)
		var iterator = await connection.notifications().makeAsyncIterator()

		await connection.start()

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

		let first = await iterator.next()
		guard case let .threadStatusChanged(notification)? = first else {
			#expect(Bool(false))
			return
		}
		#expect(notification.threadId == "thread-1")
		guard case let .active(activeFlags) = notification.status else {
			#expect(Bool(false))
			return
		}
		#expect(activeFlags == [.waitingOnApproval])

		try await transport.enqueueReceive(data: encodedJSONObject([
			"method": "item/agentMessage/delta",
			"params": [
				"threadId": "thread-1",
				"turnId": "turn-1",
				"itemId": "item-1",
				"delta": "Hello",
			],
		]))

		let second = await iterator.next()
		guard case let .itemAgentMessageDelta(notification)? = second else {
			#expect(Bool(false))
			return
		}
		#expect(notification.threadId == "thread-1")
		#expect(notification.turnId == "turn-1")
		#expect(notification.itemId == "item-1")
		#expect(notification.delta == "Hello")
	}

	@Test func inboundServerRequestRoutesToHandlerAndWritesResponse() async throws {
		let transport = TestTransport()
		let responder = TestRequestResponder { request in
			guard case .execCommandApproval = request else {
				return .unhandled
			}
			return .execCommandApproval(ExecCommandApprovalResponse(decision: .approved))
		}
		let connection = CodexConnection(transport: transport, requestResponder: responder)

		await connection.start()
		try await transport.enqueueReceive(data: encodedJSONObject([
			"id": 42,
			"method": "execCommandApproval",
			"params": [
				"conversationId": "conversation-1",
				"callId": "call-1",
				"command": ["echo", "hi"],
				"cwd": "/tmp",
				"parsedCmd": [],
			],
		]))

		let response = try await waitForSentMessage(at: 0, transport: transport)
		let object = try jsonObject(from: response)
		#expect((object["id"] as? Int) == 42)
		let result = object["result"] as? [String: Any]
		#expect((result?["decision"] as? String) == "approved")
	}

	@Test func unhandledServerRequestReturnsMethodNotFound() async throws {
		let transport = TestTransport()
		let responder = TestRequestResponder { _ in .unhandled }
		let connection = CodexConnection(transport: transport, requestResponder: responder)

		await connection.start()
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

		let response = try await waitForSentMessage(at: 0, transport: transport)
		let object = try jsonObject(from: response)
		let error = object["error"] as? [String: Any]
		#expect((object["id"] as? Int) == 7)
		#expect((error?["code"] as? Int) == -32601)
	}

	@Test func overloadErrorRetriesAndEventuallySucceeds() async throws {
		let transport = TestTransport()
		let sleeper = TestSleeper()
		let connection = CodexConnection(
			transport: transport,
			maxRetryCount: 3,
			retryBaseDelayNanos: 1,
			retryMaxDelayNanos: 4,
			retryJitterRatio: 0,
			sleep: { nanos in try await sleeper.sleep(nanos) },
			random: { 0.5 }
		)

		let task = Task {
			try await connection._request(method: "test/retry", params: EmptyParams(), as: EchoResult.self)
		}

		let firstSent = try await waitForSentMessage(at: 0, transport: transport)
		try await transport.enqueueReceive(data: encodedJSONObject([
			"id": try rawID(from: firstSent),
			"error": [
				"code": -32001,
				"message": "Server overloaded; retry later.",
			],
		]))

		let secondSent = try await waitForSentMessage(at: 1, transport: transport)
		try await transport.enqueueReceive(data: encodedJSONObject([
			"id": try rawID(from: secondSent),
			"result": ["value": "ok"],
		]))

		#expect(try await task.value == EchoResult(value: "ok"))
		let durations = await sleeper.durations()
		#expect(durations.count == 1)
	}

	@Test func overloadErrorExhaustsRetries() async throws {
		let transport = TestTransport()
		let sleeper = TestSleeper()
		let connection = CodexConnection(
			transport: transport,
			maxRetryCount: 2,
			retryBaseDelayNanos: 1,
			retryMaxDelayNanos: 4,
			retryJitterRatio: 0,
			sleep: { nanos in try await sleeper.sleep(nanos) },
			random: { 0.5 }
		)

		let task = Task {
			try await connection._request(method: "test/retry", params: EmptyParams(), as: EchoResult.self)
		}

		for index in 0..<3 {
			let sent = try await waitForSentMessage(at: index, transport: transport)
			try await transport.enqueueReceive(data: encodedJSONObject([
				"id": try rawID(from: sent),
				"error": [
					"code": -32001,
					"message": "Server overloaded; retry later.",
				],
			]))
		}

		do {
			_ = try await task.value
			#expect(Bool(false))
		} catch let error as CodexConnectionError {
			guard case let .serverError(object) = error else {
				#expect(Bool(false))
				return
			}
			#expect(object.code == -32001)
		}

		let durations = await sleeper.durations()
		#expect(durations.count == 2)
		#expect(durations[0] <= durations[1])
	}

	@Test func disconnectDuringRetryFailsCleanly() async throws {
		let transport = TestTransport()
		let sleeper = TestSleeper(blockOnSleep: true)
		let connection = CodexConnection(
			transport: transport,
			maxRetryCount: 3,
			retryBaseDelayNanos: 1,
			retryMaxDelayNanos: 4,
			retryJitterRatio: 0,
			sleep: { nanos in try await sleeper.sleep(nanos) },
			random: { 0.5 }
		)

		let task = Task {
			try await connection._request(method: "test/retry", params: EmptyParams(), as: EchoResult.self)
		}

		let firstSent = try await waitForSentMessage(at: 0, transport: transport)
		try await transport.enqueueReceive(data: encodedJSONObject([
			"id": try rawID(from: firstSent),
			"error": [
				"code": -32001,
				"message": "Server overloaded; retry later.",
			],
		]))

		try await waitForCondition { await sleeper.callCount() == 1 }
		await connection.stop()
		await sleeper.resumeNext()

		do {
			_ = try await task.value
			#expect(Bool(false))
		} catch let error as CodexConnectionError {
			guard case .disconnected = error else {
				#expect(Bool(false))
				return
			}
		}

		#expect(await transport.sentMessages().count == 1)
	}

	@Test func invalidInboundMessageFailsPendingRequests() async throws {
		let transport = TestTransport()
		let connection = CodexConnection(transport: transport)

		let task = Task {
			try await connection._request(method: "test/invalid", params: EmptyParams(), as: EchoResult.self)
		}

		_ = try await waitForSentMessage(at: 0, transport: transport)
		try await transport.enqueueReceive(data: encodedJSONObject([
			"unexpected": true,
		]))

		do {
			_ = try await task.value
			#expect(Bool(false))
		} catch let error as CodexConnectionError {
			guard case .invalidMessage = error else {
				#expect(Bool(false))
				return
			}
		}
	}
}

private struct EchoParams: Sendable, Codable {
	let value: String
}

private struct EchoResult: Sendable, Codable, Equatable {
	let value: String
}

private struct EmptyParams: Sendable, Codable {}

private struct TestRequestResponder: CodexServerRequestResponder {
	let handler: @Sendable (ServerRequestEnvelope) async -> ServerRequestResponse

	func handle(_ request: ServerRequestEnvelope) async -> ServerRequestResponse {
		await handler(request)
	}
}

private actor TestSleeper {
	private let blockOnSleep: Bool
	private var recordedDurations: [UInt64] = []
	private var continuations: [CheckedContinuation<Void, Error>] = []

	init(blockOnSleep: Bool = false) {
		self.blockOnSleep = blockOnSleep
	}

	func sleep(_ nanos: UInt64) async throws {
		recordedDurations.append(nanos)
		guard blockOnSleep else { return }
		try await withCheckedThrowingContinuation { continuation in
			continuations.append(continuation)
		}
	}

	func durations() -> [UInt64] {
		recordedDurations
	}

	func callCount() -> Int {
		recordedDurations.count
	}

	func resumeNext() {
		guard !continuations.isEmpty else { return }
		continuations.removeFirst().resume()
	}
}

private actor TestTransport: CodexTransport {
	private var sent: [Data] = []
	private var receiveQueue: [Result<Data, Error>] = []
	private var receiveContinuations: [CheckedContinuation<Data, Error>] = []
	private var sendError: Error?

	func send(_ message: Data) async throws {
		if let sendError {
			throw sendError
		}
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
		enqueue(.success(data))
	}

	func enqueueFailure(_ error: Error) {
		enqueue(.failure(error))
	}

	func sentMessages() -> [Data] {
		sent
	}

	private func enqueue(_ result: Result<Data, Error>) {
		if !receiveContinuations.isEmpty {
			receiveContinuations.removeFirst().resume(with: result)
		} else {
			receiveQueue.append(result)
		}
	}
}

private func waitForSentMessage(at index: Int, transport: TestTransport) async throws -> Data {
	try await waitForCondition {
		await transport.sentMessages().count > index
	}
	return await transport.sentMessages()[index]
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

private func rawID(from data: Data) throws -> Any {
	let object = try jsonObject(from: data)
	guard let id = object["id"] else {
		throw TestFailure(message: "Expected id field in JSON-RPC message.")
	}
	return id
}
