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
	var connectionState: ConnectionState = .disconnected
	var loginState: LoginState = .signedOut
	var compatibility: CodaxCompatibilityState = .unknown
	var isLoadingThreads = false
	var errorState: CodaxOrchestratorError?
	var compatibilityDebugInfo: CodaxCompatibilityDebugInfo?

	var threads: [Thread] {
		get { threadSessionState.threads }
		set { threadSessionState.replaceThreads(newValue) }
	}

	var selectedThreadCodexId: String? {
		get { threadSessionState.selectedThreadCodexId }
		set {
			guard let newValue else {
				threadSessionState.selectedThreadCodexId = nil
				return
			}
			threadSessionState.selectThread(codexId: newValue)
		}
	}

	var activeThread: Thread? {
		get { threadSessionState.selectedThread }
		set { threadSessionState.setSelectedThread(newValue) }
	}

	var activeThreadTokenUsage: ThreadTokenUsage? {
		get { threadSessionState.selectedTokenUsage }
		set {
			guard let threadCodexId = threadSessionState.selectedThreadCodexId else { return }
			threadSessionState.setTokenUsage(newValue, for: threadCodexId)
		}
	}

	var activeTurnPlan: [TurnPlanStep] {
		get { threadSessionState.selectedTurnPlan }
		set {
			guard let threadCodexId = threadSessionState.selectedThreadCodexId else { return }
			threadSessionState.setTurnPlan(newValue, for: threadCodexId)
		}
	}

	var activeTurnDiff: String? {
		get { threadSessionState.selectedTurnDiff }
		set {
			guard let threadCodexId = threadSessionState.selectedThreadCodexId else { return }
			threadSessionState.setTurnDiff(newValue, for: threadCodexId)
		}
	}

	private let compatibilityProbe: CodexCLIProbe
	private let runtimeFactory: RuntimeFactory
	private let initializeParamsFactory: InitializeParamsFactory

	private var runtimeCoordinator: CodexRuntimeCoordinator?
	private var notificationTask: Task<Void, Never>?
	private var serverRequestTask: Task<Void, Never>?
	private var threadSessionState = CodaxThreadSessionState()

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
		errorState = nil

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
			errorState = CodaxOrchestratorError(message: error.localizedDescription)
			connectionState = .disconnected
			await teardownRuntime()
		}
	}

	func loginWithChatGPT() async {
		errorState = CodaxOrchestratorError(message: "ChatGPT login flow is not implemented yet.")
	}

	func loadThreads() async {
		guard connectionState == .connected, let connection = await runtimeCoordinator?.connection() else { return }

		isLoadingThreads = true
		defer { isLoadingThreads = false }

		guard let threadCodexId = threadSessionState.selectedThreadCodexId else {
			return
		}

		do {
			let response = try await connection.threadRead(ThreadReadParams(threadId: threadCodexId, includeTurns: true))
			threadSessionState.upsert(response.thread)
			threadSessionState.selectThread(codexId: response.thread.id)
		} catch {
			errorState = CodaxOrchestratorError(message: error.localizedDescription)
		}
	}

	func startThread() async {
		guard connectionState == .connected, let connection = await runtimeCoordinator?.connection() else { return }

		errorState = nil

		do {
			let response = try await connection.threadStart(
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
			threadSessionState.upsert(response.thread)
			threadSessionState.selectThread(codexId: response.thread.id)
			threadSessionState.clearSelectedTransientState()
		} catch {
			errorState = CodaxOrchestratorError(message: error.localizedDescription)
		}
	}

	func startTurn(inputText: String) async {
		guard connectionState == .connected, let connection = await runtimeCoordinator?.connection() else { return }
		guard let threadCodexId = threadSessionState.selectedThreadCodexId else { return }

		let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty else { return }

		errorState = nil

		do {
			let response = try await connection.turnStart(
				TurnStartParams(
					threadId: threadCodexId,
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
			errorState = CodaxOrchestratorError(message: error.localizedDescription)
		}
	}

	func selectThread(codexId: String) {
		threadSessionState.selectThread(codexId: codexId)
	}

	// MARK: Server Notification Handling

	func handle(_ notification: ServerNotificationEnvelope) {
		switch notification {
		case let .error(error):
			errorState = CodaxOrchestratorError(message: error.error.message)
			merge(turnError: error.error, intoThreadCodexId: error.threadId, turnCodexId: error.turnId)

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
			threadSessionState.upsert(notification.thread)
			threadSessionState.selectThread(codexId: notification.thread.id)

		case let .threadStatusChanged(notification):
			threadSessionState.updateThread(codexId: notification.threadId) { thread in
				thread.status = notification.status
			}

		case let .threadTokenUsageUpdated(notification):
			threadSessionState.setTokenUsage(notification.tokenUsage, for: notification.threadId)

		case let .turnStarted(notification):
			threadSessionState.merge(turn: notification.turn, into: notification.threadId)

		case let .turnCompleted(notification):
			threadSessionState.merge(turn: notification.turn, into: notification.threadId)

		case let .turnPlanUpdated(notification):
			threadSessionState.setTurnPlan(notification.plan, for: notification.threadId)

		case let .turnDiffUpdated(notification):
			threadSessionState.setTurnDiff(notification.diff, for: notification.threadId)

		case .serverRequestResolved,
			.itemStarted,
			.itemCompleted,
			.itemAgentMessageDelta,
			.itemCommandExecutionOutputDelta,
			.itemFileChangeOutputDelta,
			.itemReasoningTextDelta,
			.itemReasoningSummaryTextDelta,
			.itemReasoningSummaryPartAdded:
			return

		default:
			return
		}
	}

	// MARK: Server Request Handling

	func handle(_ request: ServerRequestEnvelope) {
		switch request {
		case .itemFileChangeRequestApproval,
			.applyPatchApproval,
			.itemToolRequestUserInput,
			.itemToolCall,
			.mcpServerElicitationRequest,
			.itemCommandExecutionRequestApproval,
			.execCommandApproval,
			.accountChatgptAuthTokensRefresh:
			return
		}
	}

		// MARK: Compatibility

	func refreshCompatibility() async {
		compatibility = .checking
		let debugSnapshot = await compatibilityProbe.debugProbeCompatibility()
		compatibilityDebugInfo = CodaxCompatibilityDebugInfo(formattedDescription: debugSnapshot.formattedDescription)
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
			let stream = await runtimeCoordinator.notifications()
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
			let stream = await runtimeCoordinator.serverRequests()
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

	func merge(turn: Turn, intoThreadCodexId threadCodexId: String) {
		threadSessionState.merge(turn: turn, into: threadCodexId)
	}

	func merge(turnError: TurnError, intoThreadCodexId threadCodexId: String, turnCodexId: String) {
		threadSessionState.merge(turnError: turnError, into: threadCodexId, turnCodexId: turnCodexId)
	}
}
