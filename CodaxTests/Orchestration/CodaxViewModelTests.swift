import Foundation
import SwiftData
import Testing
@testable import Codax

// MARK: - View Model Tests

@MainActor
struct CodaxViewModelTests {
	@Test func connectSurfacesUnsupportedStartupCompatibility() async throws {
			let factory = RuntimeFactoryRecorder()
			let modelContainer = try makeInMemoryModelContainer()
			let viewModel = CodaxViewModel(
				runtimeFactory: {
					await factory.markStarted()
				return makeFailingRuntimeCoordinator(
					error: LocalCodexTransport.LaunchError.launchFailed(
						command: "/usr/bin/env codex app-server --listen stdio://",
						reason: "Codax currently supports Codex CLI 0.114.x only.",
						stderrSnapshot: nil,
						debugSnapshot: CodexCLIProbe.DebugSnapshot(
							inheritedPath: "/usr/bin",
							detectedCodexPath: "/usr/local/bin/codex",
							compatibility: .unsupported(
								version: CodexCLIVersion(major: 0, minor: 113, patch: 0),
								path: "/usr/local/bin/codex",
								supportedRange: CodexCLIProbe.supportedRangeDescription,
								reason: "Codax currently supports Codex CLI 0.114.x only."
							),
							attempts: []
						)
					)
				)
				},
				initializeParamsFactory: { makeInitializeParams() },
				modelContainer: modelContainer
			)

		await viewModel.connect()

		#expect(await factory.callCount() == 1)
		#expect(viewModel.connectionState == .disconnected)
		guard case let .unsupported(version, _, _, _) = viewModel.compatibility else {
			#expect(Bool(false))
			return
		}
		#expect(version == CodexCLIVersion(major: 0, minor: 113, patch: 0))
	}

		@Test func connectPerformsHandshakeAndStartsRuntimeOnce() async throws {
			let factory = RuntimeFactoryRecorder()
			let transport = ViewModelTestTransport()
			let modelContainer = try makeInMemoryModelContainer()
			let viewModel = makeConnectedViewModel(transport: transport, modelContainer: modelContainer, factory: factory)

		await viewModel.connect()
		await viewModel.connect()

		#expect(await factory.callCount() == 1)
		#expect(viewModel.connectionState == .connected)
		#expect(await transport.sentMethods() == ["initialize", "initialized", "account/read", "thread/list"])
		guard case let .supported(version, path) = viewModel.compatibility else {
			#expect(Bool(false))
			return
		}
		#expect(version == CodexCLIVersion(major: 0, minor: 112, patch: 0))
		#expect(path == "/usr/local/bin/codex")
		#expect(viewModel.loginState == .signedOut)
	}

	@Test func startThreadPersistsSelectedThreadDetail() async throws {
			let transport = ViewModelTestTransport()
			let modelContainer = try makeInMemoryModelContainer()
			let viewModel = makeConnectedViewModel(transport: transport, modelContainer: modelContainer)

			await viewModel.connect()
			await viewModel.startThread()

			let persistedThread = try fetchThread(codexId: "thread-1", from: modelContainer)
			#expect(viewModel.selectedThreadCodexId == "thread-1")
			#expect(persistedThread?.codexId == "thread-1")
			#expect(persistedThread?.hydrationState == .detail)
		#expect(await transport.sentMethods() == ["initialize", "initialized", "account/read", "thread/list", "thread/start", "gitDiffToRemote"])
	}

	@Test func startThreadProjectsSessionConfigurationAndGitSummary() async throws {
		let transport = ViewModelTestTransport()
		let modelContainer = try makeInMemoryModelContainer()
		let viewModel = makeConnectedViewModel(transport: transport, modelContainer: modelContainer)

		await viewModel.connect()
		await viewModel.startThread()

		let fetchedThread = try fetchThread(codexId: "thread-1", from: modelContainer)
		let persistedThread = try #require(fetchedThread)
		#expect(persistedThread.session?.approvalPolicy == .onRequest)
		#expect(persistedThread.session?.reasoningEffort == .medium)
		#expect(persistedThread.gitDiff?.response?.sha == "abc123")
		#expect(persistedThread.gitDiff?.response?.diff == """
			diff --git a/README.md b/README.md
			--- a/README.md
			+++ b/README.md
			+First
			+Second
			-Third
			""")
		#expect(await transport.sentMethods() == ["initialize", "initialized", "account/read", "thread/list", "thread/start", "gitDiffToRemote"])
	}

	@Test func startTurnPersistsTurnOnSelectedThread() async throws {
			let transport = ViewModelTestTransport()
			let modelContainer = try makeInMemoryModelContainer()
			let viewModel = makeConnectedViewModel(transport: transport, modelContainer: modelContainer)

			await viewModel.connect()
			await viewModel.startThread()
			await viewModel.startTurn(inputText: "Hello, Codax")

			let persistedThread = try fetchThread(codexId: "thread-1", from: modelContainer)
			#expect(persistedThread?.turns.count == 1)
			#expect(persistedThread?.turns.first?.codexId == "turn-1")
		#expect(await transport.sentMethods() == ["initialize", "initialized", "account/read", "thread/list", "thread/start", "gitDiffToRemote", "turn/start"])
		}

	@Test func loadThreadsPersistsSummariesAndHydratesSelection() async throws {
			let transport = ViewModelTestTransport()
			let modelContainer = try makeInMemoryModelContainer()
			let viewModel = makeConnectedViewModel(transport: transport, modelContainer: modelContainer)

			await viewModel.connect()
			await viewModel.startThread()

			viewModel.selectedThreadCodexId = nil

			await viewModel.loadThreads()

			let persistedThread = try fetchThread(codexId: "thread-1", from: modelContainer)
			#expect(viewModel.selectedThreadCodexId == "thread-1")
			#expect(persistedThread?.hydrationState == .detail)
		#expect(await transport.sentMethods() == ["initialize", "initialized", "account/read", "thread/list", "thread/start", "gitDiffToRemote", "thread/list", "thread/read", "gitDiffToRemote"])
		}

		@Test func loginWithChatGPTStartsRealLoginFlow() async throws {
			let transport = ViewModelTestTransport()
			let modelContainer = try makeInMemoryModelContainer()
			let viewModel = makeConnectedViewModel(transport: transport, modelContainer: modelContainer)

		await viewModel.connect()
		await viewModel.loginWithChatGPT()

		#expect(viewModel.loginState == .authorizing)
		#expect(viewModel.pendingLogin == CodaxPendingLogin(loginId: "login-1", authURL: "https://example.com/auth"))
		#expect(await transport.sentMethods() == ["initialize", "initialized", "account/read", "thread/list", "account/login/start"])
	}

		@Test func notificationHandlingUpdatesViewModelState() async throws {
			let transport = ViewModelTestTransport()
			let modelContainer = try makeInMemoryModelContainer()
			let viewModel = makeConnectedViewModel(transport: transport, modelContainer: modelContainer)

		await viewModel.connect()
		await viewModel.startThread()
		await viewModel.startTurn(inputText: "Plan test")

		viewModel.handle(
			.accountUpdated(
				AccountUpdatedNotification(
					authMode: .chatgpt,
					planType: .plus
				)
			)
		)
		viewModel.handle(
			.threadStatusChanged(
				ThreadStatusChangedNotification(
					threadId: "thread-1",
					status: .active(activeFlags: [.waitingOnApproval])
				)
			)
		)
		viewModel.handle(
			.turnPlanUpdated(
				TurnPlanUpdatedNotification(
					threadId: "thread-1",
					turnId: "turn-1",
					explanation: "Testing",
					plan: [TurnPlanStep(step: "Ship first slice", status: .inProgress)]
				)
			)
		)
		viewModel.handle(
			.turnDiffUpdated(
				TurnDiffUpdatedNotification(
					threadId: "thread-1",
					turnId: "turn-1",
					diff: "M ContentView.swift"
				)
			)
		)

		#expect(viewModel.authMode == .chatgpt)
		let fetchedThread = try fetchThread(codexId: "thread-1", from: modelContainer)
		let persistedThread = try #require(fetchedThread)
		#expect(persistedThread.status == .active(activeFlags: [.waitingOnApproval]))
		#expect(persistedThread.turns.first?.plan?.steps.count == 1)
		#expect(persistedThread.turns.first?.diff?.diff == "M ContentView.swift")
		}

		@Test func serverRequestsBecomePendingUiStateAndResolveByNotification() async throws {
			let transport = ViewModelTestTransport()
			let modelContainer = try makeInMemoryModelContainer()
			let viewModel = makeConnectedViewModel(transport: transport, modelContainer: modelContainer)

		await viewModel.connect()

		viewModel.handle(
			.execCommandApproval(
				ExecCommandApprovalParams(
					conversationId: "thread-1",
					callId: "call-1",
					approvalId: nil,
					command: ["echo", "hi"],
					cwd: "/tmp",
					reason: "Need approval",
					parsedCmd: []
				),
				id: .int(17)
			)
		)

		let fetchedRequest = try fetchPendingServerRequest(id: .int(17), from: modelContainer)
		let pendingRequest = try #require(fetchedRequest)
		#expect(pendingRequest.payload?.summary == "Need approval")
		#expect(pendingRequest.requestId == .int(17))

		viewModel.handle(
			.serverRequestResolved(
				ServerRequestResolvedNotification(threadId: "thread-1", requestId: .int(17))
			)
		)

		let resolvedRequest = try fetchPendingServerRequest(id: .int(17), from: modelContainer)
		#expect(resolvedRequest == nil)
	}

	@Test func permissionsApprovalRequestsBecomePendingUiState() async throws {
		let transport = ViewModelTestTransport()
		let modelContainer = try makeInMemoryModelContainer()
		let viewModel = makeConnectedViewModel(transport: transport, modelContainer: modelContainer)

		await viewModel.connect()

		viewModel.handle(
			.itemPermissionsRequestApproval(
				PermissionsRequestApprovalParams(
					threadId: "thread-1",
					turnId: "turn-1",
					itemId: "item-1",
					reason: "Need temporary automation access",
					permissions: AdditionalPermissionProfile(
						network: nil,
						fileSystem: nil,
						macos: AdditionalMacOsPermissions(
							preferences: .readOnly,
							automations: .all,
							accessibility: false,
							calendar: false
						)
					)
				),
				id: .string("request-1")
			)
		)

		let fetchedRequest = try fetchPendingServerRequest(id: .string("request-1"), from: modelContainer)
		let pendingRequest = try #require(fetchedRequest)
		#expect(pendingRequest.payload?.summary == "Need temporary automation access")
		#expect(pendingRequest.requestId == .string("request-1"))
	}
}

// MARK: - Test Recorders

private actor RuntimeFactoryRecorder {
	private var starts = 0

	func markStarted() {
		starts += 1
	}

	func callCount() -> Int {
		starts
	}
}

// MARK: - Test Transport

private actor ViewModelTestTransport: CodexTransport {
	private var sent: [Data] = []
	private var receiveQueue: [Result<Data, Error>] = []
	private var receiveContinuations: [CheckedContinuation<Data, Error>] = []
	private var currentThread: [String: Any]?
	private var currentAccount: [String: Any]?
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
				case "account/read":
					var result: [String: Any] = [
						"requiresOpenaiAuth": true,
					]
					result["account"] = currentAccount ?? NSNull()
					try enqueueReceive(
						data: encodedJSONObject([
							"id": object["id"] ?? NSNull(),
							"result": result,
						])
					)
			case "account/login/start":
				try enqueueReceive(
					data: encodedJSONObject([
						"id": object["id"] ?? NSNull(),
						"result": [
							"type": "chatgpt",
							"loginId": "login-1",
							"authUrl": "https://example.com/auth",
						],
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
							"serviceTier": NSNull(),
							"cwd": "/tmp",
							"approvalPolicy": "on-request",
							"sandbox": ["type": "dangerFullAccess"],
							"reasoningEffort": "medium",
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
			case "thread/list":
				let data = currentThread.map { [$0] } ?? []
				try enqueueReceive(
					data: encodedJSONObject([
						"id": object["id"] ?? NSNull(),
						"result": [
							"data": data,
							"nextCursor": NSNull(),
						],
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
				case "gitDiffToRemote":
					try enqueueReceive(
						data: encodedJSONObject([
							"id": object["id"] ?? NSNull(),
							"result": [
								"sha": "abc123",
								"diff": """
								diff --git a/README.md b/README.md
								--- a/README.md
								+++ b/README.md
								+First
								+Second
								-Third
								""",
							],
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
			"cliVersion": "0.114.0",
			"source": "appServer",
			"agentNickname": NSNull(),
			"agentRole": NSNull(),
			"gitInfo": [
				"sha": "abc123",
				"branch": "main",
				"originUrl": "https://example.com/repo.git",
			],
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

// MARK: - View Model Factory Helpers

@MainActor
private func makeConnectedViewModel(
	transport: ViewModelTestTransport,
	modelContainer: ModelContainer,
	factory: RuntimeFactoryRecorder? = nil
) -> CodaxViewModel {
	CodaxViewModel(
		runtimeFactory: {
			await factory?.markStarted()
			return makeRuntimeCoordinator(transport: transport)
		},
		initializeParamsFactory: { makeInitializeParams() },
		modelContainer: modelContainer
	)
}

private func makeRuntimeCoordinator(transport: ViewModelTestTransport) -> CodexRuntimeCoordinator {
	CodexRuntimeCoordinator(
		transportFactory: { _ in
			CodexRuntimeCoordinator.StartupContext(
				transport: transport,
				debugSnapshot: CodexCLIProbe.DebugSnapshot(
					inheritedPath: "/usr/bin",
					detectedCodexPath: "/usr/local/bin/codex",
					compatibility: .supported(
						version: CodexCLIVersion(major: 0, minor: 112, patch: 0),
						path: "/usr/local/bin/codex"
					),
					attempts: []
				)
			)
		}
	)
}

private func makeFailingRuntimeCoordinator(error: Error) -> CodexRuntimeCoordinator {
	CodexRuntimeCoordinator(
		transportFactory: { _ in
			throw error
		}
	)
}

// MARK: - Persistence Helpers

@MainActor
private func makeInMemoryModelContainer() throws -> ModelContainer {
	try makeCodaxModelContainer(inMemory: true)
}

@MainActor
private func fetchThread(codexId: String, from modelContainer: ModelContainer) throws -> ThreadModel? {
	try modelContainer.mainContext.fetch(
		FetchDescriptor<ThreadModel>(
			predicate: #Predicate<ThreadModel> { $0.codexId == codexId }
		)
	).first
}

@MainActor
private func fetchPendingServerRequest(id: JSONRPCID, from modelContainer: ModelContainer) throws -> PendingServerRequestModel? {
	try modelContainer.mainContext.fetch(FetchDescriptor<PendingServerRequestModel>()).first { $0.requestId == id }
}

// MARK: - Payload Helpers

private func makeInitializeParams() -> InitializeParams {
	InitializeParams(
		clientInfo: ClientInfo(
			name: "codax",
			title: "Codax",
			version: "0.0.0-test"
		),
		capabilities: InitializeCapabilities(
			experimentalApi: false,
			optOutNotificationMethods: nil
		)
	)
}

// MARK: - JSON Helpers

private func encodedJSONObject(_ object: [String: Any]) throws -> Data {
	try JSONSerialization.data(withJSONObject: object, options: [.fragmentsAllowed])
}

private func jsonObject(from data: Data) throws -> [String: Any] {
	guard let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) as? [String: Any] else {
		throw TestFailure(message: "Expected JSON object payload.")
	}
	return object
}
