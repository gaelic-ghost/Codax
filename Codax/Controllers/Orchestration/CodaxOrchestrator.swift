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
	typealias RuntimeFactory = () async throws -> CodexRuntimeCoordinator
	typealias InitializeParamsFactory = () -> InitializeParams

	var account: Account?
	var authMode: AuthMode?
	var threads: [Thread] = []
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

	private var runtimeCoordinator: CodexRuntimeCoordinator?
	private var notificationTask: Task<Void, Never>?
	private var serverRequestTask: Task<Void, Never>?
	private var activeThreadCodexId: String?

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
		guard !(connectionState == .connected && runtimeCoordinator != nil) else {
			connectionState = .connected
			return
		}
		if runtimeCoordinator != nil {
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
			let runtimeCoordinator = try await runtimeFactory()
			self.runtimeCoordinator = runtimeCoordinator
			try await runtimeCoordinator.start()

			let params = initializeParamsFactory()
			_ = try await runtimeCoordinator.initialize(params)
			try await runtimeCoordinator.sendInitialized()

			startNotificationTask(runtimeCoordinator: runtimeCoordinator)
			startServerRequestTask(runtimeCoordinator: runtimeCoordinator)
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
		guard connectionState == .connected, let client = await runtimeCoordinator?.client() else { return }

		isLoadingThreads = true
		defer { isLoadingThreads = false }

		guard let threadCodexId = activeThreadCodexId ?? activeThread?.codexId else {
			if let activeThread {
				upsertThread(activeThread)
			} else {
				threads = []
				activeThread = nil
			}
			return
		}

		do {
			let response = try await client.readThread(ThreadReadParams(threadCodexId: threadCodexId, includeTurns: true))
			activeThreadCodexId = response.thread.codexId
			activeThread = response.thread
			upsertThread(response.thread)
		} catch {
			activeError = error.localizedDescription
		}
	}

	func startThread() async {
		guard connectionState == .connected, let client = await runtimeCoordinator?.client() else { return }

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
			activeThreadCodexId = response.thread.codexId
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
		guard connectionState == .connected, let client = await runtimeCoordinator?.client() else { return }
		guard let threadCodexId = activeThread?.codexId ?? activeThreadCodexId else { return }

		let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty else { return }

		activeError = nil

		do {
			let response = try await client.startTurn(
				TurnStartParams(
					threadCodexId: threadCodexId,
					input: [.text(text: trimmed, textElements: [])],
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
			merge(turn: response.turn, intoThreadCodexId: threadCodexId)
		} catch {
			activeError = error.localizedDescription
		}
	}

	func selectThread(codexId: String) {
		activeThreadCodexId = codexId
		if let thread = threads.first(where: { $0.codexId == codexId }) {
			activeThread = thread
		}
	}

	// MARK: Server Notification Handling

	func handle(_ notification: ServerNotificationEnvelope) {
		switch notification {
		case let .error(error):
			activeError = error.error.message
			merge(turnError: error.error, intoThreadCodexId: error.threadCodexId, turnCodexId: error.turnCodexId)

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
			activeThreadCodexId = notification.thread.codexId
			activeThread = notification.thread
			upsertThread(notification.thread)

		case let .threadStatusChanged(notification):
			updateThread(codexId: notification.threadCodexId) { thread in
				thread.status = notification.status
			}

		case let .threadTokenUsageUpdated(notification):
			guard notification.threadCodexId == activeThreadCodexId || notification.threadCodexId == activeThread?.codexId else { return }
			activeThreadTokenUsage = notification.tokenUsage

		case let .turnStarted(notification):
			merge(turn: notification.turn, intoThreadCodexId: notification.threadCodexId)

		case let .turnCompleted(notification):
			merge(turn: notification.turn, intoThreadCodexId: notification.threadCodexId)

		case let .turnPlanUpdated(notification):
			guard notification.threadCodexId == activeThreadCodexId || notification.threadCodexId == activeThread?.codexId else { return }
			activeTurnPlan = notification.plan

		case let .turnDiffUpdated(notification):
			guard notification.threadCodexId == activeThreadCodexId || notification.threadCodexId == activeThread?.codexId else { return }
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

	func handle(_ request: ServerRequestEnvelope) {
		switch request {
		case .chatgptAuthRefresh,
			.fileChangeApproval,
			.applyPatchApproval,
			.userInput,
			.dynamicToolCall,
			.mcpServerElicitation,
			.commandApproval,
			.execCommandApproval,
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
	static func makeRuntime() async throws -> CodexRuntimeCoordinator {
		CodexRuntimeCoordinator()
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

	func startNotificationTask(runtimeCoordinator: CodexRuntimeCoordinator) {
		notificationTask?.cancel()
		notificationTask = Task { [weak self] in
			guard let self else { return }
			let stream = runtimeCoordinator.notifications()
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

	func startServerRequestTask(runtimeCoordinator: CodexRuntimeCoordinator) {
		serverRequestTask?.cancel()
		serverRequestTask = Task { [weak self] in
			guard let self else { return }
			let stream = runtimeCoordinator.serverRequests()
			for await request in stream {
				guard !Task.isCancelled else { break }
				await MainActor.run {
					self.handle(request)
				}
			}
		}
	}

	func teardownRuntime() async {
		notificationTask?.cancel()
		notificationTask = nil
		serverRequestTask?.cancel()
		serverRequestTask = nil

		if let runtimeCoordinator {
			await runtimeCoordinator.stop()
		}

		runtimeCoordinator = nil
	}

	func upsertThread(_ thread: Thread) {
		if let index = threads.firstIndex(where: { $0.codexId == thread.codexId }) {
			threads[index] = thread
		} else {
			threads.append(thread)
		}
	}

	func updateThread(codexId: String, mutation: (inout Thread) -> Void) {
		if var activeThread, activeThread.codexId == codexId {
			mutation(&activeThread)
			self.activeThread = activeThread
			upsertThread(activeThread)
			return
		}

		guard let index = threads.firstIndex(where: { $0.codexId == codexId }) else { return }
		var thread = threads[index]
		mutation(&thread)
		threads[index] = thread
		if activeThreadCodexId == codexId {
			activeThread = thread
		}
	}

	func merge(turn: Turn, intoThreadCodexId threadCodexId: String) {
		updateThread(codexId: threadCodexId) { thread in
			if let index = thread.turns.firstIndex(where: { $0.codexId == turn.codexId }) {
				thread.turns[index] = turn
			} else {
				thread.turns.append(turn)
			}
		}
	}

	func merge(turnError: TurnError, intoThreadCodexId threadCodexId: String, turnCodexId: String) {
		updateThread(codexId: threadCodexId) { thread in
			guard let index = thread.turns.firstIndex(where: { $0.codexId == turnCodexId }) else { return }
			thread.turns[index].error = turnError
		}
	}
}
