# Connection Schema Progress

Generated on 2026-03-11T21:03:34.985Z.

This tracker is derived from the pinned `codex-schemas/v0.112.0` tree and checked against `Codax/Controllers/Connection/CodexSchema.generated.swift`.

## Summary

- Total exported schema types: 433
- Exported schema types represented in connection Swift: 433
- Exported schema types still missing in connection Swift: 0
- Reachable protocol-surface types: 306
- Non-reachable exported types: 127
- Client request methods: 47 (all done)
- Server notification methods: 44 (all done)
- Server request methods: 8 (all done)
- Reachable types missing generated Swift: 0

## Client Requests

| Method | Swift API | Params | Response | Status |
| --- | --- | --- | --- | --- |
| `initialize` | `initialize` | `InitializeParams` | `InitializeResponse` | done |
| `thread/start` | `threadStart` | `ThreadStartParams` | `ThreadStartResponse` | done |
| `thread/resume` | `threadResume` | `ThreadResumeParams` | `ThreadResumeResponse` | done |
| `thread/fork` | `threadFork` | `ThreadForkParams` | `ThreadForkResponse` | done |
| `thread/archive` | `threadArchive` | `ThreadArchiveParams` | `ThreadArchiveResponse` | done |
| `thread/unsubscribe` | `threadUnsubscribe` | `ThreadUnsubscribeParams` | `ThreadUnsubscribeResponse` | done |
| `thread/name/set` | `threadNameSet` | `ThreadSetNameParams` | `ThreadSetNameResponse` | done |
| `thread/metadata/update` | `threadMetadataUpdate` | `ThreadMetadataUpdateParams` | `ThreadMetadataUpdateResponse` | done |
| `thread/unarchive` | `threadUnarchive` | `ThreadUnarchiveParams` | `ThreadUnarchiveResponse` | done |
| `thread/compact/start` | `threadCompactStart` | `ThreadCompactStartParams` | `ThreadCompactStartResponse` | done |
| `thread/rollback` | `threadRollback` | `ThreadRollbackParams` | `ThreadRollbackResponse` | done |
| `thread/list` | `threadList` | `ThreadListParams` | `ThreadListResponse` | done |
| `thread/loaded/list` | `threadLoadedList` | `ThreadLoadedListParams` | `ThreadLoadedListResponse` | done |
| `thread/read` | `threadRead` | `ThreadReadParams` | `ThreadReadResponse` | done |
| `skills/list` | `skillsList` | `SkillsListParams` | `SkillsListResponse` | done |
| `skills/remote/list` | `skillsRemoteList` | `SkillsRemoteReadParams` | `SkillsRemoteReadResponse` | done |
| `skills/remote/export` | `skillsRemoteExport` | `SkillsRemoteWriteParams` | `SkillsRemoteWriteResponse` | done |
| `app/list` | `appList` | `AppsListParams` | `AppsListResponse` | done |
| `skills/config/write` | `skillsConfigWrite` | `SkillsConfigWriteParams` | `SkillsConfigWriteResponse` | done |
| `plugin/install` | `pluginInstall` | `PluginInstallParams` | `PluginInstallResponse` | done |
| `turn/start` | `turnStart` | `TurnStartParams` | `TurnStartResponse` | done |
| `turn/steer` | `turnSteer` | `TurnSteerParams` | `TurnSteerResponse` | done |
| `turn/interrupt` | `turnInterrupt` | `TurnInterruptParams` | `TurnInterruptResponse` | done |
| `review/start` | `reviewStart` | `ReviewStartParams` | `ReviewStartResponse` | done |
| `model/list` | `modelList` | `ModelListParams` | `ModelListResponse` | done |
| `experimentalFeature/list` | `experimentalFeatureList` | `ExperimentalFeatureListParams` | `ExperimentalFeatureListResponse` | done |
| `mcpServer/oauth/login` | `mcpServerOauthLogin` | `McpServerOauthLoginParams` | `McpServerOauthLoginResponse` | done |
| `config/mcpServer/reload` | `configMcpServerReload` | `undefined` | `McpServerRefreshResponse` | done |
| `mcpServerStatus/list` | `mcpServerStatusList` | `ListMcpServerStatusParams` | `ListMcpServerStatusResponse` | done |
| `windowsSandbox/setupStart` | `windowsSandboxSetupStart` | `WindowsSandboxSetupStartParams` | `WindowsSandboxSetupStartResponse` | done |
| `account/login/start` | `accountLoginStart` | `LoginAccountParams` | `LoginAccountResponse` | done |
| `account/login/cancel` | `accountLoginCancel` | `CancelLoginAccountParams` | `CancelLoginAccountResponse` | done |
| `account/logout` | `accountLogout` | `undefined` | `LogoutAccountResponse` | done |
| `account/rateLimits/read` | `accountRateLimitsRead` | `undefined` | `GetAccountRateLimitsResponse` | done |
| `feedback/upload` | `feedbackUpload` | `FeedbackUploadParams` | `FeedbackUploadResponse` | done |
| `command/exec` | `commandExec` | `CommandExecParams` | `CommandExecResponse` | done |
| `config/read` | `configRead` | `ConfigReadParams` | `ConfigReadResponse` | done |
| `externalAgentConfig/detect` | `externalAgentConfigDetect` | `ExternalAgentConfigDetectParams` | `ExternalAgentConfigDetectResponse` | done |
| `externalAgentConfig/import` | `externalAgentConfigImport` | `ExternalAgentConfigImportParams` | `ExternalAgentConfigImportResponse` | done |
| `config/value/write` | `configValueWrite` | `ConfigValueWriteParams` | `ConfigWriteResponse` | done |
| `config/batchWrite` | `configBatchWrite` | `ConfigBatchWriteParams` | `ConfigWriteResponse` | done |
| `configRequirements/read` | `configRequirementsRead` | `undefined` | `ConfigRequirementsReadResponse` | done |
| `account/read` | `accountRead` | `GetAccountParams` | `GetAccountResponse` | done |
| `getConversationSummary` | `getConversationSummary` | `GetConversationSummaryParams` | `GetConversationSummaryResponse` | done |
| `gitDiffToRemote` | `gitDiffToRemote` | `GitDiffToRemoteParams` | `GitDiffToRemoteResponse` | done |
| `getAuthStatus` | `getAuthStatus` | `GetAuthStatusParams` | `GetAuthStatusResponse` | done |
| `fuzzyFileSearch` | `fuzzyFileSearch` | `FuzzyFileSearchParams` | `FuzzyFileSearchResponse` | done |

## Server Notifications

| Method | Envelope Case | Params | Status |
| --- | --- | --- | --- |
| `error` | `error` | `undefined` | done |
| `thread/started` | `threadStarted` | `undefined` | done |
| `thread/status/changed` | `threadStatusChanged` | `undefined` | done |
| `thread/archived` | `threadArchived` | `undefined` | done |
| `thread/unarchived` | `threadUnarchived` | `undefined` | done |
| `thread/closed` | `threadClosed` | `undefined` | done |
| `skills/changed` | `skillsChanged` | `undefined` | done |
| `thread/name/updated` | `threadNameUpdated` | `undefined` | done |
| `thread/tokenUsage/updated` | `threadTokenUsageUpdated` | `undefined` | done |
| `turn/started` | `turnStarted` | `undefined` | done |
| `turn/completed` | `turnCompleted` | `undefined` | done |
| `turn/diff/updated` | `turnDiffUpdated` | `undefined` | done |
| `turn/plan/updated` | `turnPlanUpdated` | `undefined` | done |
| `item/started` | `itemStarted` | `undefined` | done |
| `item/completed` | `itemCompleted` | `undefined` | done |
| `rawResponseItem/completed` | `rawResponseItemCompleted` | `undefined` | done |
| `item/agentMessage/delta` | `itemAgentMessageDelta` | `undefined` | done |
| `item/plan/delta` | `itemPlanDelta` | `undefined` | done |
| `item/commandExecution/outputDelta` | `itemCommandExecutionOutputDelta` | `undefined` | done |
| `item/commandExecution/terminalInteraction` | `itemCommandExecutionTerminalInteraction` | `undefined` | done |
| `item/fileChange/outputDelta` | `itemFileChangeOutputDelta` | `undefined` | done |
| `serverRequest/resolved` | `serverRequestResolved` | `undefined` | done |
| `item/mcpToolCall/progress` | `itemMcpToolCallProgress` | `undefined` | done |
| `mcpServer/oauthLogin/completed` | `mcpServerOauthLoginCompleted` | `undefined` | done |
| `account/updated` | `accountUpdated` | `undefined` | done |
| `account/rateLimits/updated` | `accountRateLimitsUpdated` | `undefined` | done |
| `app/list/updated` | `appListUpdated` | `undefined` | done |
| `item/reasoning/summaryTextDelta` | `itemReasoningSummaryTextDelta` | `undefined` | done |
| `item/reasoning/summaryPartAdded` | `itemReasoningSummaryPartAdded` | `undefined` | done |
| `item/reasoning/textDelta` | `itemReasoningTextDelta` | `undefined` | done |
| `thread/compacted` | `threadCompacted` | `undefined` | done |
| `model/rerouted` | `modelRerouted` | `undefined` | done |
| `deprecationNotice` | `deprecationNotice` | `undefined` | done |
| `configWarning` | `configWarning` | `undefined` | done |
| `fuzzyFileSearch/sessionUpdated` | `fuzzyFileSearchSessionUpdated` | `undefined` | done |
| `fuzzyFileSearch/sessionCompleted` | `fuzzyFileSearchSessionCompleted` | `undefined` | done |
| `thread/realtime/started` | `threadRealtimeStarted` | `undefined` | done |
| `thread/realtime/itemAdded` | `threadRealtimeItemAdded` | `undefined` | done |
| `thread/realtime/outputAudio/delta` | `threadRealtimeOutputAudioDelta` | `undefined` | done |
| `thread/realtime/error` | `threadRealtimeError` | `undefined` | done |
| `thread/realtime/closed` | `threadRealtimeClosed` | `undefined` | done |
| `windows/worldWritableWarning` | `windowsWorldWritableWarning` | `undefined` | done |
| `windowsSandbox/setupCompleted` | `windowsSandboxSetupCompleted` | `undefined` | done |
| `account/login/completed` | `accountLoginCompleted` | `undefined` | done |

## Server Requests

| Method | Envelope Case | Params | Status |
| --- | --- | --- | --- |
| `item/commandExecution/requestApproval` | `itemCommandExecutionRequestApproval` | `CommandExecutionRequestApprovalParams` | done |
| `item/fileChange/requestApproval` | `itemFileChangeRequestApproval` | `FileChangeRequestApprovalParams` | done |
| `item/tool/requestUserInput` | `itemToolRequestUserInput` | `ToolRequestUserInputParams` | done |
| `mcpServer/elicitation/request` | `mcpServerElicitationRequest` | `McpServerElicitationRequestParams` | done |
| `item/tool/call` | `itemToolCall` | `DynamicToolCallParams` | done |
| `account/chatgptAuthTokens/refresh` | `accountChatgptAuthTokensRefresh` | `ChatgptAuthTokensRefreshParams` | done |
| `applyPatchApproval` | `applyPatchApproval` | `ApplyPatchApprovalParams` | done |
| `execCommandApproval` | `execCommandApproval` | `ExecCommandApprovalParams` | done |

## Reachable Types

| Schema Type | Swift Type | Status | Schema File |
| --- | --- | --- | --- |
| `AbsolutePathBuf` | `AbsolutePathBuf` | `generated:typealias` | `AbsolutePathBuf.ts` |
| `Account` | `Account` | `generated:enum` | `v2/Account.ts` |
| `AccountLoginCompletedNotification` | `AccountLoginCompletedNotification` | `generated:struct` | `v2/AccountLoginCompletedNotification.ts` |
| `AccountRateLimitsUpdatedNotification` | `AccountRateLimitsUpdatedNotification` | `generated:struct` | `v2/AccountRateLimitsUpdatedNotification.ts` |
| `AccountUpdatedNotification` | `AccountUpdatedNotification` | `generated:struct` | `v2/AccountUpdatedNotification.ts` |
| `AdditionalFileSystemPermissions` | `AdditionalFileSystemPermissions` | `generated:struct` | `v2/AdditionalFileSystemPermissions.ts` |
| `AdditionalMacOsPermissions` | `AdditionalMacOsPermissions` | `generated:struct` | `v2/AdditionalMacOsPermissions.ts` |
| `AdditionalNetworkPermissions` | `AdditionalNetworkPermissions` | `generated:struct` | `v2/AdditionalNetworkPermissions.ts` |
| `AdditionalPermissionProfile` | `AdditionalPermissionProfile` | `generated:struct` | `v2/AdditionalPermissionProfile.ts` |
| `AgentMessageDeltaNotification` | `AgentMessageDeltaNotification` | `generated:struct` | `v2/AgentMessageDeltaNotification.ts` |
| `AnalyticsConfig` | `AnalyticsConfig` | `generated:struct` | `v2/AnalyticsConfig.ts` |
| `AppBranding` | `AppBranding` | `generated:struct` | `v2/AppBranding.ts` |
| `AppInfo` | `AppInfo` | `generated:struct` | `v2/AppInfo.ts` |
| `AppListUpdatedNotification` | `AppListUpdatedNotification` | `generated:struct` | `v2/AppListUpdatedNotification.ts` |
| `ApplyPatchApprovalParams` | `ApplyPatchApprovalParams` | `generated:struct` | `ApplyPatchApprovalParams.ts` |
| `ApplyPatchApprovalResponse` | `ApplyPatchApprovalResponse` | `generated:struct` | `ApplyPatchApprovalResponse.ts` |
| `AppMetadata` | `AppMetadata` | `generated:struct` | `v2/AppMetadata.ts` |
| `AppReview` | `AppReview` | `generated:struct` | `v2/AppReview.ts` |
| `AppScreenshot` | `AppScreenshot` | `generated:struct` | `v2/AppScreenshot.ts` |
| `AppsListParams` | `AppsListParams` | `generated:struct` | `v2/AppsListParams.ts` |
| `AppsListResponse` | `AppsListResponse` | `generated:struct` | `v2/AppsListResponse.ts` |
| `AskForApproval` | `AskForApproval` | `generated:enum` | `v2/AskForApproval.ts` |
| `AuthMode` | `AuthMode` | `generated:enum` | `AuthMode.ts` |
| `ByteRange` | `ByteRange` | `generated:struct` | `v2/ByteRange.ts` |
| `CancelLoginAccountParams` | `CancelLoginAccountParams` | `generated:struct` | `v2/CancelLoginAccountParams.ts` |
| `CancelLoginAccountResponse` | `CancelLoginAccountResponse` | `generated:struct` | `v2/CancelLoginAccountResponse.ts` |
| `CancelLoginAccountStatus` | `CancelLoginAccountStatus` | `generated:enum` | `v2/CancelLoginAccountStatus.ts` |
| `ChatgptAuthTokensRefreshParams` | `ChatgptAuthTokensRefreshParams` | `generated:struct` | `v2/ChatgptAuthTokensRefreshParams.ts` |
| `ChatgptAuthTokensRefreshReason` | `ChatgptAuthTokensRefreshReason` | `generated:enum` | `v2/ChatgptAuthTokensRefreshReason.ts` |
| `ChatgptAuthTokensRefreshResponse` | `ChatgptAuthTokensRefreshResponse` | `generated:struct` | `v2/ChatgptAuthTokensRefreshResponse.ts` |
| `ClientInfo` | `ClientInfo` | `generated:struct` | `ClientInfo.ts` |
| `ClientRequest` | `ClientRequest` | `envelope-api` | `ClientRequest.ts` |
| `CodexErrorInfo` | `CodexErrorInfo` | `generated:enum` | `v2/CodexErrorInfo.ts` |
| `CollabAgentState` | `CollabAgentState` | `generated:struct` | `v2/CollabAgentState.ts` |
| `CollabAgentStatus` | `CollabAgentStatus` | `generated:enum` | `v2/CollabAgentStatus.ts` |
| `CollabAgentTool` | `CollabAgentTool` | `generated:enum` | `v2/CollabAgentTool.ts` |
| `CollabAgentToolCallStatus` | `CollabAgentToolCallStatus` | `generated:enum` | `v2/CollabAgentToolCallStatus.ts` |
| `CollaborationMode` | `CollaborationMode` | `generated:struct` | `CollaborationMode.ts` |
| `CommandAction` | `CommandAction` | `generated:enum` | `v2/CommandAction.ts` |
| `CommandExecParams` | `CommandExecParams` | `generated:struct` | `v2/CommandExecParams.ts` |
| `CommandExecResponse` | `CommandExecResponse` | `generated:struct` | `v2/CommandExecResponse.ts` |
| `CommandExecutionApprovalDecision` | `CommandExecutionApprovalDecision` | `generated:enum` | `v2/CommandExecutionApprovalDecision.ts` |
| `CommandExecutionOutputDeltaNotification` | `CommandExecutionOutputDeltaNotification` | `generated:struct` | `v2/CommandExecutionOutputDeltaNotification.ts` |
| `CommandExecutionRequestApprovalParams` | `CommandExecutionRequestApprovalParams` | `generated:struct` | `v2/CommandExecutionRequestApprovalParams.ts` |
| `CommandExecutionRequestApprovalResponse` | `CommandExecutionRequestApprovalResponse` | `generated:struct` | `v2/CommandExecutionRequestApprovalResponse.ts` |
| `CommandExecutionStatus` | `CommandExecutionStatus` | `generated:enum` | `v2/CommandExecutionStatus.ts` |
| `Config` | `Config` | `generated:struct` | `v2/Config.ts` |
| `ConfigBatchWriteParams` | `ConfigBatchWriteParams` | `generated:struct` | `v2/ConfigBatchWriteParams.ts` |
| `ConfigEdit` | `ConfigEdit` | `generated:struct` | `v2/ConfigEdit.ts` |
| `ConfigLayer` | `ConfigLayer` | `generated:struct` | `v2/ConfigLayer.ts` |
| `ConfigLayerMetadata` | `ConfigLayerMetadata` | `generated:struct` | `v2/ConfigLayerMetadata.ts` |
| `ConfigLayerSource` | `ConfigLayerSource` | `generated:enum` | `v2/ConfigLayerSource.ts` |
| `ConfigReadParams` | `ConfigReadParams` | `generated:struct` | `v2/ConfigReadParams.ts` |
| `ConfigReadResponse` | `ConfigReadResponse` | `generated:struct` | `v2/ConfigReadResponse.ts` |
| `ConfigRequirements` | `ConfigRequirements` | `generated:struct` | `v2/ConfigRequirements.ts` |
| `ConfigRequirementsReadResponse` | `ConfigRequirementsReadResponse` | `generated:struct` | `v2/ConfigRequirementsReadResponse.ts` |
| `ConfigValueWriteParams` | `ConfigValueWriteParams` | `generated:struct` | `v2/ConfigValueWriteParams.ts` |
| `ConfigWarningNotification` | `ConfigWarningNotification` | `generated:struct` | `v2/ConfigWarningNotification.ts` |
| `ConfigWriteResponse` | `ConfigWriteResponse` | `generated:struct` | `v2/ConfigWriteResponse.ts` |
| `ContentItem` | `ContentItem` | `generated:enum` | `ContentItem.ts` |
| `ContextCompactedNotification` | `ContextCompactedNotification` | `generated:struct` | `v2/ContextCompactedNotification.ts` |
| `ConversationGitInfo` | `ConversationGitInfo` | `generated:struct` | `ConversationGitInfo.ts` |
| `ConversationSummary` | `ConversationSummary` | `generated:struct` | `ConversationSummary.ts` |
| `CreditsSnapshot` | `CreditsSnapshot` | `generated:struct` | `v2/CreditsSnapshot.ts` |
| `DeprecationNoticeNotification` | `DeprecationNoticeNotification` | `generated:struct` | `v2/DeprecationNoticeNotification.ts` |
| `DynamicToolCallOutputContentItem` | `DynamicToolCallOutputContentItem` | `generated:enum` | `v2/DynamicToolCallOutputContentItem.ts` |
| `DynamicToolCallParams` | `DynamicToolCallParams` | `generated:struct` | `v2/DynamicToolCallParams.ts` |
| `DynamicToolCallResponse` | `DynamicToolCallResponse` | `generated:struct` | `v2/DynamicToolCallResponse.ts` |
| `DynamicToolCallStatus` | `DynamicToolCallStatus` | `generated:enum` | `v2/DynamicToolCallStatus.ts` |
| `ErrorNotification` | `ErrorNotification` | `generated:struct` | `v2/ErrorNotification.ts` |
| `ExecCommandApprovalParams` | `ExecCommandApprovalParams` | `generated:struct` | `ExecCommandApprovalParams.ts` |
| `ExecCommandApprovalResponse` | `ExecCommandApprovalResponse` | `generated:struct` | `ExecCommandApprovalResponse.ts` |
| `ExecPolicyAmendment` | `ExecPolicyAmendment` | `generated:typealias` | `v2/ExecPolicyAmendment.ts` |
| `ExperimentalFeature` | `ExperimentalFeature` | `generated:struct` | `v2/ExperimentalFeature.ts` |
| `ExperimentalFeatureListParams` | `ExperimentalFeatureListParams` | `generated:struct` | `v2/ExperimentalFeatureListParams.ts` |
| `ExperimentalFeatureListResponse` | `ExperimentalFeatureListResponse` | `generated:struct` | `v2/ExperimentalFeatureListResponse.ts` |
| `ExperimentalFeatureStage` | `ExperimentalFeatureStage` | `generated:enum` | `v2/ExperimentalFeatureStage.ts` |
| `ExternalAgentConfigDetectParams` | `ExternalAgentConfigDetectParams` | `generated:struct` | `v2/ExternalAgentConfigDetectParams.ts` |
| `ExternalAgentConfigDetectResponse` | `ExternalAgentConfigDetectResponse` | `generated:struct` | `v2/ExternalAgentConfigDetectResponse.ts` |
| `ExternalAgentConfigImportParams` | `ExternalAgentConfigImportParams` | `generated:struct` | `v2/ExternalAgentConfigImportParams.ts` |
| `ExternalAgentConfigImportResponse` | `ExternalAgentConfigImportResponse` | `generated:struct` | `v2/ExternalAgentConfigImportResponse.ts` |
| `ExternalAgentConfigMigrationItem` | `ExternalAgentConfigMigrationItem` | `generated:struct` | `v2/ExternalAgentConfigMigrationItem.ts` |
| `ExternalAgentConfigMigrationItemType` | `ExternalAgentConfigMigrationItemType` | `generated:enum` | `v2/ExternalAgentConfigMigrationItemType.ts` |
| `FeedbackUploadParams` | `FeedbackUploadParams` | `generated:struct` | `v2/FeedbackUploadParams.ts` |
| `FeedbackUploadResponse` | `FeedbackUploadResponse` | `generated:struct` | `v2/FeedbackUploadResponse.ts` |
| `FileChange` | `FileChange` | `generated:enum` | `FileChange.ts` |
| `FileChangeApprovalDecision` | `FileChangeApprovalDecision` | `generated:enum` | `v2/FileChangeApprovalDecision.ts` |
| `FileChangeOutputDeltaNotification` | `FileChangeOutputDeltaNotification` | `generated:struct` | `v2/FileChangeOutputDeltaNotification.ts` |
| `FileChangeRequestApprovalParams` | `FileChangeRequestApprovalParams` | `generated:struct` | `v2/FileChangeRequestApprovalParams.ts` |
| `FileChangeRequestApprovalResponse` | `FileChangeRequestApprovalResponse` | `generated:struct` | `v2/FileChangeRequestApprovalResponse.ts` |
| `FileUpdateChange` | `FileUpdateChange` | `generated:struct` | `v2/FileUpdateChange.ts` |
| `ForcedLoginMethod` | `ForcedLoginMethod` | `generated:enum` | `ForcedLoginMethod.ts` |
| `FunctionCallOutputBody` | `FunctionCallOutputBody` | `generated:enum` | `FunctionCallOutputBody.ts` |
| `FunctionCallOutputContentItem` | `FunctionCallOutputContentItem` | `generated:enum` | `FunctionCallOutputContentItem.ts` |
| `FunctionCallOutputPayload` | `FunctionCallOutputPayload` | `generated:struct` | `FunctionCallOutputPayload.ts` |
| `FuzzyFileSearchParams` | `FuzzyFileSearchParams` | `generated:struct` | `FuzzyFileSearchParams.ts` |
| `FuzzyFileSearchResponse` | `FuzzyFileSearchResponse` | `generated:struct` | `FuzzyFileSearchResponse.ts` |
| `FuzzyFileSearchResult` | `FuzzyFileSearchResult` | `generated:struct` | `FuzzyFileSearchResult.ts` |
| `FuzzyFileSearchSessionCompletedNotification` | `FuzzyFileSearchSessionCompletedNotification` | `generated:struct` | `FuzzyFileSearchSessionCompletedNotification.ts` |
| `FuzzyFileSearchSessionUpdatedNotification` | `FuzzyFileSearchSessionUpdatedNotification` | `generated:struct` | `FuzzyFileSearchSessionUpdatedNotification.ts` |
| `GetAccountParams` | `GetAccountParams` | `generated:struct` | `v2/GetAccountParams.ts` |
| `GetAccountRateLimitsResponse` | `GetAccountRateLimitsResponse` | `generated:struct` | `v2/GetAccountRateLimitsResponse.ts` |
| `GetAccountResponse` | `GetAccountResponse` | `generated:struct` | `v2/GetAccountResponse.ts` |
| `GetAuthStatusParams` | `GetAuthStatusParams` | `generated:struct` | `GetAuthStatusParams.ts` |
| `GetAuthStatusResponse` | `GetAuthStatusResponse` | `generated:struct` | `GetAuthStatusResponse.ts` |
| `GetConversationSummaryParams` | `GetConversationSummaryParams` | `generated:enum` | `GetConversationSummaryParams.ts` |
| `GetConversationSummaryResponse` | `GetConversationSummaryResponse` | `generated:struct` | `GetConversationSummaryResponse.ts` |
| `GhostCommit` | `GhostCommit` | `generated:struct` | `GhostCommit.ts` |
| `GitDiffToRemoteParams` | `GitDiffToRemoteParams` | `generated:struct` | `GitDiffToRemoteParams.ts` |
| `GitDiffToRemoteResponse` | `GitDiffToRemoteResponse` | `generated:struct` | `GitDiffToRemoteResponse.ts` |
| `GitInfo` | `GitInfo` | `generated:struct` | `v2/GitInfo.ts` |
| `GitSha` | `GitSha` | `generated:typealias` | `GitSha.ts` |
| `HazelnutScope` | `HazelnutScope` | `generated:enum` | `v2/HazelnutScope.ts` |
| `ImageDetail` | `ImageDetail` | `generated:enum` | `ImageDetail.ts` |
| `InitializeCapabilities` | `InitializeCapabilities` | `generated:struct` | `InitializeCapabilities.ts` |
| `InitializeParams` | `InitializeParams` | `generated:struct` | `InitializeParams.ts` |
| `InitializeResponse` | `InitializeResponse` | `generated:struct` | `InitializeResponse.ts` |
| `InputModality` | `InputModality` | `generated:enum` | `InputModality.ts` |
| `ItemCompletedNotification` | `ItemCompletedNotification` | `generated:struct` | `v2/ItemCompletedNotification.ts` |
| `ItemStartedNotification` | `ItemStartedNotification` | `generated:struct` | `v2/ItemStartedNotification.ts` |
| `JsonValue` | `JSONValue` | `generated:indirect enum(rename:JSONValue)` | `serde_json/JsonValue.ts` |
| `ListMcpServerStatusParams` | `ListMcpServerStatusParams` | `generated:struct` | `v2/ListMcpServerStatusParams.ts` |
| `ListMcpServerStatusResponse` | `ListMcpServerStatusResponse` | `generated:struct` | `v2/ListMcpServerStatusResponse.ts` |
| `LocalShellAction` | `LocalShellAction` | `generated:struct` | `LocalShellAction.ts` |
| `LocalShellExecAction` | `LocalShellExecAction` | `generated:struct` | `LocalShellExecAction.ts` |
| `LocalShellStatus` | `LocalShellStatus` | `generated:enum` | `LocalShellStatus.ts` |
| `LoginAccountParams` | `LoginAccountParams` | `generated:enum` | `v2/LoginAccountParams.ts` |
| `LoginAccountResponse` | `LoginAccountResponse` | `generated:enum` | `v2/LoginAccountResponse.ts` |
| `LogoutAccountResponse` | `LogoutAccountResponse` | `generated:struct` | `v2/LogoutAccountResponse.ts` |
| `MacOsAutomationPermission` | `MacOsAutomationPermission` | `generated:enum` | `MacOsAutomationPermission.ts` |
| `MacOsPreferencesPermission` | `MacOsPreferencesPermission` | `generated:enum` | `MacOsPreferencesPermission.ts` |
| `McpAuthStatus` | `McpAuthStatus` | `generated:enum` | `v2/McpAuthStatus.ts` |
| `McpServerElicitationAction` | `McpServerElicitationAction` | `generated:enum` | `v2/McpServerElicitationAction.ts` |
| `McpServerElicitationRequestParams` | `McpServerElicitationRequestParams` | `generated:enum` | `v2/McpServerElicitationRequestParams.ts` |
| `McpServerElicitationRequestResponse` | `McpServerElicitationRequestResponse` | `generated:struct` | `v2/McpServerElicitationRequestResponse.ts` |
| `McpServerOauthLoginCompletedNotification` | `McpServerOauthLoginCompletedNotification` | `generated:struct` | `v2/McpServerOauthLoginCompletedNotification.ts` |
| `McpServerOauthLoginParams` | `McpServerOauthLoginParams` | `generated:struct` | `v2/McpServerOauthLoginParams.ts` |
| `McpServerOauthLoginResponse` | `McpServerOauthLoginResponse` | `generated:struct` | `v2/McpServerOauthLoginResponse.ts` |
| `McpServerRefreshResponse` | `McpServerRefreshResponse` | `generated:struct` | `v2/McpServerRefreshResponse.ts` |
| `McpServerStatus` | `McpServerStatus` | `generated:struct` | `v2/McpServerStatus.ts` |
| `McpToolCallError` | `McpToolCallError` | `generated:struct` | `v2/McpToolCallError.ts` |
| `McpToolCallProgressNotification` | `McpToolCallProgressNotification` | `generated:struct` | `v2/McpToolCallProgressNotification.ts` |
| `McpToolCallResult` | `McpToolCallResult` | `generated:struct` | `v2/McpToolCallResult.ts` |
| `McpToolCallStatus` | `McpToolCallStatus` | `generated:enum` | `v2/McpToolCallStatus.ts` |
| `MergeStrategy` | `MergeStrategy` | `generated:enum` | `v2/MergeStrategy.ts` |
| `MessagePhase` | `MessagePhase` | `generated:enum` | `MessagePhase.ts` |
| `ModeKind` | `ModeKind` | `generated:enum` | `ModeKind.ts` |
| `Model` | `AppModel` | `generated:struct` | `v2/Model.ts` |
| `ModelAvailabilityNux` | `ModelAvailabilityNux` | `generated:struct` | `v2/ModelAvailabilityNux.ts` |
| `ModelListParams` | `ModelListParams` | `generated:struct` | `v2/ModelListParams.ts` |
| `ModelListResponse` | `ModelListResponse` | `generated:struct` | `v2/ModelListResponse.ts` |
| `ModelReroutedNotification` | `ModelReroutedNotification` | `generated:struct` | `v2/ModelReroutedNotification.ts` |
| `ModelRerouteReason` | `ModelRerouteReason` | `generated:enum` | `v2/ModelRerouteReason.ts` |
| `ModelUpgradeInfo` | `ModelUpgradeInfo` | `generated:struct` | `v2/ModelUpgradeInfo.ts` |
| `NetworkAccess` | `NetworkAccess` | `generated:enum` | `v2/NetworkAccess.ts` |
| `NetworkApprovalContext` | `NetworkApprovalContext` | `generated:struct` | `v2/NetworkApprovalContext.ts` |
| `NetworkApprovalProtocol` | `NetworkApprovalProtocol` | `generated:enum` | `v2/NetworkApprovalProtocol.ts` |
| `NetworkPolicyAmendment` | `NetworkPolicyAmendment` | `generated:struct` | `v2/NetworkPolicyAmendment.ts` |
| `NetworkPolicyRuleAction` | `NetworkPolicyRuleAction` | `generated:enum` | `v2/NetworkPolicyRuleAction.ts` |
| `OverriddenMetadata` | `OverriddenMetadata` | `generated:struct` | `v2/OverriddenMetadata.ts` |
| `ParsedCommand` | `ParsedCommand` | `generated:enum` | `ParsedCommand.ts` |
| `PatchApplyStatus` | `PatchApplyStatus` | `generated:enum` | `v2/PatchApplyStatus.ts` |
| `PatchChangeKind` | `PatchChangeKind` | `generated:enum` | `v2/PatchChangeKind.ts` |
| `Personality` | `Personality` | `generated:enum` | `Personality.ts` |
| `PlanDeltaNotification` | `PlanDeltaNotification` | `generated:struct` | `v2/PlanDeltaNotification.ts` |
| `PlanType` | `PlanType` | `generated:enum` | `PlanType.ts` |
| `PluginInstallParams` | `PluginInstallParams` | `generated:struct` | `v2/PluginInstallParams.ts` |
| `PluginInstallResponse` | `PluginInstallResponse` | `generated:struct` | `v2/PluginInstallResponse.ts` |
| `ProductSurface` | `ProductSurface` | `generated:enum` | `v2/ProductSurface.ts` |
| `ProfileV2` | `ProfileV2` | `generated:struct` | `v2/ProfileV2.ts` |
| `RateLimitSnapshot` | `RateLimitSnapshot` | `generated:struct` | `v2/RateLimitSnapshot.ts` |
| `RateLimitWindow` | `RateLimitWindow` | `generated:struct` | `v2/RateLimitWindow.ts` |
| `RawResponseItemCompletedNotification` | `RawResponseItemCompletedNotification` | `generated:struct` | `v2/RawResponseItemCompletedNotification.ts` |
| `ReadOnlyAccess` | `ReadOnlyAccess` | `generated:enum` | `v2/ReadOnlyAccess.ts` |
| `ReasoningEffort` | `ReasoningEffort` | `generated:enum` | `ReasoningEffort.ts` |
| `ReasoningEffortOption` | `ReasoningEffortOption` | `generated:struct` | `v2/ReasoningEffortOption.ts` |
| `ReasoningItemContent` | `ReasoningItemContent` | `generated:enum` | `ReasoningItemContent.ts` |
| `ReasoningItemReasoningSummary` | `ReasoningItemReasoningSummary` | `generated:struct` | `ReasoningItemReasoningSummary.ts` |
| `ReasoningSummary` | `ReasoningSummary` | `generated:enum` | `ReasoningSummary.ts` |
| `ReasoningSummaryPartAddedNotification` | `ReasoningSummaryPartAddedNotification` | `generated:struct` | `v2/ReasoningSummaryPartAddedNotification.ts` |
| `ReasoningSummaryTextDeltaNotification` | `ReasoningSummaryTextDeltaNotification` | `generated:struct` | `v2/ReasoningSummaryTextDeltaNotification.ts` |
| `ReasoningTextDeltaNotification` | `ReasoningTextDeltaNotification` | `generated:struct` | `v2/ReasoningTextDeltaNotification.ts` |
| `RemoteSkillSummary` | `RemoteSkillSummary` | `generated:struct` | `v2/RemoteSkillSummary.ts` |
| `RequestId` | `RequestId` | `generated:enum(rename:JSONRPCID)` | `RequestId.ts` |
| `ResidencyRequirement` | `ResidencyRequirement` | `generated:enum` | `v2/ResidencyRequirement.ts` |
| `Resource` | `Resource` | `generated:struct` | `Resource.ts` |
| `ResourceTemplate` | `ResourceTemplate` | `generated:struct` | `ResourceTemplate.ts` |
| `ResponseItem` | `ResponseItem` | `generated:enum` | `ResponseItem.ts` |
| `ReviewDecision` | `ReviewDecision` | `generated:enum` | `ReviewDecision.ts` |
| `ReviewDelivery` | `ReviewDelivery` | `generated:enum` | `v2/ReviewDelivery.ts` |
| `ReviewStartParams` | `ReviewStartParams` | `generated:struct` | `v2/ReviewStartParams.ts` |
| `ReviewStartResponse` | `ReviewStartResponse` | `generated:struct` | `v2/ReviewStartResponse.ts` |
| `ReviewTarget` | `ReviewTarget` | `generated:enum` | `v2/ReviewTarget.ts` |
| `SandboxMode` | `SandboxMode` | `generated:enum` | `v2/SandboxMode.ts` |
| `SandboxPolicy` | `SandboxPolicy` | `generated:enum` | `v2/SandboxPolicy.ts` |
| `SandboxWorkspaceWrite` | `SandboxWorkspaceWrite` | `generated:struct` | `v2/SandboxWorkspaceWrite.ts` |
| `ServerNotification` | `ServerNotification` | `envelope` | `ServerNotification.ts` |
| `ServerRequest` | `ServerRequest` | `envelope` | `ServerRequest.ts` |
| `ServerRequestResolvedNotification` | `ServerRequestResolvedNotification` | `generated:struct` | `v2/ServerRequestResolvedNotification.ts` |
| `ServiceTier` | `ServiceTier` | `generated:enum` | `ServiceTier.ts` |
| `SessionSource` | `SessionSource` | `generated:enum` | `v2/SessionSource.ts` |
| `Settings` | `Settings` | `generated:struct` | `Settings.ts` |
| `SkillDependencies` | `SkillDependencies` | `generated:struct` | `v2/SkillDependencies.ts` |
| `SkillErrorInfo` | `SkillErrorInfo` | `generated:struct` | `v2/SkillErrorInfo.ts` |
| `SkillInterface` | `SkillInterface` | `generated:struct` | `v2/SkillInterface.ts` |
| `SkillMetadata` | `SkillMetadata` | `generated:struct` | `v2/SkillMetadata.ts` |
| `SkillsChangedNotification` | `SkillsChangedNotification` | `generated:struct` | `v2/SkillsChangedNotification.ts` |
| `SkillsConfigWriteParams` | `SkillsConfigWriteParams` | `generated:struct` | `v2/SkillsConfigWriteParams.ts` |
| `SkillsConfigWriteResponse` | `SkillsConfigWriteResponse` | `generated:struct` | `v2/SkillsConfigWriteResponse.ts` |
| `SkillScope` | `SkillScope` | `generated:enum` | `v2/SkillScope.ts` |
| `SkillsListEntry` | `SkillsListEntry` | `generated:struct` | `v2/SkillsListEntry.ts` |
| `SkillsListExtraRootsForCwd` | `SkillsListExtraRootsForCwd` | `generated:struct` | `v2/SkillsListExtraRootsForCwd.ts` |
| `SkillsListParams` | `SkillsListParams` | `generated:struct` | `v2/SkillsListParams.ts` |
| `SkillsListResponse` | `SkillsListResponse` | `generated:struct` | `v2/SkillsListResponse.ts` |
| `SkillsRemoteReadParams` | `SkillsRemoteReadParams` | `generated:struct` | `v2/SkillsRemoteReadParams.ts` |
| `SkillsRemoteReadResponse` | `SkillsRemoteReadResponse` | `generated:struct` | `v2/SkillsRemoteReadResponse.ts` |
| `SkillsRemoteWriteParams` | `SkillsRemoteWriteParams` | `generated:struct` | `v2/SkillsRemoteWriteParams.ts` |
| `SkillsRemoteWriteResponse` | `SkillsRemoteWriteResponse` | `generated:struct` | `v2/SkillsRemoteWriteResponse.ts` |
| `SkillToolDependency` | `SkillToolDependency` | `generated:struct` | `v2/SkillToolDependency.ts` |
| `SubAgentSource` | `SubAgentSource` | `generated:enum` | `SubAgentSource.ts` |
| `TerminalInteractionNotification` | `TerminalInteractionNotification` | `generated:struct` | `v2/TerminalInteractionNotification.ts` |
| `TextElement` | `TextElement` | `generated:struct` | `v2/TextElement.ts` |
| `TextPosition` | `TextPosition` | `generated:struct` | `v2/TextPosition.ts` |
| `TextRange` | `TextRange` | `generated:struct` | `v2/TextRange.ts` |
| `Thread` | `Thread` | `generated:struct` | `v2/Thread.ts` |
| `ThreadActiveFlag` | `ThreadActiveFlag` | `generated:enum` | `v2/ThreadActiveFlag.ts` |
| `ThreadArchivedNotification` | `ThreadArchivedNotification` | `generated:struct` | `v2/ThreadArchivedNotification.ts` |
| `ThreadArchiveParams` | `ThreadArchiveParams` | `generated:struct` | `v2/ThreadArchiveParams.ts` |
| `ThreadArchiveResponse` | `ThreadArchiveResponse` | `generated:struct` | `v2/ThreadArchiveResponse.ts` |
| `ThreadClosedNotification` | `ThreadClosedNotification` | `generated:struct` | `v2/ThreadClosedNotification.ts` |
| `ThreadCompactStartParams` | `ThreadCompactStartParams` | `generated:struct` | `v2/ThreadCompactStartParams.ts` |
| `ThreadCompactStartResponse` | `ThreadCompactStartResponse` | `generated:struct` | `v2/ThreadCompactStartResponse.ts` |
| `ThreadForkParams` | `ThreadForkParams` | `generated:struct` | `v2/ThreadForkParams.ts` |
| `ThreadForkResponse` | `ThreadForkResponse` | `generated:struct` | `v2/ThreadForkResponse.ts` |
| `ThreadId` | `ThreadId` | `generated:typealias` | `ThreadId.ts` |
| `ThreadItem` | `ThreadItem` | `generated:enum` | `v2/ThreadItem.ts` |
| `ThreadListParams` | `ThreadListParams` | `generated:struct` | `v2/ThreadListParams.ts` |
| `ThreadListResponse` | `ThreadListResponse` | `generated:struct` | `v2/ThreadListResponse.ts` |
| `ThreadLoadedListParams` | `ThreadLoadedListParams` | `generated:struct` | `v2/ThreadLoadedListParams.ts` |
| `ThreadLoadedListResponse` | `ThreadLoadedListResponse` | `generated:struct` | `v2/ThreadLoadedListResponse.ts` |
| `ThreadMetadataGitInfoUpdateParams` | `ThreadMetadataGitInfoUpdateParams` | `generated:struct` | `v2/ThreadMetadataGitInfoUpdateParams.ts` |
| `ThreadMetadataUpdateParams` | `ThreadMetadataUpdateParams` | `generated:struct` | `v2/ThreadMetadataUpdateParams.ts` |
| `ThreadMetadataUpdateResponse` | `ThreadMetadataUpdateResponse` | `generated:struct` | `v2/ThreadMetadataUpdateResponse.ts` |
| `ThreadNameUpdatedNotification` | `ThreadNameUpdatedNotification` | `generated:struct` | `v2/ThreadNameUpdatedNotification.ts` |
| `ThreadReadParams` | `ThreadReadParams` | `generated:struct` | `v2/ThreadReadParams.ts` |
| `ThreadReadResponse` | `ThreadReadResponse` | `generated:struct` | `v2/ThreadReadResponse.ts` |
| `ThreadRealtimeAudioChunk` | `ThreadRealtimeAudioChunk` | `generated:struct` | `v2/ThreadRealtimeAudioChunk.ts` |
| `ThreadRealtimeClosedNotification` | `ThreadRealtimeClosedNotification` | `generated:struct` | `v2/ThreadRealtimeClosedNotification.ts` |
| `ThreadRealtimeErrorNotification` | `ThreadRealtimeErrorNotification` | `generated:struct` | `v2/ThreadRealtimeErrorNotification.ts` |
| `ThreadRealtimeItemAddedNotification` | `ThreadRealtimeItemAddedNotification` | `generated:struct` | `v2/ThreadRealtimeItemAddedNotification.ts` |
| `ThreadRealtimeOutputAudioDeltaNotification` | `ThreadRealtimeOutputAudioDeltaNotification` | `generated:struct` | `v2/ThreadRealtimeOutputAudioDeltaNotification.ts` |
| `ThreadRealtimeStartedNotification` | `ThreadRealtimeStartedNotification` | `generated:struct` | `v2/ThreadRealtimeStartedNotification.ts` |
| `ThreadResumeParams` | `ThreadResumeParams` | `generated:struct` | `v2/ThreadResumeParams.ts` |
| `ThreadResumeResponse` | `ThreadResumeResponse` | `generated:struct` | `v2/ThreadResumeResponse.ts` |
| `ThreadRollbackParams` | `ThreadRollbackParams` | `generated:struct` | `v2/ThreadRollbackParams.ts` |
| `ThreadRollbackResponse` | `ThreadRollbackResponse` | `generated:struct` | `v2/ThreadRollbackResponse.ts` |
| `ThreadSetNameParams` | `ThreadSetNameParams` | `generated:struct` | `v2/ThreadSetNameParams.ts` |
| `ThreadSetNameResponse` | `ThreadSetNameResponse` | `generated:struct` | `v2/ThreadSetNameResponse.ts` |
| `ThreadSortKey` | `ThreadSortKey` | `generated:enum` | `v2/ThreadSortKey.ts` |
| `ThreadSourceKind` | `ThreadSourceKind` | `generated:enum` | `v2/ThreadSourceKind.ts` |
| `ThreadStartedNotification` | `ThreadStartedNotification` | `generated:struct` | `v2/ThreadStartedNotification.ts` |
| `ThreadStartParams` | `ThreadStartParams` | `generated:struct` | `v2/ThreadStartParams.ts` |
| `ThreadStartResponse` | `ThreadStartResponse` | `generated:struct` | `v2/ThreadStartResponse.ts` |
| `ThreadStatus` | `ThreadStatus` | `generated:enum` | `v2/ThreadStatus.ts` |
| `ThreadStatusChangedNotification` | `ThreadStatusChangedNotification` | `generated:struct` | `v2/ThreadStatusChangedNotification.ts` |
| `ThreadTokenUsage` | `ThreadTokenUsage` | `generated:struct` | `v2/ThreadTokenUsage.ts` |
| `ThreadTokenUsageUpdatedNotification` | `ThreadTokenUsageUpdatedNotification` | `generated:struct` | `v2/ThreadTokenUsageUpdatedNotification.ts` |
| `ThreadUnarchivedNotification` | `ThreadUnarchivedNotification` | `generated:struct` | `v2/ThreadUnarchivedNotification.ts` |
| `ThreadUnarchiveParams` | `ThreadUnarchiveParams` | `generated:struct` | `v2/ThreadUnarchiveParams.ts` |
| `ThreadUnarchiveResponse` | `ThreadUnarchiveResponse` | `generated:struct` | `v2/ThreadUnarchiveResponse.ts` |
| `ThreadUnsubscribeParams` | `ThreadUnsubscribeParams` | `generated:struct` | `v2/ThreadUnsubscribeParams.ts` |
| `ThreadUnsubscribeResponse` | `ThreadUnsubscribeResponse` | `generated:struct` | `v2/ThreadUnsubscribeResponse.ts` |
| `ThreadUnsubscribeStatus` | `ThreadUnsubscribeStatus` | `generated:enum` | `v2/ThreadUnsubscribeStatus.ts` |
| `TokenUsageBreakdown` | `TokenUsageBreakdown` | `generated:struct` | `v2/TokenUsageBreakdown.ts` |
| `Tool` | `Tool` | `generated:struct` | `Tool.ts` |
| `ToolRequestUserInputAnswer` | `ToolRequestUserInputAnswer` | `generated:struct` | `v2/ToolRequestUserInputAnswer.ts` |
| `ToolRequestUserInputOption` | `ToolRequestUserInputOption` | `generated:struct` | `v2/ToolRequestUserInputOption.ts` |
| `ToolRequestUserInputParams` | `ToolRequestUserInputParams` | `generated:struct` | `v2/ToolRequestUserInputParams.ts` |
| `ToolRequestUserInputQuestion` | `ToolRequestUserInputQuestion` | `generated:struct` | `v2/ToolRequestUserInputQuestion.ts` |
| `ToolRequestUserInputResponse` | `ToolRequestUserInputResponse` | `generated:struct` | `v2/ToolRequestUserInputResponse.ts` |
| `ToolsV2` | `ToolsV2` | `generated:struct` | `v2/ToolsV2.ts` |
| `Turn` | `Turn` | `generated:struct` | `v2/Turn.ts` |
| `TurnCompletedNotification` | `TurnCompletedNotification` | `generated:struct` | `v2/TurnCompletedNotification.ts` |
| `TurnDiffUpdatedNotification` | `TurnDiffUpdatedNotification` | `generated:struct` | `v2/TurnDiffUpdatedNotification.ts` |
| `TurnError` | `TurnError` | `generated:struct` | `v2/TurnError.ts` |
| `TurnInterruptParams` | `TurnInterruptParams` | `generated:struct` | `v2/TurnInterruptParams.ts` |
| `TurnInterruptResponse` | `TurnInterruptResponse` | `generated:struct` | `v2/TurnInterruptResponse.ts` |
| `TurnPlanStep` | `TurnPlanStep` | `generated:struct` | `v2/TurnPlanStep.ts` |
| `TurnPlanStepStatus` | `TurnPlanStepStatus` | `generated:enum` | `v2/TurnPlanStepStatus.ts` |
| `TurnPlanUpdatedNotification` | `TurnPlanUpdatedNotification` | `generated:struct` | `v2/TurnPlanUpdatedNotification.ts` |
| `TurnStartedNotification` | `TurnStartedNotification` | `generated:struct` | `v2/TurnStartedNotification.ts` |
| `TurnStartParams` | `TurnStartParams` | `generated:struct` | `v2/TurnStartParams.ts` |
| `TurnStartResponse` | `TurnStartResponse` | `generated:struct` | `v2/TurnStartResponse.ts` |
| `TurnStatus` | `TurnStatus` | `generated:enum` | `v2/TurnStatus.ts` |
| `TurnSteerParams` | `TurnSteerParams` | `generated:struct` | `v2/TurnSteerParams.ts` |
| `TurnSteerResponse` | `TurnSteerResponse` | `generated:struct` | `v2/TurnSteerResponse.ts` |
| `UserInput` | `UserInput` | `generated:enum` | `v2/UserInput.ts` |
| `Verbosity` | `Verbosity` | `generated:enum` | `Verbosity.ts` |
| `WebSearchAction` | `WebSearchAction` | `generated:enum` | `v2/WebSearchAction.ts` |
| `WebSearchMode` | `WebSearchMode` | `generated:enum` | `WebSearchMode.ts` |
| `WindowsSandboxSetupCompletedNotification` | `WindowsSandboxSetupCompletedNotification` | `generated:struct` | `v2/WindowsSandboxSetupCompletedNotification.ts` |
| `WindowsSandboxSetupMode` | `WindowsSandboxSetupMode` | `generated:enum` | `v2/WindowsSandboxSetupMode.ts` |
| `WindowsSandboxSetupStartParams` | `WindowsSandboxSetupStartParams` | `generated:struct` | `v2/WindowsSandboxSetupStartParams.ts` |
| `WindowsSandboxSetupStartResponse` | `WindowsSandboxSetupStartResponse` | `generated:struct` | `v2/WindowsSandboxSetupStartResponse.ts` |
| `WindowsWorldWritableWarningNotification` | `WindowsWorldWritableWarningNotification` | `generated:struct` | `v2/WindowsWorldWritableWarningNotification.ts` |
| `WriteStatus` | `WriteStatus` | `generated:enum` | `v2/WriteStatus.ts` |

## Missing Reachable Types

- none

## Missing Exported Types

- none

## Non-Reachable Exported Types

| Schema Type | Swift Type | Status | Schema File |
| --- | --- | --- | --- |
| `AgentMessageContent` | `AgentMessageContent` | `generated:struct` | `AgentMessageContent.ts` |
| `AgentMessageContentDeltaEvent` | `AgentMessageContentDeltaEvent` | `generated:struct` | `AgentMessageContentDeltaEvent.ts` |
| `AgentMessageDeltaEvent` | `AgentMessageDeltaEvent` | `generated:struct` | `AgentMessageDeltaEvent.ts` |
| `AgentMessageEvent` | `AgentMessageEvent` | `generated:struct` | `AgentMessageEvent.ts` |
| `AgentMessageItem` | `AgentMessageItem` | `generated:struct` | `AgentMessageItem.ts` |
| `AgentReasoningDeltaEvent` | `AgentReasoningDeltaEvent` | `generated:struct` | `AgentReasoningDeltaEvent.ts` |
| `AgentReasoningEvent` | `AgentReasoningEvent` | `generated:struct` | `AgentReasoningEvent.ts` |
| `AgentReasoningRawContentDeltaEvent` | `AgentReasoningRawContentDeltaEvent` | `generated:struct` | `AgentReasoningRawContentDeltaEvent.ts` |
| `AgentReasoningRawContentEvent` | `AgentReasoningRawContentEvent` | `generated:struct` | `AgentReasoningRawContentEvent.ts` |
| `AgentReasoningSectionBreakEvent` | `AgentReasoningSectionBreakEvent` | `generated:struct` | `AgentReasoningSectionBreakEvent.ts` |
| `AgentStatus` | `AgentStatus` | `generated:enum` | `AgentStatus.ts` |
| `ApplyPatchApprovalRequestEvent` | `ApplyPatchApprovalRequestEvent` | `generated:struct` | `ApplyPatchApprovalRequestEvent.ts` |
| `AppsConfig` | `AppsConfig` | `generated:struct` | `v2/AppsConfig.ts` |
| `AppsDefaultConfig` | `AppsDefaultConfig` | `generated:struct` | `v2/AppsDefaultConfig.ts` |
| `AppToolApproval` | `AppToolApproval` | `generated:enum` | `v2/AppToolApproval.ts` |
| `AppToolsConfig` | `AppToolsConfig` | `generated:typealias` | `v2/AppToolsConfig.ts` |
| `BackgroundEventEvent` | `BackgroundEventEvent` | `generated:struct` | `BackgroundEventEvent.ts` |
| `CallToolResult` | `CallToolResult` | `generated:struct` | `CallToolResult.ts` |
| `ClientNotification` | `ClientNotification` | `generated:struct` | `ClientNotification.ts` |
| `CollabAgentInteractionBeginEvent` | `CollabAgentInteractionBeginEvent` | `generated:struct` | `CollabAgentInteractionBeginEvent.ts` |
| `CollabAgentInteractionEndEvent` | `CollabAgentInteractionEndEvent` | `generated:struct` | `CollabAgentInteractionEndEvent.ts` |
| `CollabAgentRef` | `CollabAgentRef` | `generated:struct` | `CollabAgentRef.ts` |
| `CollabAgentSpawnBeginEvent` | `CollabAgentSpawnBeginEvent` | `generated:struct` | `CollabAgentSpawnBeginEvent.ts` |
| `CollabAgentSpawnEndEvent` | `CollabAgentSpawnEndEvent` | `generated:struct` | `CollabAgentSpawnEndEvent.ts` |
| `CollabAgentStatusEntry` | `CollabAgentStatusEntry` | `generated:struct` | `CollabAgentStatusEntry.ts` |
| `CollabCloseBeginEvent` | `CollabCloseBeginEvent` | `generated:struct` | `CollabCloseBeginEvent.ts` |
| `CollabCloseEndEvent` | `CollabCloseEndEvent` | `generated:struct` | `CollabCloseEndEvent.ts` |
| `CollaborationModeMask` | `CollaborationModeMask` | `generated:struct` | `v2/CollaborationModeMask.ts` |
| `CollabResumeBeginEvent` | `CollabResumeBeginEvent` | `generated:struct` | `CollabResumeBeginEvent.ts` |
| `CollabResumeEndEvent` | `CollabResumeEndEvent` | `generated:struct` | `CollabResumeEndEvent.ts` |
| `CollabWaitingBeginEvent` | `CollabWaitingBeginEvent` | `generated:struct` | `CollabWaitingBeginEvent.ts` |
| `CollabWaitingEndEvent` | `CollabWaitingEndEvent` | `generated:struct` | `CollabWaitingEndEvent.ts` |
| `ContextCompactedEvent` | `ContextCompactedEvent` | `generated:struct` | `ContextCompactedEvent.ts` |
| `ContextCompactionItem` | `ContextCompactionItem` | `generated:struct` | `ContextCompactionItem.ts` |
| `CustomPrompt` | `CustomPrompt` | `generated:struct` | `CustomPrompt.ts` |
| `DeprecationNoticeEvent` | `DeprecationNoticeEvent` | `generated:struct` | `DeprecationNoticeEvent.ts` |
| `DynamicToolCallRequest` | `DynamicToolCallRequest` | `generated:struct` | `DynamicToolCallRequest.ts` |
| `DynamicToolCallResponseEvent` | `DynamicToolCallResponseEvent` | `generated:struct` | `DynamicToolCallResponseEvent.ts` |
| `DynamicToolSpec` | `DynamicToolSpec` | `generated:struct` | `v2/DynamicToolSpec.ts` |
| `ElicitationRequest` | `ElicitationRequest` | `generated:enum` | `ElicitationRequest.ts` |
| `ElicitationRequestEvent` | `ElicitationRequestEvent` | `generated:struct` | `ElicitationRequestEvent.ts` |
| `ErrorEvent` | `ErrorEvent` | `generated:struct` | `ErrorEvent.ts` |
| `EventMsg` | `EventMsg` | `generated:enum` | `EventMsg.ts` |
| `ExecApprovalRequestEvent` | `ExecApprovalRequestEvent` | `generated:struct` | `ExecApprovalRequestEvent.ts` |
| `ExecCommandBeginEvent` | `ExecCommandBeginEvent` | `generated:struct` | `ExecCommandBeginEvent.ts` |
| `ExecCommandEndEvent` | `ExecCommandEndEvent` | `generated:struct` | `ExecCommandEndEvent.ts` |
| `ExecCommandOutputDeltaEvent` | `ExecCommandOutputDeltaEvent` | `generated:struct` | `ExecCommandOutputDeltaEvent.ts` |
| `ExecCommandSource` | `ExecCommandSource` | `generated:enum` | `ExecCommandSource.ts` |
| `ExecCommandStatus` | `ExecCommandStatus` | `generated:enum` | `ExecCommandStatus.ts` |
| `ExecOutputStream` | `ExecOutputStream` | `generated:enum` | `ExecOutputStream.ts` |
| `ExitedReviewModeEvent` | `ExitedReviewModeEvent` | `generated:struct` | `ExitedReviewModeEvent.ts` |
| `FileSystemPermissions` | `FileSystemPermissions` | `generated:struct` | `FileSystemPermissions.ts` |
| `GetHistoryEntryResponseEvent` | `GetHistoryEntryResponseEvent` | `generated:struct` | `GetHistoryEntryResponseEvent.ts` |
| `HistoryEntry` | `HistoryEntry` | `generated:struct` | `HistoryEntry.ts` |
| `ImageGenerationBeginEvent` | `ImageGenerationBeginEvent` | `generated:struct` | `ImageGenerationBeginEvent.ts` |
| `ImageGenerationEndEvent` | `ImageGenerationEndEvent` | `generated:struct` | `ImageGenerationEndEvent.ts` |
| `ImageGenerationItem` | `ImageGenerationItem` | `generated:struct` | `ImageGenerationItem.ts` |
| `ItemCompletedEvent` | `ItemCompletedEvent` | `generated:struct` | `ItemCompletedEvent.ts` |
| `ItemStartedEvent` | `ItemStartedEvent` | `generated:struct` | `ItemStartedEvent.ts` |
| `ListCustomPromptsResponseEvent` | `ListCustomPromptsResponseEvent` | `generated:struct` | `ListCustomPromptsResponseEvent.ts` |
| `ListRemoteSkillsResponseEvent` | `ListRemoteSkillsResponseEvent` | `generated:struct` | `ListRemoteSkillsResponseEvent.ts` |
| `ListSkillsResponseEvent` | `ListSkillsResponseEvent` | `generated:struct` | `ListSkillsResponseEvent.ts` |
| `MacOsSeatbeltProfileExtensions` | `MacOsSeatbeltProfileExtensions` | `generated:struct` | `MacOsSeatbeltProfileExtensions.ts` |
| `McpInvocation` | `McpInvocation` | `generated:struct` | `McpInvocation.ts` |
| `McpListToolsResponseEvent` | `McpListToolsResponseEvent` | `generated:struct` | `McpListToolsResponseEvent.ts` |
| `McpStartupCompleteEvent` | `McpStartupCompleteEvent` | `generated:struct` | `McpStartupCompleteEvent.ts` |
| `McpStartupFailure` | `McpStartupFailure` | `generated:struct` | `McpStartupFailure.ts` |
| `McpStartupStatus` | `McpStartupStatus` | `generated:enum` | `McpStartupStatus.ts` |
| `McpStartupUpdateEvent` | `McpStartupUpdateEvent` | `generated:struct` | `McpStartupUpdateEvent.ts` |
| `McpToolCallBeginEvent` | `McpToolCallBeginEvent` | `generated:struct` | `McpToolCallBeginEvent.ts` |
| `McpToolCallEndEvent` | `McpToolCallEndEvent` | `generated:struct` | `McpToolCallEndEvent.ts` |
| `ModelRerouteEvent` | `ModelRerouteEvent` | `generated:struct` | `ModelRerouteEvent.ts` |
| `NetworkPermissions` | `NetworkPermissions` | `generated:struct` | `NetworkPermissions.ts` |
| `NetworkRequirements` | `NetworkRequirements` | `generated:struct` | `v2/NetworkRequirements.ts` |
| `PatchApplyBeginEvent` | `PatchApplyBeginEvent` | `generated:struct` | `PatchApplyBeginEvent.ts` |
| `PatchApplyEndEvent` | `PatchApplyEndEvent` | `generated:struct` | `PatchApplyEndEvent.ts` |
| `PermissionProfile` | `PermissionProfile` | `generated:struct` | `PermissionProfile.ts` |
| `PlanDeltaEvent` | `PlanDeltaEvent` | `generated:struct` | `PlanDeltaEvent.ts` |
| `PlanItem` | `PlanItem` | `generated:struct` | `PlanItem.ts` |
| `PlanItemArg` | `PlanItemArg` | `generated:struct` | `PlanItemArg.ts` |
| `RawResponseItemEvent` | `RawResponseItemEvent` | `generated:struct` | `RawResponseItemEvent.ts` |
| `RealtimeAudioFrame` | `RealtimeAudioFrame` | `generated:struct` | `RealtimeAudioFrame.ts` |
| `RealtimeConversationClosedEvent` | `RealtimeConversationClosedEvent` | `generated:struct` | `RealtimeConversationClosedEvent.ts` |
| `RealtimeConversationRealtimeEvent` | `RealtimeConversationRealtimeEvent` | `generated:struct` | `RealtimeConversationRealtimeEvent.ts` |
| `RealtimeConversationStartedEvent` | `RealtimeConversationStartedEvent` | `generated:struct` | `RealtimeConversationStartedEvent.ts` |
| `RealtimeEvent` | `RealtimeEvent` | `generated:enum` | `RealtimeEvent.ts` |
| `RealtimeHandoffMessage` | `RealtimeHandoffMessage` | `generated:struct` | `RealtimeHandoffMessage.ts` |
| `RealtimeHandoffRequested` | `RealtimeHandoffRequested` | `generated:struct` | `RealtimeHandoffRequested.ts` |
| `ReasoningContentDeltaEvent` | `ReasoningContentDeltaEvent` | `generated:struct` | `ReasoningContentDeltaEvent.ts` |
| `ReasoningItem` | `ReasoningItem` | `generated:struct` | `ReasoningItem.ts` |
| `ReasoningRawContentDeltaEvent` | `ReasoningRawContentDeltaEvent` | `generated:struct` | `ReasoningRawContentDeltaEvent.ts` |
| `RejectConfig` | `RejectConfig` | `generated:struct` | `RejectConfig.ts` |
| `RemoteSkillDownloadedEvent` | `RemoteSkillDownloadedEvent` | `generated:struct` | `RemoteSkillDownloadedEvent.ts` |
| `RequestUserInputEvent` | `RequestUserInputEvent` | `generated:struct` | `RequestUserInputEvent.ts` |
| `RequestUserInputQuestion` | `RequestUserInputQuestion` | `generated:struct` | `RequestUserInputQuestion.ts` |
| `RequestUserInputQuestionOption` | `RequestUserInputQuestionOption` | `generated:struct` | `RequestUserInputQuestionOption.ts` |
| `ReviewCodeLocation` | `ReviewCodeLocation` | `generated:struct` | `ReviewCodeLocation.ts` |
| `ReviewFinding` | `ReviewFinding` | `generated:struct` | `ReviewFinding.ts` |
| `ReviewLineRange` | `ReviewLineRange` | `generated:struct` | `ReviewLineRange.ts` |
| `ReviewOutputEvent` | `ReviewOutputEvent` | `generated:struct` | `ReviewOutputEvent.ts` |
| `ReviewRequest` | `ReviewRequest` | `generated:struct` | `ReviewRequest.ts` |
| `SessionConfiguredEvent` | `SessionConfiguredEvent` | `generated:struct` | `SessionConfiguredEvent.ts` |
| `SessionNetworkProxyRuntime` | `SessionNetworkProxyRuntime` | `generated:struct` | `SessionNetworkProxyRuntime.ts` |
| `StepStatus` | `StepStatus` | `generated:enum` | `StepStatus.ts` |
| `StreamErrorEvent` | `StreamErrorEvent` | `generated:struct` | `StreamErrorEvent.ts` |
| `TerminalInteractionEvent` | `TerminalInteractionEvent` | `generated:struct` | `TerminalInteractionEvent.ts` |
| `ThreadNameUpdatedEvent` | `ThreadNameUpdatedEvent` | `generated:struct` | `ThreadNameUpdatedEvent.ts` |
| `ThreadRolledBackEvent` | `ThreadRolledBackEvent` | `generated:struct` | `ThreadRolledBackEvent.ts` |
| `TokenCountEvent` | `TokenCountEvent` | `generated:struct` | `TokenCountEvent.ts` |
| `TokenUsage` | `TokenUsage` | `generated:struct` | `TokenUsage.ts` |
| `TokenUsageInfo` | `TokenUsageInfo` | `generated:struct` | `TokenUsageInfo.ts` |
| `TurnAbortedEvent` | `TurnAbortedEvent` | `generated:struct` | `TurnAbortedEvent.ts` |
| `TurnAbortReason` | `TurnAbortReason` | `generated:enum` | `TurnAbortReason.ts` |
| `TurnCompleteEvent` | `TurnCompleteEvent` | `generated:struct` | `TurnCompleteEvent.ts` |
| `TurnDiffEvent` | `TurnDiffEvent` | `generated:struct` | `TurnDiffEvent.ts` |
| `TurnItem` | `TurnItem` | `generated:enum` | `TurnItem.ts` |
| `TurnStartedEvent` | `TurnStartedEvent` | `generated:struct` | `TurnStartedEvent.ts` |
| `UndoCompletedEvent` | `UndoCompletedEvent` | `generated:struct` | `UndoCompletedEvent.ts` |
| `UndoStartedEvent` | `UndoStartedEvent` | `generated:struct` | `UndoStartedEvent.ts` |
| `UpdatePlanArgs` | `UpdatePlanArgs` | `generated:struct` | `UpdatePlanArgs.ts` |
| `UserMessageEvent` | `UserMessageEvent` | `generated:struct` | `UserMessageEvent.ts` |
| `UserMessageItem` | `UserMessageItem` | `generated:struct` | `UserMessageItem.ts` |
| `ViewImageToolCallEvent` | `ViewImageToolCallEvent` | `generated:struct` | `ViewImageToolCallEvent.ts` |
| `WarningEvent` | `WarningEvent` | `generated:struct` | `WarningEvent.ts` |
| `WebSearchBeginEvent` | `WebSearchBeginEvent` | `generated:struct` | `WebSearchBeginEvent.ts` |
| `WebSearchEndEvent` | `WebSearchEndEvent` | `generated:struct` | `WebSearchEndEvent.ts` |
| `WebSearchItem` | `WebSearchItem` | `generated:struct` | `WebSearchItem.ts` |

