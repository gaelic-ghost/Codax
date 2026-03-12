//
//  CodaxOrchestrator.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Observation

@Observable
final class CodaxOrchestrator {

	let runtime = CodexRuntimeCoordinator()

		// MARK: - OBSERVABLE STATE FOR UI GOES HERE

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
