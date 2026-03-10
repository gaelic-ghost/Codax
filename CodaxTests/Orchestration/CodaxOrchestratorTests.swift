import Foundation
import Testing
@testable import Codax

@MainActor
struct CodaxOrchestratorTests {
	@Test func refreshCompatibilityUpdatesOrchestratorState() async throws {
		let orchestrator = CodaxOrchestrator(
			compatibilityProbe: makeProbe(
				versionOutput: .init(status: 0, stdout: "codex-cli 0.111.9\n", stderr: ""),
				resolvedPath: "/usr/local/bin/codex"
			),
			runtimeFactory: {
				throw TestFailure(message: "Runtime factory should not be called.")
			}
		)

		await orchestrator.refreshCompatibility()

		#expect(
			orchestrator.compatibility ==
			.supported(
				version: CodexCLIVersion(major: 0, minor: 111, patch: 9),
				path: "/usr/local/bin/codex"
			)
		)
	}

	@Test func connectDoesNotStartRuntimeWhenCompatibilityIsUnsupported() async throws {
		let factory = RuntimeFactoryRecorder()
		let orchestrator = CodaxOrchestrator(
			compatibilityProbe: makeProbe(
				versionOutput: .init(status: 0, stdout: "codex-cli 0.113.0\n", stderr: ""),
				resolvedPath: "/usr/local/bin/codex"
			),
			runtimeFactory: {
				await factory.markStarted()
				throw TestFailure(message: "Unsupported compatibility should not start runtime.")
			}
		)

		await orchestrator.connect()

		#expect(await factory.callCount() == 0)
		#expect(orchestrator.connectionState == .disconnected)
		guard case let .unsupported(version, _, _, _) = orchestrator.compatibility else {
			#expect(Bool(false))
			return
		}
		#expect(version == CodexCLIVersion(major: 0, minor: 113, patch: 0))
	}

	@Test func connectPerformsHandshakeAndStartsRuntimeOnce() async throws {
		let factory = RuntimeFactoryRecorder()
		let transport = OrchestratorTestTransport()
		let orchestrator = makeConnectedOrchestrator(transport: transport, factory: factory)

		await orchestrator.connect()
		await orchestrator.connect()

		#expect(await factory.callCount() == 1)
		#expect(orchestrator.connectionState == .connected)
		#expect(await transport.sentMethods() == ["initialize", "initialized"])
	}

	@Test func startThreadUpdatesActiveThreadAndSummaries() async throws {
		let transport = OrchestratorTestTransport()
		let orchestrator = makeConnectedOrchestrator(transport: transport)

		await orchestrator.connect()
		await orchestrator.startThread()

		#expect(orchestrator.activeThread?.id == "thread-1")
		#expect(orchestrator.threads.count == 1)
		#expect(await transport.sentMethods() == ["initialize", "initialized", "thread/start"])
	}

	@Test func startTurnAppendsTurnToActiveThread() async throws {
		let transport = OrchestratorTestTransport()
		let orchestrator = makeConnectedOrchestrator(transport: transport)

		await orchestrator.connect()
		await orchestrator.startThread()
		await orchestrator.startTurn(inputText: "Hello, Codax")

		#expect(orchestrator.activeThread?.turns.count == 1)
		#expect(orchestrator.activeThread?.turns.first?.id == "turn-1")
		#expect(await transport.sentMethods() == ["initialize", "initialized", "thread/start", "turn/start"])
	}

	@Test func loadThreadsReadsBackActiveThread() async throws {
		let transport = OrchestratorTestTransport()
		let orchestrator = makeConnectedOrchestrator(transport: transport)

		await orchestrator.connect()
		await orchestrator.startThread()

		orchestrator.activeThread = nil
		orchestrator.threads = []

		await orchestrator.loadThreads()

		#expect(orchestrator.activeThread?.id == "thread-1")
		#expect(orchestrator.threads.count == 1)
		#expect(await transport.sentMethods() == ["initialize", "initialized", "thread/start", "thread/read"])
	}

	@Test func notificationHandlingUpdatesOrchestratorState() async throws {
		let transport = OrchestratorTestTransport()
		let orchestrator = makeConnectedOrchestrator(transport: transport)

		await orchestrator.connect()
		await orchestrator.startThread()

		orchestrator.handle(
			.accountUpdated(
				AccountUpdatedNotification(
					authMode: .chatgpt,
					planType: .plus
				)
			)
		)
		orchestrator.handle(
			.threadStatusChanged(
				ThreadStatusChangedNotification(
					threadId: "thread-1",
					status: .active(activeFlags: [.waitingOnApproval])
				)
			)
		)
		orchestrator.handle(
			.turnPlanUpdated(
				TurnPlanUpdatedNotification(
					threadId: "thread-1",
					turnId: "turn-1",
					explanation: "Testing",
					plan: [TurnPlanStep(step: "Ship first slice", status: .inProgress)]
				)
			)
		)
		orchestrator.handle(
			.turnDiffUpdated(
				TurnDiffUpdatedNotification(
					threadId: "thread-1",
					turnId: "turn-1",
					diff: "M ContentView.swift"
				)
			)
		)

		#expect(orchestrator.authMode == .chatgpt)
		#expect(orchestrator.activeTurnPlan.count == 1)
		#expect(orchestrator.activeTurnDiff == "M ContentView.swift")
		#expect(orchestrator.activeThread?.status == .active(activeFlags: [.waitingOnApproval]))
	}
}

private actor RuntimeFactoryRecorder {
	private var starts = 0

	func markStarted() {
		starts += 1
	}

	func callCount() -> Int {
		starts
	}
}

private actor OrchestratorTestTransport: CodexTransport {
	private var sent: [Data] = []
	private var receiveQueue: [Result<Data, Error>] = []
	private var receiveContinuations: [CheckedContinuation<Data, Error>] = []
	private var currentThread: [String: Any]?
	private var nextThreadNumber = 1
	private var nextTurnNumber = 1

	func send(_ message: Data) async throws {
		sent.append(message)
		let object = try jsonObject(from: message)
		guard let method = object["method"] as? String else { return }

		switch method {
		case "initialize":
			try enqueueReceive(
				data: encodedJSONObject([
					"id": object["id"] ?? NSNull(),
					"result": ["userAgent": "codex-test"],
				])
			)
		case "thread/start":
			let thread = makeThreadPayload(id: "thread-\(nextThreadNumber)")
			nextThreadNumber += 1
			currentThread = thread
			try enqueueReceive(
				data: encodedJSONObject([
					"id": object["id"] ?? NSNull(),
					"result": [
						"thread": thread,
						"model": "gpt-5",
						"modelProvider": "openai",
						"cwd": "/tmp",
						"approvalPolicy": NSNull(),
						"sandbox": NSNull(),
					],
				])
			)
		case "thread/read":
			let thread = currentThread ?? makeThreadPayload(id: "thread-fallback")
			currentThread = thread
			try enqueueReceive(
				data: encodedJSONObject([
					"id": object["id"] ?? NSNull(),
					"result": ["thread": thread],
				])
			)
		case "turn/start":
			let turn = makeTurnPayload(id: "turn-\(nextTurnNumber)")
			nextTurnNumber += 1
			if var thread = currentThread {
				var turns = (thread["turns"] as? [[String: Any]]) ?? []
				turns.append(turn)
				thread["turns"] = turns
				currentThread = thread
			}
			try enqueueReceive(
				data: encodedJSONObject([
					"id": object["id"] ?? NSNull(),
					"result": ["turn": turn],
				])
			)
		default:
			return
		}
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
			continuation.resume(throwing: CodexTransportError.closed)
		}
	}

	func sentMethods() async -> [String] {
		sent.compactMap { data in
			guard let object = try? jsonObject(from: data) else { return nil }
			return object["method"] as? String
		}
	}

	private func enqueueReceive(data: Data) throws {
		enqueue(.success(data))
	}

	private func enqueue(_ result: Result<Data, Error>) {
		if !receiveContinuations.isEmpty {
			receiveContinuations.removeFirst().resume(with: result)
		} else {
			receiveQueue.append(result)
		}
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
			"cliVersion": "0.112.0",
			"source": NSNull(),
			"agentNickname": NSNull(),
			"agentRole": NSNull(),
			"gitInfo": NSNull(),
			"name": "Thread \(id)",
			"turns": [],
		]
	}

	private func makeTurnPayload(id: String) -> [String: Any] {
		[
			"id": id,
			"items": [],
			"status": "completed",
			"error": NSNull(),
		]
	}
}

@MainActor
private func makeConnectedOrchestrator(
	transport: OrchestratorTestTransport,
	factory: RuntimeFactoryRecorder? = nil
) -> CodaxOrchestrator {
	CodaxOrchestrator(
		compatibilityProbe: makeProbe(
			versionOutput: .init(status: 0, stdout: "codex-cli 0.112.0\n", stderr: ""),
			resolvedPath: "/usr/local/bin/codex"
		),
		runtimeFactory: {
			await factory?.markStarted()
			let connection = CodexConnection(transport: transport, requestHandler: TestRequestHandler { _ in .unhandled })
			let client = CodexClient(connection: connection)
			return CodaxOrchestrationRuntime(process: nil, connection: connection, client: client)
		}
	)
}

private struct TestRequestHandler: CodexServerRequestHandler {
	let handler: @Sendable (ServerRequestEnvelope) async -> ServerRequestResult

	func handle(_ request: ServerRequestEnvelope) async -> ServerRequestResult {
		await handler(request)
	}
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
