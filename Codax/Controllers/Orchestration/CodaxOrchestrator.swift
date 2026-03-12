//
//  CodaxOrchestrator.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import Observation

@Observable
final class CodaxOrchestrator {

	let runtime = CodexRuntimeCoordinator()

		// MARK: - OBSERVABLE STATE FOR UI GOES HERE

	var projects: [CodaxProject] = []
	var projectListings: [CodaxProjectListing] = []
	var selectedProject: CodaxProject?
	var selectedProjectThreadListings: [CodaxProjectThreadListing] = []
	var selectedProjectThread: CodaxProjectThread?

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

// MARK: - Supporting Types for UI State

extension CodaxOrchestrator {

	// MARK: Account

	// MARK: Application

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
		var chunks: [CodaxProjectThreadChunk]

	}

		/// Subset of Thread info relevant for listing in the sidebar
	struct CodaxProjectThreadListing {
		let codexId: String
		var cwd: URL
		var name: String

	}

		/// A paginated chunk of Turns in a Thread suitable for loading in and out as a ThreadView is scrolled
	struct CodaxProjectThreadChunk {
		var turns: [CodaxProjectThreadTurn]

	}

	// MARK: Turns

	struct CodaxProjectThreadTurn {

	}

	// MARK: Items

	struct CodaxUserItem {

	}

	struct CodaxAgentItem {

	}

}

// MARK: STARTUP & CODEX INITIALIZATION

extension CodaxOrchestrator {

	func start(arguments: [String] = []) async throws {
		_ = try await runtime.start(arguments: arguments)
		_ = try await initialize(params: makeInitializeParams())
		try await runtime.initialized()
		_ = try await accountRead(params: GetAccountParams(refreshToken: false))
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

}
