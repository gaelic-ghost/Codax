//
//  CodaxOrchestrator.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import Foundation
import Observation

// MARK: - App Session Management and UI Drive

@MainActor
@Observable
final class CodaxOrchestrator {
	typealias RuntimeFactory = () async throws -> CodaxOrchestrationRuntime
	typealias InitializeParamsFactory = () -> InitializeParams

	var account: Account?
	var authMode: AuthMode?
	var threads: [ThreadSummary] = []
	var activeThread: Thread?
	var connectionState: ConnectionState = .disconnected
	var loginState: LoginState = .signedOut
	var compatibility: CodaxCompatibilityState = .unknown
	var activeThreadTokenUsage: ThreadTokenUsage?
	var activeTurnPlan: [TurnPlanStep] = []
	var activeTurnDiff: String?
	var activeError: String?
	var compatibilityDebugOutput: String?
	var isLoadingThreads = false

	private let compatibilityProbe: CodexCLIProbe
	private let runtimeFactory: RuntimeFactory
	private let initializeParamsFactory: InitializeParamsFactory

	private var process: CodexProcess?
	private var connection: CodexConnection?
	private var client: CodexClient?
	private var notificationTask: Task<Void, Never>?
	private var activeThreadID: String?

	init() {
		self.compatibilityProbe = CodexCLIProbe()
		self.runtimeFactory = { try await CodaxOrchestrator.makeRuntime() }
		self.initializeParamsFactory = { CodaxOrchestrator.makeInitializeParams() }
	}

	internal init(
		compatibilityProbe: CodexCLIProbe,
		runtimeFactory: @escaping RuntimeFactory,
		initializeParamsFactory: @escaping InitializeParamsFactory
	) {
		self.compatibilityProbe = compatibilityProbe
		self.runtimeFactory = runtimeFactory
		self.initializeParamsFactory = initializeParamsFactory
	}

	internal convenience init(
		compatibilityProbe: CodexCLIProbe,
		runtimeFactory: @escaping RuntimeFactory
	) {
		self.init(
			compatibilityProbe: compatibilityProbe,
			runtimeFactory: runtimeFactory,
			initializeParamsFactory: { CodaxOrchestrator.makeInitializeParams() }
		)
	}

	func connect() async {
		guard connectionState != .connecting else { return }
		guard !(connectionState == .connected && connection != nil) else {
			connectionState = .connected
			return
		}
		if connection != nil {
			await teardownRuntime()
		}

		await refreshCompatibility()
		guard case .supported = compatibility else {
			connectionState = .disconnected
			return
		}

		connectionState = .connecting
		activeError = nil

		do {
			let runtime = try await runtimeFactory()
			process = runtime.process
			connection = runtime.connection
			client = runtime.client

			let params = initializeParamsFactory()
			_ = try await runtime.client.initialize(params)
			try await runtime.client.sendInitialized()

			startNotificationTask(connection: runtime.connection)
			connectionState = .connected
			await loadThreads()
		} catch {
			activeError = error.localizedDescription
			connectionState = .disconnected
			await teardownRuntime()
		}
	}

	func loginWithChatGPT() async {
		activeError = "ChatGPT login flow is not implemented yet."
	}

	func loadThreads() async {
		guard let client, connectionState == .connected else { return }

		isLoadingThreads = true
		defer { isLoadingThreads = false }

		guard let threadID = activeThreadID ?? activeThread?.id else {
			if let activeThread {
				upsertThread(activeThread)
			} else {
				threads = []
				activeThread = nil
			}
			return
		}

		do {
			let response = try await client.readThread(ThreadReadParams(threadId: threadID, includeTurns: true))
			activeThreadID = response.thread.id
			activeThread = response.thread
			upsertThread(response.thread)
		} catch {
			activeError = error.localizedDescription
		}
	}

	func startThread() async {
		guard let client, connectionState == .connected else { return }

		activeError = nil

		do {
			let response = try await client.startThread(
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
			activeThreadID = response.thread.id
			activeThread = response.thread
			activeThreadTokenUsage = nil
			activeTurnPlan = []
			activeTurnDiff = nil
			upsertThread(response.thread)
		} catch {
			activeError = error.localizedDescription
		}
	}

	func startTurn(inputText: String) async {
		guard let client, connectionState == .connected else { return }
		guard let threadID = activeThread?.id ?? activeThreadID else { return }

		let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty else { return }

		activeError = nil

		do {
			let response = try await client.startTurn(
				TurnStartParams(
					threadId: threadID,
					input: [.string(trimmed)],
					cwd: nil,
					approvalPolicy: nil,
					sandboxPolicy: nil,
					model: nil,
					serviceTier: nil,
					effort: nil,
					summary: nil,
					personality: nil,
					outputSchema: nil,
					collaborationMode: nil
				)
			)
			merge(turn: response.turn, intoThreadID: threadID)
		} catch {
			activeError = error.localizedDescription
		}
	}

	func selectThread(id: String) {
		activeThreadID = id
		if let thread = threads.first(where: { $0.id == id }) {
			activeThread = thread
		}
	}

	func handle(_ notification: ServerNotificationEnvelope) {
		switch notification {
		case let .error(error):
			activeError = error.error.message
			merge(turnError: error.error, intoThreadID: error.threadId, turnID: error.turnId)

		case let .accountUpdated(notification):
			if let authMode = notification.authMode {
				self.authMode = authMode
			}
			if
				let planType = notification.planType,
				case let .chatgpt(email, _) = account
			{
				account = .chatgpt(email: email, planType: planType)
			}

		case let .accountLoginCompleted(notification):
			if notification.success {
				loginState = .signedIn
			} else {
				loginState = .failed(notification.error ?? "Login failed.")
			}

		case let .threadStarted(notification):
			activeThreadID = notification.thread.id
			activeThread = notification.thread
			upsertThread(notification.thread)

		case let .threadStatusChanged(notification):
			updateThread(id: notification.threadId) { thread in
				thread.status = Self.jsonValue(for: notification.status)
			}

		case let .threadTokenUsageUpdated(notification):
			guard notification.threadId == activeThreadID || notification.threadId == activeThread?.id else { return }
			activeThreadTokenUsage = notification.tokenUsage

		case let .turnStarted(notification):
			merge(turn: notification.turn, intoThreadID: notification.threadId)

		case let .turnCompleted(notification):
			merge(turn: notification.turn, intoThreadID: notification.threadId)

		case let .turnPlanUpdated(notification):
			guard notification.threadId == activeThreadID || notification.threadId == activeThread?.id else { return }
			activeTurnPlan = notification.plan

		case let .turnDiffUpdated(notification):
			guard notification.threadId == activeThreadID || notification.threadId == activeThread?.id else { return }
			activeTurnDiff = notification.diff

		case .serverRequestResolved,
			.itemStarted,
			.itemCompleted,
			.agentMessageDelta,
			.commandExecutionOutputDelta,
			.fileChangeOutputDelta,
			.reasoningTextDelta,
			.reasoningSummaryTextDelta,
			.reasoningSummaryPartAdded,
			.unknown:
			return
		}
	}

	func refreshCompatibility() async {
		compatibility = .checking
		let debugSnapshot = await compatibilityProbe.debugProbeCompatibility()
		compatibilityDebugOutput = debugSnapshot.formattedDescription
		print("[CodaxCompatibilityProbe]\n\(debugSnapshot.formattedDescription)")
		compatibility = CodaxCompatibilityState(debugSnapshot.compatibility)
	}
}

// MARK: - Internal Helpers

private extension CodaxOrchestrator {
	struct DefaultServerRequestHandler: CodexServerRequestHandler {
		func handle(_ request: ServerRequestEnvelope) async -> ServerRequestResult {
			.unhandled
		}
	}

	static func makeRuntime() async throws -> CodaxOrchestrationRuntime {
		let process = CodexProcess()
		let transport = try await process.launchBundledCodex(arguments: [])
		let connection = CodexConnection(transport: transport, requestHandler: DefaultServerRequestHandler())
		let client = CodexClient(connection: connection)
		return CodaxOrchestrationRuntime(process: process, connection: connection, client: client)
	}

	static func makeInitializeParams() -> InitializeParams {
		let bundle = Bundle.main
		let version =
			(bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ??
			(bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ??
			"0.0.0"

		return InitializeParams(
			clientInfo: ClientInfo(
				name: "codax",
				title: "Codax",
				version: version
			),
			capabilities: InitializeCapabilities(
				experimentalApi: false,
				optOutNotificationMethods: nil
			)
		)
	}

	func startNotificationTask(connection: CodexConnection) {
		notificationTask?.cancel()
		notificationTask = Task { [weak self] in
			guard let self else { return }
			let stream = connection.notifications()
			for await notification in stream {
				guard !Task.isCancelled else { break }
				await MainActor.run {
					self.handle(notification)
				}
			}

			guard !Task.isCancelled else { return }
			await MainActor.run {
				if self.connectionState == .connected {
					self.connectionState = .disconnected
				}
			}
		}
	}

	func teardownRuntime() async {
		notificationTask?.cancel()
		notificationTask = nil

		if let connection {
			await connection.stop()
		}

		if let process {
			await process.terminate()
		}

		process = nil
		connection = nil
		client = nil
	}

	func upsertThread(_ thread: Thread) {
		if let index = threads.firstIndex(where: { $0.id == thread.id }) {
			threads[index] = thread
		} else {
			threads.append(thread)
		}
	}

	func updateThread(id: String, mutation: (inout Thread) -> Void) {
		if var activeThread, activeThread.id == id {
			mutation(&activeThread)
			self.activeThread = activeThread
			upsertThread(activeThread)
			return
		}

		guard let index = threads.firstIndex(where: { $0.id == id }) else { return }
		var thread = threads[index]
		mutation(&thread)
		threads[index] = thread
		if activeThreadID == id {
			activeThread = thread
		}
	}

	func merge(turn: Turn, intoThreadID threadID: String) {
		updateThread(id: threadID) { thread in
			if let index = thread.turns.firstIndex(where: { $0.id == turn.id }) {
				thread.turns[index] = turn
			} else {
				thread.turns.append(turn)
			}
		}
	}

	func merge(turnError: TurnError, intoThreadID threadID: String, turnID: String) {
		updateThread(id: threadID) { thread in
			guard let index = thread.turns.firstIndex(where: { $0.id == turnID }) else { return }
			thread.turns[index].error = turnError
		}
	}

	static func jsonValue(for status: ThreadStatus) -> JSONValue {
		switch status {
		case .notLoaded:
			return .object(["type": .string("notLoaded")])
		case .idle:
			return .object(["type": .string("idle")])
		case .systemError:
			return .object(["type": .string("systemError")])
		case let .active(flags):
			return .object([
				"type": .string("active"),
				"activeFlags": .array(flags.map { .string($0.rawValue) }),
			])
		}
	}
}
