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
	// MARK: - Typealiases

	typealias RuntimeFactory = () async throws -> CodexRuntimeCoordinator
	typealias InitializeParamsFactory = () -> InitializeParams

	// MARK: - Observable State

	var account: Account?
	var authMode: AuthMode?
	var loginState: LoginState = .signedOut
	var pendingLogin: CodaxPendingLogin?
	var connectionState: ConnectionState = .disconnected
	var compatibility: CodaxCompatibilityState = .unknown
	var compatibilityDebugInfo: CodaxCompatibilityDebugInfo?
	var errorState: CodaxViewModelError?

	var selectedProjectID: UUID?
	var selectedThreadID: UUID?
	var selectedThreadCodexId: String?

	var projects: [CodaxProjectState] = []
	var threads: [Thread] = []
	var pendingServerRequests: [ServerRequestEnvelope] = []

	var threadSessionsByCodexID: [String: CodaxThreadSessionState] = [:]
	var threadTokenUsageByCodexID: [String: ThreadTokenUsage] = [:]
	var threadArchivedStateByCodexID: [String: Bool] = [:]
	var threadClosedStateByCodexID: [String: Bool] = [:]
	var threadGitDiffByCodexID: [String: CodaxThreadGitDiffState] = [:]
	var turnPlansByTurnID: [String: TurnPlanUpdatedNotification] = [:]
	var turnDiffsByTurnID: [String: TurnDiffUpdatedNotification] = [:]

	var hydratingThreadCodexIDs: Set<String> = []
	var isLoadingThreads = false
	var isRefreshingSelectedGitDiff = false

	// MARK: - Dependencies

	private let runtimeFactory: RuntimeFactory
	private let initializeParamsFactory: InitializeParamsFactory

	// MARK: - Internal State

	private var runtimeCoordinator: CodexRuntimeCoordinator?
	private var notificationTask: Task<Void, Never>?
	private var serverRequestTask: Task<Void, Never>?
	private var hydrationTask: Task<Void, Never>?

	private var threadsByCodexID: [String: Thread] = [:]
	private var threadIDsByCodexID: [String: UUID] = [:]
	private var projectIDsByRootPath: [String: UUID] = [:]
	private var detailedThreadCodexIDs: Set<String> = []
	private var lastHydratedAtByThreadCodexID: [String: Date] = [:]

	// MARK: - Initialization

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

	// MARK: - Connection Lifecycle

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
					if viewModel.connectionState == .connected {
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

	// MARK: - Account Actions

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

	// MARK: - Thread Actions

	func loadThreads() async {
		guard connectionState == .connected, let runtimeCoordinator else { return }

		isLoadingThreads = true
		defer { isLoadingThreads = false }

		do {
			let currentSelection = selectedThreadCodexId
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
			replaceThreads(response.data)

			let nextSelectedThreadCodexId =
				currentSelection.flatMap { threadID in
					threadsByCodexID[threadID] != nil ? threadID : nil
				} ?? threads.first?.id

			guard let nextSelectedThreadCodexId else {
				selectedThreadCodexId = nil
				selectedThreadID = nil
				return
			}

			selectThreadState(codexId: nextSelectedThreadCodexId)
			try await hydrateThreadDetail(
				threadCodexId: nextSelectedThreadCodexId,
				using: runtimeCoordinator,
				force: true
			)
			await refreshSelectedGitSummary(using: runtimeCoordinator)
			startRecentHydration(
				primaryThreadCodexId: nextSelectedThreadCodexId,
				using: runtimeCoordinator
			)
		} catch {
			record(error)
		}
	}

	func startThread(cwd: String? = nil) async {
		guard connectionState == .connected, let runtimeCoordinator else { return }
		errorState = nil

		do {
			let response = try await runtimeCoordinator.threadStart(
				ThreadStartParams(
					model: nil,
					modelProvider: nil,
					serviceTier: nil,
					cwd: cwd,
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
			storeThread(response.thread, markHydrated: true)
			storeThreadSession(
				CodaxThreadSessionState(
					threadCodexId: response.thread.id,
					model: response.model,
					modelProvider: response.modelProvider,
					serviceTier: response.serviceTier,
					cwd: response.cwd,
					approvalPolicy: response.approvalPolicy,
					sandboxPolicy: response.sandbox,
					reasoningEffort: response.reasoningEffort
				)
			)
			selectThreadState(codexId: response.thread.id)
			await refreshGitSummary(for: response.thread, using: runtimeCoordinator)
		} catch {
			record(error)
		}
	}

	func startTurn(inputText: String) async {
		guard connectionState == .connected, let runtimeCoordinator else { return }
		guard let threadCodexId = selectedThreadCodexId else { return }

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
			storeTurn(response.turn, on: threadCodexId)
		} catch {
			record(error)
		}
	}

	func selectThread(codexId: String) async {
		selectThreadState(codexId: codexId)
		guard connectionState == .connected, let runtimeCoordinator else { return }
		do {
			try await hydrateThreadDetail(
				threadCodexId: codexId,
				using: runtimeCoordinator,
				force: false
			)
			await refreshSelectedGitSummary(using: runtimeCoordinator)
		} catch {
			record(error)
		}
	}

	// MARK: - Inbound Runtime Handling

	func handle(_ notification: ServerNotificationEnvelope) {
		if handleAccountNotification(notification) { return }
		if handleThreadNotification(notification) { return }
		if handleTurnNotification(notification) { return }
		handleAuxiliaryNotification(notification)
	}

	func handle(_ request: ServerRequestEnvelope) {
		removePendingServerRequest(id: request.id)
		pendingServerRequests.append(request)
	}
}

// MARK: - Runtime Support

private extension CodaxViewModel {
	// MARK: Factories

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

	// MARK: Stream Binding

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

	// MARK: Connection State Updates

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

	// MARK: Runtime Teardown

	func teardownRuntime() async {
		hydrationTask?.cancel()
		hydrationTask = nil
		hydratingThreadCodexIDs.removeAll()
		notificationTask?.cancel()
		notificationTask = nil
		serverRequestTask?.cancel()
		serverRequestTask = nil

		if let runtimeCoordinator {
			await runtimeCoordinator.stop()
		}

		runtimeCoordinator = nil
		pendingLogin = nil
		pendingServerRequests.removeAll()
		selectedThreadCodexId = nil
		selectedThreadID = nil
		isRefreshingSelectedGitDiff = false
	}

	// MARK: Thread Hydration

	func hydrateThreadDetail(
		threadCodexId: String,
		using runtimeCoordinator: CodexRuntimeCoordinator,
		force: Bool
	) async throws {
		if !force, !shouldHydrateThreadDetail(codexId: threadCodexId, maxAge: 300) {
			return
		}

		hydratingThreadCodexIDs.insert(threadCodexId)
		defer { hydratingThreadCodexIDs.remove(threadCodexId) }

		let detail = try await runtimeCoordinator.threadRead(
			ThreadReadParams(threadId: threadCodexId, includeTurns: true)
		)
		storeThread(detail.thread, markHydrated: true)
	}

	func startRecentHydration(
		primaryThreadCodexId: String,
		using runtimeCoordinator: CodexRuntimeCoordinator
	) {
		hydrationTask?.cancel()
		hydrationTask = Task { [weak self] in
			guard let self else { return }
			do {
				let recentThreadCodexIDs = recentThreadCodexIDs(
					limit: 5,
					excluding: primaryThreadCodexId
				)
				for threadCodexId in recentThreadCodexIDs {
					guard !Task.isCancelled else { break }
					if shouldHydrateThreadDetail(
						codexId: threadCodexId,
						maxAge: 600
					) {
						try await hydrateThreadDetail(
							threadCodexId: threadCodexId,
							using: runtimeCoordinator,
							force: false
						)
					}
				}
			} catch {
				await MainActor.run {
					self.record(error)
				}
			}
		}
	}

	// MARK: Git Summary

	func refreshSelectedGitSummary(using runtimeCoordinator: CodexRuntimeCoordinator) async {
		guard let thread = selectedThread else { return }
		await refreshGitSummary(for: thread, using: runtimeCoordinator)
	}

	func refreshGitSummary(for thread: Thread, using runtimeCoordinator: CodexRuntimeCoordinator) async {
		if selectedThreadCodexId == thread.id {
			isRefreshingSelectedGitDiff = true
		}

		do {
			let response = try await runtimeCoordinator.gitDiffToRemote(
				GitDiffToRemoteParams(cwd: thread.cwd)
			)
			threadGitDiffByCodexID[thread.id] = CodaxThreadGitDiffState(
				threadCodexId: thread.id,
				response: response,
				errorMessage: nil,
				updatedAt: .now
			)
		} catch {
			threadGitDiffByCodexID[thread.id] = CodaxThreadGitDiffState(
				threadCodexId: thread.id,
				response: nil,
				errorMessage: error.localizedDescription,
				updatedAt: .now
			)
		}

		if selectedThreadCodexId == thread.id {
			isRefreshingSelectedGitDiff = false
		}
	}

	// MARK: Account Refresh

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

	// MARK: Notification Routing

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
				storeThread(notification.thread, markHydrated: true)
				selectThreadState(codexId: notification.thread.id)
				return true
			case let .threadStatusChanged(notification):
				updateThread(notification.threadId) { $0.status = notification.status }
				return true
			case let .threadArchived(notification):
				threadArchivedStateByCodexID[notification.threadId] = true
				rebuildProjects()
				return true
			case let .threadUnarchived(notification):
				threadArchivedStateByCodexID[notification.threadId] = false
				rebuildProjects()
				return true
			case let .threadClosed(notification):
				threadClosedStateByCodexID[notification.threadId] = true
				rebuildProjects()
				return true
			case let .threadNameUpdated(notification):
				updateThread(notification.threadId) { $0.name = notification.threadName }
				return true
			case let .threadTokenUsageUpdated(notification):
				threadTokenUsageByCodexID[notification.threadId] = notification.tokenUsage
				return true
			default:
				return false
		}
	}

	func handleTurnNotification(_ notification: ServerNotificationEnvelope) -> Bool {
		switch notification {
			case let .error(error):
				errorState = CodaxViewModelError(message: error.error.message)
				return true
			case let .turnStarted(notification):
				storeTurn(notification.turn, on: notification.threadId)
				return true
			case let .turnCompleted(notification):
				storeTurn(notification.turn, on: notification.threadId)
				return true
			case let .turnPlanUpdated(notification):
				turnPlansByTurnID[notification.turnId] = notification
				return true
			case let .turnDiffUpdated(notification):
				turnDiffsByTurnID[notification.turnId] = notification
				return true
			default:
				return false
		}
	}

	func handleAuxiliaryNotification(_ notification: ServerNotificationEnvelope) {
		switch notification {
			case let .serverRequestResolved(notification):
				removePendingServerRequest(id: notification.requestId)
			default:
				return
		}
	}

	// MARK: Thread State

	var selectedThread: Thread? {
		guard let selectedThreadCodexId else { return nil }
		return threadsByCodexID[selectedThreadCodexId]
	}

	func replaceThreads(_ incomingThreads: [Thread]) {
		var nextThreadsByCodexID = threadsByCodexID
		for thread in incomingThreads {
			nextThreadsByCodexID[thread.id] = mergeThread(existing: nextThreadsByCodexID[thread.id], incoming: thread)
			threadIDsByCodexID[thread.id, default: UUID()] = threadIDsByCodexID[thread.id] ?? UUID()
		}
		threadsByCodexID = nextThreadsByCodexID
		syncThreadsProjection()
		rebuildProjects()
	}

	func storeThread(_ thread: Thread, markHydrated: Bool) {
		threadIDsByCodexID[thread.id, default: UUID()] = threadIDsByCodexID[thread.id] ?? UUID()
		threadsByCodexID[thread.id] = mergeThread(existing: threadsByCodexID[thread.id], incoming: thread)
		if markHydrated {
			detailedThreadCodexIDs.insert(thread.id)
			lastHydratedAtByThreadCodexID[thread.id] = .now
		}
		syncThreadsProjection()
		rebuildProjects()
		if selectedThreadCodexId == thread.id {
			selectedThreadID = threadIDsByCodexID[thread.id]
			selectProject(forRootPath: thread.cwd)
		}
	}

	func storeThreadSession(_ session: CodaxThreadSessionState) {
		threadSessionsByCodexID[session.threadCodexId] = session
	}

	func storeTurn(_ turn: Turn, on threadCodexId: String) {
		updateThread(threadCodexId) { thread in
			var turns = thread.turns
			if let index = turns.firstIndex(where: { $0.id == turn.id }) {
				turns[index] = turn
			} else {
				turns.append(turn)
			}
			thread.turns = turns
		}
		detailedThreadCodexIDs.insert(threadCodexId)
		lastHydratedAtByThreadCodexID[threadCodexId] = .now
	}

	func updateThread(_ threadCodexId: String, mutate: (inout Thread) -> Void) {
		guard var thread = threadsByCodexID[threadCodexId] else { return }
		mutate(&thread)
		threadsByCodexID[threadCodexId] = thread
		syncThreadsProjection()
		rebuildProjects()
	}

	func mergeThread(existing: Thread?, incoming: Thread) -> Thread {
		guard let existing else { return incoming }
		var merged = incoming
		if incoming.turns.isEmpty, !existing.turns.isEmpty {
			merged.turns = existing.turns
		}
		return merged
	}

	func syncThreadsProjection() {
		threads = threadsByCodexID.values.sorted { lhs, rhs in
			if lhs.updatedAt == rhs.updatedAt {
				return lhs.createdAt > rhs.createdAt
			}
			return lhs.updatedAt > rhs.updatedAt
		}
	}

	func shouldHydrateThreadDetail(codexId: String, maxAge: TimeInterval) -> Bool {
		guard threadsByCodexID[codexId] != nil else { return true }
		guard detailedThreadCodexIDs.contains(codexId) else { return true }
		guard let lastHydratedAt = lastHydratedAtByThreadCodexID[codexId] else { return true }
		return Date().timeIntervalSince(lastHydratedAt) > maxAge
	}

	func recentThreadCodexIDs(limit: Int, excluding excludedCodexId: String?) -> [String] {
		threads
			.filter { thread in
				thread.id != excludedCodexId &&
					threadArchivedStateByCodexID[thread.id] != true &&
					threadClosedStateByCodexID[thread.id] != true
			}
			.prefix(limit)
			.map(\.id)
	}

	// MARK: Project State

	func rebuildProjects() {
		let groupedThreads = Dictionary(grouping: threads) { $0.cwd }
		projects = groupedThreads
			.map { rootPath, threads in
				let projectID = projectIDsByRootPath[rootPath] ?? UUID()
				projectIDsByRootPath[rootPath] = projectID
				let name = URL(fileURLWithPath: rootPath).lastPathComponent
				let updatedAt = threads.map(\.updatedAt).max() ?? 0
				return CodaxProjectState(
					id: projectID,
					name: name.isEmpty ? rootPath : name,
					rootPath: rootPath,
					isActive: selectedProjectID == projectID,
					threadCodexIDs: threads.map(\.id),
					updatedAt: Date(timeIntervalSince1970: TimeInterval(updatedAt))
				)
			}
			.sorted { lhs, rhs in
				if lhs.updatedAt == rhs.updatedAt {
					return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
				}
				return lhs.updatedAt > rhs.updatedAt
			}

		if let selectedProjectID, !projects.contains(where: { $0.id == selectedProjectID }) {
			self.selectedProjectID = projects.first?.id
		}
	}

	func selectThreadState(codexId: String) {
		selectedThreadCodexId = codexId
		selectedThreadID = threadID(for: codexId)
		if let thread = threadsByCodexID[codexId] {
			selectProject(forRootPath: thread.cwd)
		}
	}

	func selectProject(forRootPath rootPath: String) {
		let projectID = projectIDsByRootPath[rootPath] ?? UUID()
		projectIDsByRootPath[rootPath] = projectID
		selectedProjectID = projectID
		for index in projects.indices {
			projects[index].isActive = projects[index].id == projectID
		}
	}

	func threadID(for codexId: String) -> UUID {
		if let id = threadIDsByCodexID[codexId] {
			return id
		}
		let id = UUID()
		threadIDsByCodexID[codexId] = id
		return id
	}

	// MARK: Server Request State

	func removePendingServerRequest(id: JSONRPCID) {
		pendingServerRequests.removeAll { $0.id == id }
	}
}

// MARK: - Account Helpers

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
