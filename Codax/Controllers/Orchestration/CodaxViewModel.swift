//
//  CodaxViewModel.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import Foundation
import Observation
import SwiftData

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
	var hydratingThreadCodexIDs: Set<String> = []
	var isLoadingThreads = false
	var isRefreshingSelectedGitDiff = false

	// MARK: - Dependencies

	private let runtimeFactory: RuntimeFactory
	private let initializeParamsFactory: InitializeParamsFactory
	private let modelContext: ModelContext

	// MARK: - Internal State

	private var runtimeCoordinator: CodexRuntimeCoordinator?
	private var notificationTask: Task<Void, Never>?
	private var serverRequestTask: Task<Void, Never>?
	private var hydrationTask: Task<Void, Never>?

	// MARK: - Initialization

	init(modelContainer: ModelContainer) {
		self.runtimeFactory = { try await CodaxViewModel.makeRuntime() }
		self.initializeParamsFactory = { CodaxViewModel.makeInitializeParams() }
		self.modelContext = modelContainer.mainContext
	}

	internal init(
		runtimeFactory: @escaping RuntimeFactory,
		initializeParamsFactory: @escaping InitializeParamsFactory,
		modelContainer: ModelContainer
	) {
		self.runtimeFactory = runtimeFactory
		self.initializeParamsFactory = initializeParamsFactory
		self.modelContext = modelContainer.mainContext
	}

	internal convenience init(
		runtimeFactory: @escaping RuntimeFactory,
		modelContainer: ModelContainer
	) {
		self.init(
			runtimeFactory: runtimeFactory,
			initializeParamsFactory: { CodaxViewModel.makeInitializeParams() },
			modelContainer: modelContainer
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
			try persistThreadList(response.data)

			let selectedThreadCodexId =
				currentSelection.flatMap { threadID in
					response.data.contains(where: { $0.id == threadID }) ? threadID : nil
				} ?? response.data.first?.id

			guard let selectedThreadCodexId else {
				self.selectedThreadCodexId = nil
				return
			}

			self.selectedThreadCodexId = selectedThreadCodexId
			try await hydrateThreadDetail(
				threadCodexId: selectedThreadCodexId,
				using: runtimeCoordinator,
				force: true
			)
			await refreshSelectedGitSummary(using: runtimeCoordinator)
			startRecentHydration(
				primaryThreadCodexId: selectedThreadCodexId,
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
			try persistThreadDetail(response.thread)
			try persistThreadSession(ThreadSessionRecord(response: response))
			selectedThreadCodexId = response.thread.id
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
			try persistTurn(response.turn, threadCodexId: threadCodexId)
		} catch {
			record(error)
		}
	}

	func selectThread(codexId: String) async {
		selectedThreadCodexId = codexId
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
		do {
			try persistPendingServerRequest(PendingServerRequestRecord(envelope: request))
		} catch {
			record(error)
		}
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
		do {
			try clearPendingServerRequests()
		} catch {
			record(error)
		}
		selectedThreadCodexId = nil
		isRefreshingSelectedGitDiff = false
	}

	// MARK: Thread Hydration

	func hydrateThreadDetail(
		threadCodexId: String,
		using runtimeCoordinator: CodexRuntimeCoordinator,
		force: Bool
	) async throws {
		if !force, !(try shouldHydrateThreadDetail(codexId: threadCodexId, maxAge: 300)) {
			return
		}

		hydratingThreadCodexIDs.insert(threadCodexId)
		defer { hydratingThreadCodexIDs.remove(threadCodexId) }

		let detail = try await runtimeCoordinator.threadRead(
			ThreadReadParams(threadId: threadCodexId, includeTurns: true)
		)
		try persistThreadDetail(detail.thread)
	}

	func startRecentHydration(
		primaryThreadCodexId: String,
		using runtimeCoordinator: CodexRuntimeCoordinator
	) {
		hydrationTask?.cancel()
		hydrationTask = Task { [weak self] in
			guard let self else { return }
			do {
				let recentThreadCodexIDs = try self.recentThreadCodexIDs(
					limit: 5,
					excluding: primaryThreadCodexId
				)
				for threadCodexId in recentThreadCodexIDs {
					guard !Task.isCancelled else { break }
					if try self.shouldHydrateThreadDetail(
						codexId: threadCodexId,
						maxAge: 600
					) {
						try await self.hydrateThreadDetail(
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
		guard
			let threadCodexId = selectedThreadCodexId,
			let thread = try? fetchThread(codexId: threadCodexId)
		else {
			return
		}
		await refreshGitSummary(for: thread, using: runtimeCoordinator)
	}

	func refreshGitSummary(for thread: ThreadModel, using runtimeCoordinator: CodexRuntimeCoordinator) async {
		if selectedThreadCodexId == thread.codexId {
			isRefreshingSelectedGitDiff = true
		}

		do {
			let response = try await runtimeCoordinator.gitDiffToRemote(
				GitDiffToRemoteParams(cwd: thread.cwd)
			)
			try persistGitDiff(
				ThreadGitDiffRecord(
					threadCodexId: thread.codexId,
					response: response,
					errorMessage: nil
				)
			)
			if selectedThreadCodexId == thread.codexId {
				isRefreshingSelectedGitDiff = false
			}
		} catch {
			do {
				try persistGitDiff(
					ThreadGitDiffRecord(
						threadCodexId: thread.codexId,
						response: nil,
						errorMessage: error.localizedDescription
					)
				)
			} catch {
				record(error)
			}
			if selectedThreadCodexId == thread.codexId {
				isRefreshingSelectedGitDiff = false
			}
		}
	}

	func refreshGitSummary(for thread: Thread, using runtimeCoordinator: CodexRuntimeCoordinator) async {
		if selectedThreadCodexId == thread.id {
			isRefreshingSelectedGitDiff = true
		}

		do {
			let response = try await runtimeCoordinator.gitDiffToRemote(
				GitDiffToRemoteParams(cwd: thread.cwd)
			)
			try persistGitDiff(
				ThreadGitDiffRecord(
					threadCodexId: thread.id,
					response: response,
					errorMessage: nil
				)
			)
			if selectedThreadCodexId == thread.id {
				isRefreshingSelectedGitDiff = false
			}
		} catch {
			do {
				try persistGitDiff(
					ThreadGitDiffRecord(
						threadCodexId: thread.id,
						response: nil,
						errorMessage: error.localizedDescription
					)
				)
			} catch {
				record(error)
			}
			if selectedThreadCodexId == thread.id {
				isRefreshingSelectedGitDiff = false
			}
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
				selectedThreadCodexId = notification.thread.id
				do {
					try persistThreadDetail(notification.thread)
				} catch {
					record(error)
				}
				return true
			case let .threadStatusChanged(notification):
				do {
					try persistThreadStatus(notification.status, for: notification.threadId)
				} catch {
					record(error)
				}
				return true
			case let .threadArchived(notification):
				do {
					try persistThreadArchived(true, for: notification.threadId)
				} catch {
					record(error)
				}
				return true
			case let .threadUnarchived(notification):
				do {
					try persistThreadArchived(false, for: notification.threadId)
				} catch {
					record(error)
				}
				return true
			case let .threadClosed(notification):
				do {
					try persistThreadClosed(for: notification.threadId)
				} catch {
					record(error)
				}
				return true
			case let .threadNameUpdated(notification):
				do {
					try persistThreadName(notification.threadName, for: notification.threadId)
				} catch {
					record(error)
				}
				return true
			case let .threadTokenUsageUpdated(notification):
				do {
					try persistThreadTokenUsage(notification.tokenUsage, for: notification.threadId)
				} catch {
					record(error)
				}
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
				do {
					try persistTurn(notification.turn, threadCodexId: notification.threadId)
				} catch {
					record(error)
				}
				return true
			case let .turnCompleted(notification):
				do {
					try persistTurn(notification.turn, threadCodexId: notification.threadId)
				} catch {
					record(error)
				}
				return true
			case let .turnPlanUpdated(notification):
				do {
					try persistTurnPlan(TurnPlanRecord(notification: notification))
				} catch {
					record(error)
				}
				return true
			case let .turnDiffUpdated(notification):
				do {
					try persistTurnDiff(TurnDiffRecord(notification: notification))
				} catch {
					record(error)
				}
				return true
			default:
				return false
		}
	}

	func handleAuxiliaryNotification(_ notification: ServerNotificationEnvelope) {
		switch notification {
			case let .serverRequestResolved(notification):
				do {
					try resolvePendingServerRequest(id: notification.requestId)
				} catch {
					record(error)
				}
			default:
				return
		}
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

// MARK: - SwiftData Persistence

private extension CodaxViewModel {
	// MARK: Fetching

	func fetchThread(codexId: String) throws -> ThreadModel? {
		let descriptor = FetchDescriptor<ThreadModel>(
			predicate: #Predicate<ThreadModel> { $0.codexId == codexId }
		)
		return try modelContext.fetch(descriptor).first
	}

	// MARK: Project Persistence

	func fetchTurn(codexId: String, on thread: ThreadModel) -> TurnModel? {
		thread.turns.first(where: { $0.codexId == codexId })
	}

	func fetchPendingServerRequest(id: JSONRPCID) throws -> PendingServerRequestModel? {
		let requests = try modelContext.fetch(FetchDescriptor<PendingServerRequestModel>())
		return requests.first(where: { $0.requestId == id })
	}

	// MARK: Thread Persistence

	func persistThreadList(_ threads: [Thread]) throws {
		for thread in threads {
			let project = ensureProject(rootPath: thread.cwd)
			let record = ThreadRecord(thread: thread, hydrationState: .summary)
			let model = try fetchThread(codexId: thread.id) ?? ThreadModel(
				record: record,
				project: project
			)
			model.project = project
			if model.modelContext == nil {
				modelContext.insert(model)
			}
			if model.lastHydratedAt != nil {
				var preserved = record
				preserved.id = model.id
				preserved.lastHydratedAt = model.lastHydratedAt
				preserved.hydrationState = model.hydrationState
				preserved.isArchived = model.isArchived
				preserved.isClosed = model.isClosed
				preserved.tokenUsage = model.tokenUsage
				model.apply(preserved)
			} else {
				model.apply(record)
			}
		}
		try saveIfNeeded()
	}

	func persistThreadDetail(_ thread: Thread) throws {
		let project = ensureProject(rootPath: thread.cwd)
		let record = ThreadRecord(thread: thread, hydrationState: .detail)
		let model = try fetchThread(codexId: thread.id) ?? ThreadModel(
			record: record,
			project: project
		)
		model.project = project
		if model.modelContext == nil {
			modelContext.insert(model)
		}
		model.apply(record)
		reconcileTurns(thread.turns, on: model)
		touchProject(for: model)
		try saveIfNeeded()
	}

	func persistThreadSession(_ record: ThreadSessionRecord) throws {
		guard let thread = try fetchThread(codexId: record.threadCodexId) else { return }
		if let session = thread.session {
			session.apply(record)
		} else {
			let session = ThreadSessionModel(record: record, thread: thread)
			thread.session = session
			modelContext.insert(session)
		}
		touchProject(for: thread)
		try saveIfNeeded()
	}

	func persistGitDiff(_ record: ThreadGitDiffRecord) throws {
		guard let thread = try fetchThread(codexId: record.threadCodexId) else { return }
		if let gitDiff = thread.gitDiff {
			gitDiff.apply(record)
		} else {
			let gitDiff = ThreadGitDiffModel(record: record, thread: thread)
			thread.gitDiff = gitDiff
			modelContext.insert(gitDiff)
		}
		touchProject(for: thread)
		try saveIfNeeded()
	}

	func persistTurn(_ turn: Turn, threadCodexId: String) throws {
		guard let thread = try fetchThread(codexId: threadCodexId) else { return }
		let sequenceIndex = fetchTurn(codexId: turn.id, on: thread)?.sequenceIndex ?? thread.turns.count
		let record = TurnRecord(turn: turn, sequenceIndex: sequenceIndex)
		let model = fetchTurn(codexId: turn.id, on: thread) ?? TurnModel(
			record: record,
			thread: thread
		)
		if model.modelContext == nil {
			thread.turns.append(model)
			modelContext.insert(model)
		}
		model.apply(record)
		reconcileItems(turn.items, on: model)
		thread.lastHydratedAt = .now
		thread.hydrationState = .detail
		touchProject(for: thread)
		try saveIfNeeded()
	}

	func persistTurnPlan(_ record: TurnPlanRecord) throws {
		guard let turn = try fetchTurn(codexId: record.turnCodexId) else { return }
		if let plan = turn.plan {
			plan.apply(record)
		} else {
			let plan = TurnPlanModel(record: record, turn: turn)
			turn.plan = plan
			modelContext.insert(plan)
		}
		if let thread = turn.thread {
			touchProject(for: thread)
		}
		try saveIfNeeded()
	}

	func persistTurnDiff(_ record: TurnDiffRecord) throws {
		guard let turn = try fetchTurn(codexId: record.turnCodexId) else { return }
		if let diff = turn.diff {
			diff.apply(record)
		} else {
			let diff = TurnDiffModel(record: record, turn: turn)
			turn.diff = diff
			modelContext.insert(diff)
		}
		if let thread = turn.thread {
			touchProject(for: thread)
		}
		try saveIfNeeded()
	}

	func persistPendingServerRequest(_ record: PendingServerRequestRecord) throws {
		if let request = try fetchPendingServerRequest(id: record.requestId) {
			request.apply(record)
		} else {
			modelContext.insert(PendingServerRequestModel(record: record))
		}
		try saveIfNeeded()
	}

	func resolvePendingServerRequest(id: JSONRPCID) throws {
		guard let request = try fetchPendingServerRequest(id: id) else { return }
		modelContext.delete(request)
		try saveIfNeeded()
	}

	func clearPendingServerRequests() throws {
		let requests = try modelContext.fetch(FetchDescriptor<PendingServerRequestModel>())
		for request in requests {
			modelContext.delete(request)
		}
		try saveIfNeeded()
	}

	func persistThreadStatus(_ status: ThreadStatus, for threadCodexId: String) throws {
		guard let thread = try fetchThread(codexId: threadCodexId) else { return }
		thread.setStatus(status)
		touchProject(for: thread)
		try saveIfNeeded()
	}

	// MARK: Thread Metadata Persistence

	func persistThreadName(_ name: String?, for threadCodexId: String) throws {
		guard let thread = try fetchThread(codexId: threadCodexId) else { return }
		thread.name = name
		touchProject(for: thread)
		try saveIfNeeded()
	}

	func persistThreadTokenUsage(_ tokenUsage: ThreadTokenUsage?, for threadCodexId: String) throws {
		guard let thread = try fetchThread(codexId: threadCodexId) else { return }
		thread.setTokenUsage(tokenUsage)
		touchProject(for: thread)
		try saveIfNeeded()
	}

	func persistThreadArchived(_ isArchived: Bool, for threadCodexId: String) throws {
		guard let thread = try fetchThread(codexId: threadCodexId) else { return }
		thread.setArchived(isArchived)
		touchProject(for: thread)
		try saveIfNeeded()
	}

	func persistThreadClosed(for threadCodexId: String) throws {
		guard let thread = try fetchThread(codexId: threadCodexId) else { return }
		thread.setClosed(true)
		touchProject(for: thread)
		try saveIfNeeded()
	}

	// MARK: Hydration Queries

	func shouldHydrateThreadDetail(codexId: String, maxAge: TimeInterval) throws -> Bool {
		guard let thread = try fetchThread(codexId: codexId) else { return true }
		guard thread.hydrationState == .detail else { return true }
		guard let lastHydratedAt = thread.lastHydratedAt else { return true }
		return Date().timeIntervalSince(lastHydratedAt) > maxAge
	}

	func recentThreadCodexIDs(limit: Int, excluding excludedCodexId: String?) throws -> [String] {
		var descriptor = FetchDescriptor<ThreadModel>(
			sortBy: [SortDescriptor(\ThreadModel.updatedAt, order: .reverse)]
		)
		descriptor.fetchLimit = max(limit + (excludedCodexId == nil ? 0 : 1), limit)
		return try modelContext.fetch(descriptor)
			.filter { thread in
				!thread.isArchived && !thread.isClosed && thread.codexId != excludedCodexId
			}
			.prefix(limit)
			.map(\.codexId)
	}

	// MARK: Persistence Helpers

	func fetchTurn(codexId: String) throws -> TurnModel? {
		let turns = try modelContext.fetch(FetchDescriptor<TurnModel>())
		return turns.first(where: { $0.codexId == codexId })
	}

	func ensureProject(rootPath: String) -> Project {
		let descriptor = FetchDescriptor<Project>(
			predicate: #Predicate<Project> { $0.rootPath == rootPath }
		)
		if let project = try? modelContext.fetch(descriptor).first {
			project.activate()
			return project
		}

		let name = URL(fileURLWithPath: rootPath).lastPathComponent
		let project = Project(
			record: ProjectRecord(
				name: name.isEmpty ? rootPath : name,
				rootPath: rootPath,
				isActive: true
			)
		)
		modelContext.insert(project)
		return project
	}

	func reconcileTurns(_ turns: [Turn], on thread: ThreadModel) {
		let incomingTurnIDs = Set(turns.map(\.id))
		for (index, turn) in turns.enumerated() {
			let record = TurnRecord(turn: turn, sequenceIndex: index)
			let model = fetchTurn(codexId: turn.id, on: thread) ?? TurnModel(
				record: record,
				thread: thread
			)
			if model.modelContext == nil {
				thread.turns.append(model)
				modelContext.insert(model)
			}
			model.apply(record)
			reconcileItems(turn.items, on: model)
		}

		for storedTurn in thread.turns where !incomingTurnIDs.contains(storedTurn.codexId) {
			modelContext.delete(storedTurn)
		}
	}

	func reconcileItems(_ items: [ThreadItem], on turn: TurnModel) {
		let existingByPosition = Dictionary(uniqueKeysWithValues: turn.items.map { ($0.position, $0) })
		let validPositions = Set(items.indices)

		for (position, item) in items.enumerated() {
			let record = ItemRecord(position: position, item: item)
			if let existing = existingByPosition[position] {
				existing.apply(record)
			} else {
				let model = ItemModel(record: record, turn: turn)
				turn.items.append(model)
				modelContext.insert(model)
			}
		}

		for storedItem in turn.items where !validPositions.contains(storedItem.position) {
			modelContext.delete(storedItem)
		}
	}

	func touchProject(for thread: ThreadModel) {
		thread.project?.activate()
	}

	func saveIfNeeded() throws {
		guard modelContext.hasChanges else { return }
		try modelContext.save()
	}
}
