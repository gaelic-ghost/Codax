//
//  CodaxOrchestrator.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class CodaxOrchestrator {

	typealias CodexId = String

	@ObservationIgnored
	let runtime = CodexRuntimeCoordinator()

	@ObservationIgnored
	private var notificationObservationTask: Task<Void, Never>?

	@ObservationIgnored
	private var serverRequestObservationTask: Task<Void, Never>?

		// MARK: - OBSERVABLE STATE FOR UI GOES HERE

	var userAccount: UserAccount?
	var appStatus = CodaxAppStatus()
	var pendingServerRequests: [PendingServerRequestRecord] = []

	var projects: [CodaxProject] = []
	var projectListings: [CodaxProjectListing] = []
	var selectedProject: CodaxProject?
	var selectedProjectThreadListings: [CodaxProjectThreadListing] = []
	var selectedProjectThread: CodaxProjectThread?
	var selectedProjectThreadChunks: [CodexId: [Int: CodaxProjectThreadChunk]] = [:]

		// MARK: - RAW TYPES

		// MARK: Account & Auth

	var loginAccountResponse: LoginAccountResponse?
	var cancelLoginAccountResponse: CancelLoginAccountResponse?
	var logoutAccountResponse: LogoutAccountResponse?
	var getAccountRateLimitsResponse: GetAccountRateLimitsResponse?
	var getAccountResponse: GetAccountResponse?
	var getAuthStatusResponse: GetAuthStatusResponse?

		// MARK: Initialization

	var initializeResponse: InitializeResponse?

		// MARK: Models

	var modelListResponse: ModelListResponse?

		// MARK: Experimental Features

	var experimentalFeatureListResponse: ExperimentalFeatureListResponse?

		// MARK: Apps

	var appsListResponse: AppsListResponse?

		// MARK: Commands

	var commandExecResponse: CommandExecResponse?
	var commandExecWriteResponse: CommandExecWriteResponse?
	var commandExecTerminateResponse: CommandExecTerminateResponse?
	var commandExecResizeResponse: CommandExecResizeResponse?

		// MARK: Config

	var configReadResponse: ConfigReadResponse?
	var configRequirementsReadResponse: ConfigRequirementsReadResponse?
	var configWriteResponse: ConfigWriteResponse?

		// MARK: External Agent Config

	var externalAgentConfigDetectResponse: ExternalAgentConfigDetectResponse?
	var externalAgentConfigImportResponse: ExternalAgentConfigImportResponse?

		// MARK: Fuzzy File Search

	var fuzzyFileSearchResponse: FuzzyFileSearchResponse?

		// MARK: Git Diff To Remote

	var gitDiffToRemoteResponse: GitDiffToRemoteResponse?

		// MARK: MCP Servers

	var mcpServerRefreshResponse: McpServerRefreshResponse?
	var mcpServerOauthLoginResponse: McpServerOauthLoginResponse?
	var listMcpServerStatusResponse: ListMcpServerStatusResponse?

		// MARK: Plugins

	var pluginListResponse: PluginListResponse?
	var pluginInstallResponse: PluginInstallResponse?
	var pluginUninstallResponse: PluginUninstallResponse?

		// MARK: Review

	var reviewStartResponse: ReviewStartResponse?

		// MARK: Skills

	var skillsListResponse: SkillsListResponse?
	var skillsRemoteReadResponse: SkillsRemoteReadResponse?
	var skillsRemoteWriteResponse: SkillsRemoteWriteResponse?
	var skillsConfigWriteResponse: SkillsConfigWriteResponse?

		// MARK: Conversation Summary

	var getConversationSummaryResponse: GetConversationSummaryResponse?


		// MARK: Threads

	var threadStartResponse: ThreadStartResponse?
	var threadResumeResponse: ThreadResumeResponse?
	var threadForkResponse: ThreadForkResponse?
	var threadArchiveResponse: ThreadArchiveResponse?
	var threadUnsubscribeResponse: ThreadUnsubscribeResponse?
	var threadSetNameResponse: ThreadSetNameResponse?
	var threadMetadataUpdateResponse: ThreadMetadataUpdateResponse?
	var threadUnarchiveResponse: ThreadUnarchiveResponse?
	var threadCompactStartResponse: ThreadCompactStartResponse?
	var threadRollbackResponse: ThreadRollbackResponse?
	var threadListResponse: ThreadListResponse?
	var threadLoadedListResponse: ThreadLoadedListResponse?
	var threadReadResponse: ThreadReadResponse?
	var feedbackUploadResponse: FeedbackUploadResponse?

		// MARK: Turns

	var turnStartResponse: TurnStartResponse?
	var turnSteerResponse: TurnSteerResponse?
	var turnInterruptResponse: TurnInterruptResponse?

	// MARK: - INITIALIZERS

	init() {

	}

	// MARK: - METHODS

}

	// MARK: STARTUP & CODEX INITIALIZATION

extension CodaxOrchestrator {

	func start(arguments: [String] = []) async throws {
		_ = try await runtime.start(arguments: arguments)
		startObservingRuntimeEvents()
		_ = try await initialize(params: makeInitializeParams())
		try await runtime.initialized()
		_ = try await accountRead(params: GetAccountParams(refreshToken: false))
	}

	func stop() async {
		stopObservingRuntimeEvents()
		await runtime.stop()
	}

	private func makeInitializeParams() -> InitializeParams {
		InitializeParams(
			clientInfo: ClientInfo(
				name: "codax",
				title: "Codax",
				version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
			),
			capabilities: InitializeCapabilities(
				experimentalApi: false,
				optOutNotificationMethods: nil
				)
			)
	}

	private func startObservingRuntimeEvents() {
		stopObservingRuntimeEvents()

		notificationObservationTask = Task { [weak self] in
			guard let self else { return }
			let notifications = await self.runtime.notifications()
			for await notification in notifications {
				guard !Task.isCancelled else { break }
				self.handle(serverNotification: notification)
			}
		}

		serverRequestObservationTask = Task { [weak self] in
			guard let self else { return }
			let serverRequests = await self.runtime.serverRequests()
			for await request in serverRequests {
				guard !Task.isCancelled else { break }
				self.handle(serverRequest: request)
			}
		}
	}

	private func stopObservingRuntimeEvents() {
		notificationObservationTask?.cancel()
		notificationObservationTask = nil

		serverRequestObservationTask?.cancel()
		serverRequestObservationTask = nil
	}
}

		// MARK: - SUPPORTING ServerNotification, ServerRequest TYPES FOR UI STATE

extension CodaxOrchestrator {
}

		// MARK: ACTIONABLE SERVER NOTIFICATIONS

extension CodaxOrchestrator {

	func handle(serverNotification notification: ServerNotificationEnvelope) {
		switch notification {
		case let .error(error):
			appStatus.latestErrorMessage = error.error.message
			updateThreadListing(threadId: error.threadId) { listing in
				listing.summary = error.error.message
				listing.isPending = error.willRetry || hasPendingServerRequest(for: error.threadId)
				listing.lastActive = .now
			}
			updateSelectedThreadListing(threadId: error.threadId) { listing in
				listing.summary = error.error.message
				listing.isPending = error.willRetry || hasPendingServerRequest(for: error.threadId)
				listing.lastActive = .now
			}

		case let .threadStarted(notification):
			upsertThread(notification.thread)

		case let .threadStatusChanged(notification):
			updateThreadListing(threadId: notification.threadId) { listing in
				listing.summary = threadSummary(from: notification.status)
				listing.isPending = isThreadPending(notification.status) || hasPendingServerRequest(for: notification.threadId)
				listing.lastActive = .now
			}
			updateSelectedThreadListing(threadId: notification.threadId) { listing in
				listing.summary = threadSummary(from: notification.status)
				listing.isPending = isThreadPending(notification.status) || hasPendingServerRequest(for: notification.threadId)
			}

		case let .threadArchived(notification):
			removeThread(threadId: notification.threadId)

		case let .threadUnarchived(notification):
			restoreSelectedThreadListingIfNeeded(threadId: notification.threadId)

		case let .threadClosed(notification):
			removeThread(threadId: notification.threadId)

		case let .threadNameUpdated(notification):
			updateThreadListing(threadId: notification.threadId) { listing in
				if let threadName = notification.threadName?.trimmingCharacters(in: .whitespacesAndNewlines), !threadName.isEmpty {
					listing.name = threadName
				}
			}
			updateSelectedThreadListing(threadId: notification.threadId) { listing in
				if let threadName = notification.threadName?.trimmingCharacters(in: .whitespacesAndNewlines), !threadName.isEmpty {
					listing.name = threadName
				}
			}

		case let .turnStarted(notification):
			upsertTurn(notification.turn, in: notification.threadId)
			updateThreadListing(threadId: notification.threadId) { listing in
				listing.summary = "Running"
				listing.isPending = true
				listing.isUnread = selectedProjectThread?.listing.codexId != notification.threadId
				listing.lastActive = .now
			}
			updateSelectedThreadListing(threadId: notification.threadId) { listing in
				listing.summary = "Running"
				listing.isPending = true
				listing.isUnread = false
				listing.lastActive = .now
			}

		case let .turnCompleted(notification):
			upsertTurn(notification.turn, in: notification.threadId)
			updateThreadListing(threadId: notification.threadId) { listing in
				listing.summary = hasPendingServerRequest(for: notification.threadId) ? "Waiting on approval" : "Idle"
				listing.isPending = hasPendingServerRequest(for: notification.threadId)
				listing.lastActive = .now
			}
			updateSelectedThreadListing(threadId: notification.threadId) { listing in
				listing.summary = hasPendingServerRequest(for: notification.threadId) ? "Waiting on approval" : "Idle"
				listing.isPending = hasPendingServerRequest(for: notification.threadId)
				listing.isUnread = false
				listing.lastActive = .now
			}

		case let .serverRequestResolved(notification):
			removePendingServerRequest(id: notification.requestId)
			updateThreadListing(threadId: notification.threadId) { listing in
				listing.isPending = hasPendingServerRequest(for: notification.threadId)
				if !listing.isPending, listing.summary == "Waiting on approval" {
					listing.summary = "Idle"
				}
				listing.lastActive = .now
			}
			updateSelectedThreadListing(threadId: notification.threadId) { listing in
				listing.isPending = hasPendingServerRequest(for: notification.threadId)
				if !listing.isPending, listing.summary == "Waiting on approval" {
					listing.summary = "Idle"
				}
				listing.isUnread = false
				listing.lastActive = .now
			}

		case let .accountUpdated(notification):
			userAccount = UserAccount(
				authMode: notification.authMode,
				planType: notification.planType,
				rateLimits: userAccount?.rateLimits
			)

		case let .accountRateLimitsUpdated(notification):
			userAccount = UserAccount(
				authMode: userAccount?.authMode,
				planType: userAccount?.planType,
				rateLimits: notification.rateLimits
			)

		case let .appListUpdated(notification):
			appStatus.apps = notification.data

		case let .configWarning(notification):
			appStatus.latestConfigWarning = notification.summary

		case let .deprecationNotice(notification):
			appStatus.latestDeprecationNotice = notification.summary

		default:
			break
		}
	}

}

		// MARK: ACTIONABLE SERVER REQUESTS

extension CodaxOrchestrator {

	func handle(serverRequest request: ServerRequestEnvelope) {
		let record = PendingServerRequestRecord(envelope: request)
		upsertPendingServerRequest(record)

		guard let threadId = record.threadCodexId else {
			return
		}

		updateThreadListing(threadId: threadId) { listing in
			listing.isPending = true
			listing.isUnread = selectedProjectThread?.listing.codexId != threadId
			listing.summary = record.payload.title
			listing.lastActive = .now
		}
		updateSelectedThreadListing(threadId: threadId) { listing in
			listing.isPending = true
			listing.isUnread = false
			listing.summary = record.payload.title
			listing.lastActive = .now
		}
	}

}

	// MARK: - SUPPORTING Project, Thread, Turn, Item TYPES FOR UI STATE

extension CodaxOrchestrator {

		// MARK: Account

	struct UserAccount {
		var authMode: AuthMode?
		var planType: PlanType?
		var rateLimits: RateLimitSnapshot?
	}

		// MARK: Application

	struct CodaxAppStatus {
		var latestErrorMessage: String?
		var latestConfigWarning: String?
		var latestDeprecationNotice: String?
		var apps: [AppInfo] = []
	}

		// MARK: Project and Threads

	struct CodaxProject {
		let listing: CodaxProjectListing
		var threads: [CodaxProjectThread]

	}

		/// Subset of Project info relevant for listing in the sidebar
	struct CodaxProjectListing {
		let id: UUID
		let path: URL
		var name: String

	}

		/// A Thread belonging to a Project
	struct CodaxProjectThread {
		let listing: CodaxProjectThreadListing
		var loadedChunks: [CodaxProjectThreadChunk]

		var draftContent: String?

		var hasDraft: Bool = false

	}

		/// Subset of Thread info relevant for listing in the sidebar
	struct CodaxProjectThreadListing {
		let codexId: String
		var cwd: URL
		var name: String
		var preview: String
		var summary: String

		var lastActive: Date?

		var isUnread: Bool = false
		var isPending: Bool = false

	}

		/// A paginated chunk of Turns in a Thread suitable for loading in and out as a ThreadView is scrolled
	struct CodaxProjectThreadChunk {
		var turns: [CodaxProjectThreadTurn]

	}

		// MARK: Turns

	struct CodaxProjectThreadTurn {
		let codexId: String
		var status: TurnStatus
		var itemCount: Int
		var errorMessage: String?
	}

		// MARK: Items

	struct CodaxUserItem {

	}

	struct CodaxAgentItem {

	}

}

	// MARK: - HYDRATE: PROJECTS, THREADS, CHUNKS, ITEMS

extension CodaxOrchestrator {

	// MARK: Project Hydration

	func upsertProjectListing(for cwd: String) {
		let url = projectURL(from: cwd)
		let name = projectName(from: cwd)

		if let index = projectListings.firstIndex(where: { $0.path == url }) {
			projectListings[index].name = name
			return
		}

		projectListings.append(
			CodaxProjectListing(
				id: UUID(),
				path: url,
				name: name
			)
		)
	}

	// MARK: Thread Hydration

	func upsertThreadListing(_ listing: CodaxProjectThreadListing) {
		if let index = selectedProjectThreadListings.firstIndex(where: { $0.codexId == listing.codexId }) {
			selectedProjectThreadListings[index] = listing
		} else {
			selectedProjectThreadListings.append(listing)
		}

		selectedProjectThreadListings.sort {
			($0.lastActive ?? .distantPast) > ($1.lastActive ?? .distantPast)
		}
	}

	func upsertThread(_ thread: Thread, markUnread: Bool = false) {
		upsertProjectListing(for: thread.cwd)

		let existingUnread = selectedProjectThreadListings.first(where: { $0.codexId == thread.id })?.isUnread ?? false
		let listing = makeThreadListing(
			from: thread,
			isUnread: existingUnread || markUnread,
			isPending: nil
		)
		upsertThreadListing(listing)

		if selectedProjectThread?.listing.codexId == thread.id {
			selectedProjectThread = CodaxProjectThread(
				listing: listing,
				loadedChunks: sortedThreadChunks(for: thread.id),
				draftContent: selectedProjectThread?.draftContent,
				hasDraft: selectedProjectThread?.hasDraft ?? false
			)
		}
	}

	// MARK: Chunk Hydration

	func upsertTurn(_ turn: Turn, in threadId: String) {
		var threadChunks = selectedProjectThreadChunks[threadId] ?? [:]
		var firstChunk = threadChunks[0] ?? CodaxProjectThreadChunk(turns: [])

		let codaxTurn = makeTurn(from: turn)
		if let index = firstChunk.turns.firstIndex(where: { $0.codexId == turn.id }) {
			firstChunk.turns[index] = codaxTurn
		} else {
			firstChunk.turns.append(codaxTurn)
		}

		threadChunks[0] = firstChunk
		selectedProjectThreadChunks[threadId] = threadChunks

		if let selectedProjectThread, selectedProjectThread.listing.codexId == threadId {
			self.selectedProjectThread = CodaxProjectThread(
				listing: selectedProjectThread.listing,
				loadedChunks: sortedThreadChunks(for: threadId),
				draftContent: selectedProjectThread.draftContent,
				hasDraft: selectedProjectThread.hasDraft
			)
		}
	}

	// MARK: Item Hydration

	func upsertPendingServerRequest(_ record: PendingServerRequestRecord) {
		if let index = pendingServerRequests.firstIndex(where: { $0.requestId == record.requestId }) {
			pendingServerRequests[index] = record
		} else {
			pendingServerRequests.append(record)
		}

		pendingServerRequests.sort { $0.updatedAt > $1.updatedAt }
	}

}

	// MARK: - ACTIONS: PROJECTS, THREADS, CHUNKS, ITEMS

extension CodaxOrchestrator {

	// MARK: Thread Actions

	func updateThreadListing(threadId: String, mutate: (inout CodaxProjectThreadListing) -> Void) {
		guard let index = selectedProjectThreadListings.firstIndex(where: { $0.codexId == threadId }) else {
			return
		}

		mutate(&selectedProjectThreadListings[index])
		selectedProjectThreadListings.sort {
			($0.lastActive ?? .distantPast) > ($1.lastActive ?? .distantPast)
		}
	}

	func updateSelectedThreadListing(threadId: String, mutate: (inout CodaxProjectThreadListing) -> Void) {
		guard let selectedProjectThread, selectedProjectThread.listing.codexId == threadId else {
			return
		}

		var listing = selectedProjectThread.listing
		mutate(&listing)
		self.selectedProjectThread = CodaxProjectThread(
			listing: listing,
			loadedChunks: selectedProjectThread.loadedChunks,
			draftContent: selectedProjectThread.draftContent,
			hasDraft: selectedProjectThread.hasDraft
		)
	}

	func removeThread(threadId: String) {
		selectedProjectThreadListings.removeAll { $0.codexId == threadId }
		selectedProjectThreadChunks.removeValue(forKey: threadId)
		pendingServerRequests.removeAll { $0.threadCodexId == threadId }

		if selectedProjectThread?.listing.codexId == threadId {
			selectedProjectThread = nil
		}
	}

	func restoreSelectedThreadListingIfNeeded(threadId: String) {
		guard let selectedProjectThread, selectedProjectThread.listing.codexId == threadId else {
			return
		}
		upsertThreadListing(selectedProjectThread.listing)
	}

	// MARK: Item Actions

	func removePendingServerRequest(id: RequestId) {
		pendingServerRequests.removeAll { $0.requestId == id }
	}

}

	// MARK: - HELPERS: PROJECTS, THREADS, CHUNKS, ITEMS

extension CodaxOrchestrator {

	// MARK: Project Helpers

	func projectURL(from cwd: String) -> URL {
		URL(fileURLWithPath: cwd, isDirectory: true).standardizedFileURL
	}

	func projectName(from cwd: String) -> String {
		let url = projectURL(from: cwd)
		return url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent
	}

	// MARK: Thread Helpers

	func threadDate(from unixSeconds: Int) -> Date {
		Date(timeIntervalSince1970: TimeInterval(unixSeconds))
	}

	func threadDisplayName(from thread: Thread) -> String {
		if let name = thread.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
			return name
		}

		let preview = thread.preview.trimmingCharacters(in: .whitespacesAndNewlines)
		if !preview.isEmpty {
			return String(preview.prefix(60))
		}

		return "Untitled Thread"
	}

	func threadSummary(from status: ThreadStatus) -> String {
		switch status {
		case .notLoaded:
			return "Not loaded"
		case .idle:
			return "Idle"
		case .systemError:
			return "System error"
		case let .active(activeFlags):
			if activeFlags.contains(.waitingOnApproval) {
				return "Waiting on approval"
			}
			if activeFlags.contains(.waitingOnUserInput) {
				return "Waiting on user input"
			}
			return "Running"
		}
	}

	func isThreadPending(_ status: ThreadStatus) -> Bool {
		switch status {
		case .active:
			return true
		case .notLoaded, .idle, .systemError:
			return false
		}
	}

	func makeThreadListing(from thread: Thread, isUnread: Bool? = nil, isPending: Bool? = nil) -> CodaxProjectThreadListing {
		let threadIsPending = isPending ?? (isThreadPending(thread.status) || hasPendingServerRequest(for: thread.id))
		return CodaxProjectThreadListing(
			codexId: thread.id,
			cwd: projectURL(from: thread.cwd),
			name: threadDisplayName(from: thread),
			preview: thread.preview,
			summary: threadSummary(from: thread.status),
			lastActive: threadDate(from: thread.updatedAt),
			isUnread: isUnread ?? false,
			isPending: threadIsPending
		)
	}

	func sortedThreadChunks(for threadId: String) -> [CodaxProjectThreadChunk] {
		(selectedProjectThreadChunks[threadId] ?? [:])
			.sorted { $0.key < $1.key }
			.map(\.value)
	}

	// MARK: Item Helpers

	func hasPendingServerRequest(for threadId: String) -> Bool {
		pendingServerRequests.contains { $0.threadCodexId == threadId }
	}

	func makeTurn(from turn: Turn) -> CodaxProjectThreadTurn {
		CodaxProjectThreadTurn(
			codexId: turn.id,
			status: turn.status,
			itemCount: turn.items.count,
			errorMessage: turn.error?.message
		)
	}

}
