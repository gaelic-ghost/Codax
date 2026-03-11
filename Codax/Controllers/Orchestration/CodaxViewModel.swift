//
//  CodaxViewModel.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import Foundation
import Observation

// MARK: - App State Projection

@MainActor
@Observable
final class CodaxViewModel {
	typealias RuntimeFactory = () async throws -> CodexRuntimeCoordinator
	typealias InitializeParamsFactory = () -> InitializeParams

	var account: Account?
	var authMode: AuthMode?
	var connectionState: ConnectionState = .disconnected
	var loginState: LoginState = .signedOut
	var pendingLogin: CodaxPendingLogin?
	var compatibility: CodaxCompatibilityState = .unknown
	var isLoadingThreads = false
	var errorState: CodaxViewModelError?
	var compatibilityDebugInfo: CodaxCompatibilityDebugInfo?
	var pendingUserRequests: [CodaxPendingUserRequest] = []

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

	private let runtimeFactory: RuntimeFactory
	private let initializeParamsFactory: InitializeParamsFactory

	private var runtimeCoordinator: CodexRuntimeCoordinator?
	private var notificationTask: Task<Void, Never>?
	private var serverRequestTask: Task<Void, Never>?
	private var threadSessionState = CodaxViewModelThreadSessionState()

	init() {
		self.runtimeFactory = { try await CodaxViewModel.makeRuntime() }
		self.initializeParamsFactory = { CodaxViewModel.makeInitializeParams() }
	}

	internal init(
		runtimeFactory: @escaping RuntimeFactory,
		initializeParamsFactory: @escaping InitializeParamsFactory
	) {
		self.runtimeFactory = runtimeFactory
		self.initializeParamsFactory = initializeParamsFactory
	}

	internal convenience init(
		runtimeFactory: @escaping RuntimeFactory
	) {
		self.init(
			runtimeFactory: runtimeFactory,
			initializeParamsFactory: { CodaxViewModel.makeInitializeParams() }
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

		connectionState = .connecting
		compatibility = .checking
		compatibilityDebugInfo = nil
		errorState = nil

		do {
			let runtimeCoordinator = try await runtimeFactory()
			self.runtimeCoordinator = runtimeCoordinator
			apply(startupDebugSnapshot: try await runtimeCoordinator.start())

			let params = initializeParamsFactory()
			_ = try await runtimeCoordinator.initialize(params)
			try await runtimeCoordinator.initialized()
			await refreshAccountState(refreshToken: false)

			bindRuntimeStream(
				storingIn: \CodaxViewModel.notificationTask,
				stream: { await runtimeCoordinator.notifications() },
				onElement: { viewModel, notification in
					viewModel.handle(notification)
				},
				onFinish: { viewModel in
					if viewModel.connectionState == ConnectionState.connected {
						viewModel.connectionState = .disconnected
					}
				}
			)
			bindRuntimeStream(
				storingIn: \CodaxViewModel.serverRequestTask,
				stream: { await runtimeCoordinator.serverRequests() },
				onElement: { viewModel, request in
					viewModel.handle(request)
				}
			)
			connectionState = .connected
			await loadThreads()
		} catch {
			apply(connectError: error)
			connectionState = .disconnected
			await teardownRuntime()
		}
	}

	func loginWithChatGPT() async {
		guard connectionState == .connected, let runtimeCoordinator else { return }
		errorState = nil
		loginState = .authorizing

		do {
			let response = try await runtimeCoordinator.accountLoginStart(.chatgpt)
			switch response {
				case let .chatgpt(loginId, authUrl):
					pendingLogin = CodaxPendingLogin(loginId: loginId, authURL: authUrl)
				case .apiKey, .chatgptAuthTokens:
					pendingLogin = nil
			}
		} catch {
			loginState = .failed(error.localizedDescription)
			record(error)
		}
	}

	func loadThreads() async {
		guard connectionState == .connected, let runtimeCoordinator else { return }

		isLoadingThreads = true
		defer { isLoadingThreads = false }

		do {
			let currentSelection = threadSessionState.selectedThreadCodexId
			let response = try await runtimeCoordinator.threadList(
				ThreadListParams(
					cursor: nil,
					limit: 100,
					sortKey: nil,
					modelProviders: nil,
					sourceKinds: nil,
					archived: false,
					cwd: nil,
					searchTerm: nil
				)
			)
			threadSessionState.replaceThreads(response.data)

			let selectedThreadCodexId =
				currentSelection.flatMap { threadID in
					response.data.contains(where: { $0.id == threadID }) ? threadID : nil
				} ?? response.data.first?.id

			guard let selectedThreadCodexId else {
				threadSessionState.clearSelection()
				return
			}

			threadSessionState.selectThread(codexId: selectedThreadCodexId)
			let detail = try await runtimeCoordinator.threadRead(
				ThreadReadParams(threadId: selectedThreadCodexId, includeTurns: true)
			)
			threadSessionState.upsert(detail.thread)
		} catch {
			record(error)
		}
	}

	func startThread() async {
		guard connectionState == .connected, let runtimeCoordinator else { return }
		errorState = nil

		do {
			let response = try await runtimeCoordinator.threadStart(
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
			record(error)
		}
	}

	func startTurn(inputText: String) async {
		guard connectionState == .connected, let runtimeCoordinator else { return }
		guard let threadCodexId = threadSessionState.selectedThreadCodexId else { return }

		let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty else { return }

		errorState = nil

		do {
			let response = try await runtimeCoordinator.turnStart(
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
			threadSessionState.merge(turn: response.turn, into: threadCodexId)
		} catch {
			record(error)
		}
	}

	func selectThread(codexId: String) {
		threadSessionState.selectThread(codexId: codexId)
	}

	func handle(_ notification: ServerNotificationEnvelope) {
		if handleAccountNotification(notification) { return }
		if handleThreadNotification(notification) { return }
		if handleTurnNotification(notification) { return }
		handleAuxiliaryNotification(notification)
	}

	func handle(_ request: ServerRequestEnvelope) {
		upsertPendingUserRequest(CodaxPendingUserRequest(request))
	}
}

private extension CodaxViewModel {
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

	func bindRuntimeStream<Element: Sendable>(
		storingIn taskKeyPath: ReferenceWritableKeyPath<CodaxViewModel, Task<Void, Never>?>,
		stream: @escaping @Sendable () async -> AsyncStream<Element>,
		onElement: @escaping @MainActor (CodaxViewModel, Element) -> Void,
		onFinish: (@MainActor (CodaxViewModel) -> Void)? = nil
	) {
		self[keyPath: taskKeyPath]?.cancel()
		self[keyPath: taskKeyPath] = Task { [weak self] in
			guard let self else { return }
			let stream = await stream()
			for await element in stream {
				guard !Task.isCancelled else { break }
				await MainActor.run {
					onElement(self, element)
				}
			}

			guard !Task.isCancelled, let onFinish else { return }
			await MainActor.run {
				onFinish(self)
			}
		}
	}

	func apply(startupDebugSnapshot: CodexCLIProbe.DebugSnapshot?) {
		guard let startupDebugSnapshot else {
			compatibility = .unknown
			compatibilityDebugInfo = nil
			return
		}

		compatibility = CodaxCompatibilityState(startupDebugSnapshot.compatibility)
		compatibilityDebugInfo = CodaxCompatibilityDebugInfo(
			formattedDescription: startupDebugSnapshot.formattedDescription
		)
	}

	func apply(connectError error: Error) {
		if case let LocalCodexTransport.LaunchError.launchFailed(_, _, _, debugSnapshot) = error {
			apply(startupDebugSnapshot: debugSnapshot)
		}
		record(error)
	}

	func record(_ error: Error) {
		errorState = CodaxViewModelError(message: error.localizedDescription)
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
		pendingLogin = nil
		pendingUserRequests.removeAll()
	}

	func refreshAccountState(refreshToken: Bool) async {
		guard connectionState != .disconnected, let runtimeCoordinator else { return }

		do {
			let response = try await runtimeCoordinator.accountRead(
				GetAccountParams(refreshToken: refreshToken)
			)
			account = response.account
			if let account = response.account {
				authMode = account.authMode
				loginState = .signedIn
			} else if loginState != .authorizing {
				loginState = .signedOut
			}
		} catch {
			record(error)
		}
	}

	func handleAccountNotification(_ notification: ServerNotificationEnvelope) -> Bool {
		switch notification {
			case let .accountUpdated(notification):
				if let authMode = notification.authMode {
					self.authMode = authMode
				}
				if let planType = notification.planType, case let .chatgpt(email, _) = account {
					account = .chatgpt(email: email, planType: planType)
				}
				return true
			case let .accountLoginCompleted(notification):
				pendingLogin = nil
				loginState = notification.success ? .signedIn : .failed(notification.error ?? "Login failed.")
				if notification.success {
					Task { [weak self] in
						await self?.refreshAccountState(refreshToken: true)
					}
				}
				return true
			default:
				return false
		}
	}

	func handleThreadNotification(_ notification: ServerNotificationEnvelope) -> Bool {
		switch notification {
			case let .threadStarted(notification):
				threadSessionState.upsert(notification.thread)
				threadSessionState.selectThread(codexId: notification.thread.id)
				return true
			case let .threadStatusChanged(notification):
				threadSessionState.updateThread(codexId: notification.threadId) { thread in
					thread.status = notification.status
				}
				return true
			case let .threadTokenUsageUpdated(notification):
				threadSessionState.setTokenUsage(notification.tokenUsage, for: notification.threadId)
				return true
			default:
				return false
		}
	}

	func handleTurnNotification(_ notification: ServerNotificationEnvelope) -> Bool {
		switch notification {
			case let .error(error):
				errorState = CodaxViewModelError(message: error.error.message)
				threadSessionState.merge(turnError: error.error, into: error.threadId, turnCodexId: error.turnId)
				return true
			case let .turnStarted(notification):
				threadSessionState.merge(turn: notification.turn, into: notification.threadId)
				return true
			case let .turnCompleted(notification):
				threadSessionState.merge(turn: notification.turn, into: notification.threadId)
				return true
			case let .turnPlanUpdated(notification):
				threadSessionState.setTurnPlan(notification.plan, for: notification.threadId)
				return true
			case let .turnDiffUpdated(notification):
				threadSessionState.setTurnDiff(notification.diff, for: notification.threadId)
				return true
			default:
				return false
		}
	}

	func handleAuxiliaryNotification(_ notification: ServerNotificationEnvelope) {
		switch notification {
			case let .serverRequestResolved(notification):
				pendingUserRequests.removeAll { $0.requestId == notification.requestId }
			default:
				return
		}
	}

	func upsertPendingUserRequest(_ request: CodaxPendingUserRequest) {
		if let index = pendingUserRequests.firstIndex(where: { $0.requestId == request.requestId }) {
			pendingUserRequests[index] = request
		} else {
			pendingUserRequests.append(request)
		}
	}
}

private extension Account {
	var authMode: AuthMode {
		switch self {
			case .apiKey:
				return .apikey
			case .chatgpt:
				return .chatgpt
		}
	}
}
