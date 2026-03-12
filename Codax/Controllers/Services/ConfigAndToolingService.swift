import Foundation

/*
 `ConfigAndToolingService` includes the app-listing request/response surface for the Codex app-server. Per the Codex app-server documentation, `app/list` enumerates available apps or connectors, including install metadata, accessibility, and enabled state. Semantically, this section exists to cache the last typed app-list response and nothing more; it does not reinterpret app-server semantics or add orchestration logic.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `appsListResponse`: Holds the most recent `AppsListResponse` returned by `app/list`. Semantically, this is the latest connector catalog snapshot visible to the client for the requested thread or global config context.

 Functions:
 - `appList(using:params:)`: Sends the generated `app/list` request with `AppsListParams`, awaits the typed `AppsListResponse`, and stores it in `appsListResponse`. Semantically, this fetches the available connector/app inventory that Codex can mention or route through.
 */

/*
 `ConfigAndToolingService` includes the standalone command-execution request/response surface for the Codex app-server. Per the app-server protocol, `command/exec` runs a single sandboxed command without creating a thread or turn, while its sibling routes stream stdin, termination, and PTY resize control to the running process. Semantically, this section models the lifecycle of a direct utility command session at the protocol boundary by remembering the last typed response for each command-control request.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `commandExecResponse`: Holds the most recent `CommandExecResponse` returned by `command/exec`. Semantically, this is the latest command session creation or execution result for a direct sandbox command.
 - `commandExecWriteResponse`: Holds the most recent `CommandExecWriteResponse` returned by `command/exec/write`. Semantically, this is the server acknowledgement that stdin bytes were written to, or closed on, an existing command session.
 - `commandExecTerminateResponse`: Holds the most recent `CommandExecTerminateResponse` returned by `command/exec/terminate`. Semantically, this is the acknowledgement that termination was requested for a running command session.
 - `commandExecResizeResponse`: Holds the most recent `CommandExecResizeResponse` returned by `command/exec/resize`. Semantically, this is the acknowledgement that PTY dimensions were updated for a running command session.

 Functions:
 - `commandExec(using:params:)`: Sends the generated `command/exec` request with `CommandExecParams`, awaits the typed `CommandExecResponse`, and stores it in `commandExecResponse`. Semantically, this starts or runs a direct sandbox command outside the thread/turn conversation model.
 - `commandExecWrite(using:params:)`: Sends the generated `command/exec/write` request with `CommandExecWriteParams`, awaits the typed `CommandExecWriteResponse`, and stores it in `commandExecWriteResponse`. Semantically, this pushes stdin data or an end-of-input signal into an existing direct command session.
 - `commandExecTerminate(using:params:)`: Sends the generated `command/exec/terminate` request with `CommandExecTerminateParams`, awaits the typed `CommandExecTerminateResponse`, and stores it in `commandExecTerminateResponse`. Semantically, this asks the server to stop a running direct command session.
 - `commandExecResize(using:params:)`: Sends the generated `command/exec/resize` request with `CommandExecResizeParams`, awaits the typed `CommandExecResizeResponse`, and stores it in `commandExecResizeResponse`. Semantically, this updates terminal dimensions for an existing PTY-backed command session.
 */

/*
 `ConfigAndToolingService` includes Codex configuration and admin-requirements request/response surfaces. Per the Codex CLI config reference and the app-server API, `config/read` returns the effective layered configuration, `config/value/write` and `config/batchWrite` persist user-level config edits to `config.toml`, and `configRequirements/read` returns enforced constraints from `requirements.toml` or managed policy sources. Semantically, this section captures the protocol boundary for configuration state rather than deriving any higher-level settings model of its own.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `configReadResponse`: Holds the most recent `ConfigReadResponse` returned by `config/read`. Semantically, this is the latest resolved configuration snapshot after Codex has applied config layering rules.
 - `configRequirementsReadResponse`: Holds the most recent `ConfigRequirementsReadResponse` returned by `configRequirements/read`. Semantically, this is the latest enforced-policy snapshot describing which approvals, sandbox modes, features, MCP servers, and network settings are allowed or pinned.
 - `configWriteResponse`: Holds the most recent `ConfigWriteResponse` returned by either `config/value/write` or `config/batchWrite`. Semantically, this is the acknowledgement that a user-level config mutation was accepted and written.

 Functions:
 - `configRead(using:params:)`: Sends the generated `config/read` request with `ConfigReadParams`, awaits the typed `ConfigReadResponse`, and stores it in `configReadResponse`. Semantically, this fetches the effective current config view without modifying it.
 - `configRequirementsRead(using:)`: Sends the generated zero-parameter `configRequirements/read` request, awaits the typed `ConfigRequirementsReadResponse`, and stores it in `configRequirementsReadResponse`. Semantically, this fetches the active policy constraints that limit or shape allowable config choices.
 - `configValueWrite(using:params:)`: Sends the generated `config/value/write` request with `ConfigValueWriteParams`, awaits the typed `ConfigWriteResponse`, and stores it in `configWriteResponse`. Semantically, this applies a single config key/value mutation to user config on disk.
 - `configBatchWrite(using:params:)`: Sends the generated `config/batchWrite` request with `ConfigBatchWriteParams`, awaits the typed `ConfigWriteResponse`, and stores it in `configWriteResponse`. Semantically, this applies multiple config edits atomically as one user-config write operation.
 */

/*
 `ConfigAndToolingService` includes external-agent migration discovery and import request/response surfaces. Per the app-server API overview, `externalAgentConfig/detect` scans for migratable external-agent artifacts and `externalAgentConfig/import` applies selected migration items into Codex-managed configuration. Semantically, this section represents a protocol-facing migration surface: detection describes what can be imported, and import acknowledges what was brought into the current Codex configuration world.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `externalAgentConfigDetectResponse`: Holds the most recent `ExternalAgentConfigDetectResponse` returned by `externalAgentConfig/detect`. Semantically, this is the latest discovery snapshot of external-agent artifacts that could be migrated into Codex.
 - `externalAgentConfigImportResponse`: Holds the most recent `ExternalAgentConfigImportResponse` returned by `externalAgentConfig/import`. Semantically, this is the latest acknowledgement of a chosen migration set being applied.

 Functions:
 - `externalAgentConfigDetect(using:params:)`: Sends the generated `externalAgentConfig/detect` request with `ExternalAgentConfigDetectParams`, awaits the typed `ExternalAgentConfigDetectResponse`, and stores it in `externalAgentConfigDetectResponse`. Semantically, this asks the server to inspect home and workspace locations for supported external-agent config sources.
 - `externalAgentConfigImport(using:params:)`: Sends the generated `externalAgentConfig/import` request with `ExternalAgentConfigImportParams`, awaits the typed `ExternalAgentConfigImportResponse`, and stores it in `externalAgentConfigImportResponse`. Semantically, this applies explicit migration items that were previously detected and approved for import.
 */

/*
 `ConfigAndToolingService` includes the fuzzy file-search request/response surface exposed by the generated connection schema. Semantically, this section represents a typed file-discovery query boundary: it sends a search request expressed in generated params and stores the exact generated search result without layering additional ranking or selection logic on top.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `fuzzyFileSearchResponse`: Holds the most recent `FuzzyFileSearchResponse` returned by `fuzzyFileSearch`. Semantically, this is the latest typed set of fuzzy-matched file-search results produced by the server.

 Functions:
 - `fuzzyFileSearch(using:params:)`: Sends the generated `fuzzyFileSearch` request with `FuzzyFileSearchParams`, awaits the typed `FuzzyFileSearchResponse`, and stores it in `fuzzyFileSearchResponse`. Semantically, this asks the server to resolve an inexact file query into ranked candidate file matches.
 */

/*
 `ConfigAndToolingService` includes the git-diff-to-remote request/response surface from the generated connection schema. Semantically, this section captures a transport-level repository comparison result: it asks the server to compute a diff against a remote target and stores the typed answer exactly as returned, without post-processing the diff or mixing it into thread state.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `gitDiffToRemoteResponse`: Holds the most recent `GitDiffToRemoteResponse` returned by `gitDiffToRemote`. Semantically, this is the latest typed representation of the requested local-versus-remote diff calculation.

 Functions:
 - `gitDiffToRemote(using:params:)`: Sends the generated `gitDiffToRemote` request with `GitDiffToRemoteParams`, awaits the typed `GitDiffToRemoteResponse`, and stores it in `gitDiffToRemoteResponse`. Semantically, this asks the server to compare current repository state against a remote reference and return that diff result.
 */

/*
 `ConfigAndToolingService` includes MCP-server authentication, reload, and status-enumeration request/response surfaces. Per the app-server API and CLI config reference, Codex can launch or connect to MCP servers, authenticate to them through OAuth, reload their configuration from `config.toml`, and list each configured server's tools, resources, and auth status. Semantically, this section is the typed protocol cache for that MCP-management surface.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `mcpServerRefreshResponse`: Holds the most recent `McpServerRefreshResponse` returned by `config/mcpServer/reload`. Semantically, this is the acknowledgement that MCP configuration was reloaded and that loaded threads can pick up refreshed server state on subsequent work.
 - `mcpServerOauthLoginResponse`: Holds the most recent `McpServerOauthLoginResponse` returned by `mcpServer/oauth/login`. Semantically, this is the start-of-login payload for an MCP OAuth flow, including the authorization URL needed to complete browser authentication.
 - `listMcpServerStatusResponse`: Holds the most recent `ListMcpServerStatusResponse` returned by `mcpServerStatus/list`. Semantically, this is the latest enumerated snapshot of configured MCP servers and their exposed capability/auth metadata.

 Functions:
 - `mcpServerOauthLogin(using:params:)`: Sends the generated `mcpServer/oauth/login` request with `McpServerOauthLoginParams`, awaits the typed `McpServerOauthLoginResponse`, and stores it in `mcpServerOauthLoginResponse`. Semantically, this initiates an OAuth browser-login flow for one configured MCP server.
 - `configMcpServerReload(using:)`: Sends the generated zero-parameter `config/mcpServer/reload` request, awaits the typed `McpServerRefreshResponse`, and stores it in `mcpServerRefreshResponse`. Semantically, this reloads MCP server definitions from config on disk without requiring a full server restart.
 - `mcpServerStatusList(using:params:)`: Sends the generated `mcpServerStatus/list` request with `ListMcpServerStatusParams`, awaits the typed `ListMcpServerStatusResponse`, and stores it in `listMcpServerStatusResponse`. Semantically, this fetches the current operational and descriptive status of configured MCP servers.
 */

/*
 `ConfigAndToolingService` includes plugin discovery and installation-management request/response surfaces. Per the app-server API overview, `plugin/list` reports discovered plugin marketplaces and plugin state, while `plugin/install` and `plugin/uninstall` mutate the locally installed plugin set. Semantically, this section is the typed cache of the last response seen for each plugin-management request and does not add lifecycle policy beyond what the protocol already defines.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `pluginListResponse`: Holds the most recent `PluginListResponse` returned by `plugin/list`. Semantically, this is the latest discovered plugin inventory together with plugin-state metadata.
 - `pluginInstallResponse`: Holds the most recent `PluginInstallResponse` returned by `plugin/install`. Semantically, this is the acknowledgement and resulting state payload for a plugin installation attempt.
 - `pluginUninstallResponse`: Holds the most recent `PluginUninstallResponse` returned by `plugin/uninstall`. Semantically, this is the acknowledgement and resulting state payload for a plugin removal attempt.

 Functions:
 - `pluginList(using:params:)`: Sends the generated `plugin/list` request with `PluginListParams`, awaits the typed `PluginListResponse`, and stores it in `pluginListResponse`. Semantically, this fetches the current plugin catalog and installed-state view.
 - `pluginInstall(using:params:)`: Sends the generated `plugin/install` request with `PluginInstallParams`, awaits the typed `PluginInstallResponse`, and stores it in `pluginInstallResponse`. Semantically, this requests installation of a selected marketplace plugin into the local Codex environment.
 - `pluginUninstall(using:params:)`: Sends the generated `plugin/uninstall` request with `PluginUninstallParams`, awaits the typed `PluginUninstallResponse`, and stores it in `pluginUninstallResponse`. Semantically, this removes a plugin and its user-level configuration footprint from the current environment.
 */

/*
 `ConfigAndToolingService` includes the automated-review request/response surface for the Codex app-server. Per the app-server API overview, `review/start` begins a review turn for an existing thread and then streams the actual review work through normal turn and item notifications. Semantically, this section stores the initial typed acceptance response for that review request, not the streamed review body itself.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `reviewStartResponse`: Holds the most recent `ReviewStartResponse` returned by `review/start`. Semantically, this is the typed initial review-turn response that confirms the review run has been accepted and created.

 Functions:
 - `reviewStart(using:params:)`: Sends the generated `review/start` request with `ReviewStartParams`, awaits the typed `ReviewStartResponse`, and stores it in `reviewStartResponse`. Semantically, this kicks off a review workflow for a thread while leaving the streamed review content to the normal event channels.
 */

/*
 `ConfigAndToolingService` includes local and remote skill discovery plus skill-configuration-write request/response surfaces. Per the app-server API and README, `skills/list` enumerates locally available skills for one or more working directories, `skills/remote/list` and `skills/remote/export` expose a remote skill catalog and import path, and `skills/config/write` toggles user-level skill enablement by path. Semantically, this section is the typed cache for that skill-management protocol surface.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `skillsListResponse`: Holds the most recent `SkillsListResponse` returned by `skills/list`. Semantically, this is the latest local skill inventory and any associated lookup errors for the requested cwd set.
 - `skillsRemoteReadResponse`: Holds the most recent `SkillsRemoteReadResponse` returned by `skills/remote/list`. Semantically, this is the latest typed catalog of remotely available public skills.
 - `skillsRemoteWriteResponse`: Holds the most recent `SkillsRemoteWriteResponse` returned by `skills/remote/export`. Semantically, this is the acknowledgement or result of exporting a remote skill into the local Codex skills area.
 - `skillsConfigWriteResponse`: Holds the most recent `SkillsConfigWriteResponse` returned by `skills/config/write`. Semantically, this is the acknowledgement that a user-level skill enablement setting was updated.

 Functions:
 - `skillsList(using:params:)`: Sends the generated `skills/list` request with `SkillsListParams`, awaits the typed `SkillsListResponse`, and stores it in `skillsListResponse`. Semantically, this fetches the current local skill landscape for the specified workspace contexts.
 - `skillsRemoteList(using:params:)`: Sends the generated `skills/remote/list` request with `SkillsRemoteReadParams`, awaits the typed `SkillsRemoteReadResponse`, and stores it in `skillsRemoteReadResponse`. Semantically, this reads the remotely published skill catalog exposed by the server.
 - `skillsRemoteExport(using:params:)`: Sends the generated `skills/remote/export` request with `SkillsRemoteWriteParams`, awaits the typed `SkillsRemoteWriteResponse`, and stores it in `skillsRemoteWriteResponse`. Semantically, this imports a chosen remote skill into the local skills area managed by Codex.
 - `skillsConfigWrite(using:params:)`: Sends the generated `skills/config/write` request with `SkillsConfigWriteParams`, awaits the typed `SkillsConfigWriteResponse`, and stores it in `skillsConfigWriteResponse`. Semantically, this enables or disables a local skill path in user config.
 */

final class ConfigAndToolingService {
	// MARK: - Apps

	var appsListResponse: AppsListResponse?

	func appList(using connection: CodexConnection, params: AppsListParams) async throws -> AppsListResponse {
		let response = try await connection.appList(params)
		appsListResponse = response
		return response
	}

	// MARK: - Commands

	var commandExecResponse: CommandExecResponse?
	var commandExecWriteResponse: CommandExecWriteResponse?
	var commandExecTerminateResponse: CommandExecTerminateResponse?
	var commandExecResizeResponse: CommandExecResizeResponse?

	func commandExec(using connection: CodexConnection, params: CommandExecParams) async throws -> CommandExecResponse {
		let response = try await connection.commandExec(params)
		commandExecResponse = response
		return response
	}

	func commandExecWrite(using connection: CodexConnection, params: CommandExecWriteParams) async throws -> CommandExecWriteResponse {
		let response = try await connection.commandExecWrite(params)
		commandExecWriteResponse = response
		return response
	}

	func commandExecTerminate(using connection: CodexConnection, params: CommandExecTerminateParams) async throws -> CommandExecTerminateResponse {
		let response = try await connection.commandExecTerminate(params)
		commandExecTerminateResponse = response
		return response
	}

	func commandExecResize(using connection: CodexConnection, params: CommandExecResizeParams) async throws -> CommandExecResizeResponse {
		let response = try await connection.commandExecResize(params)
		commandExecResizeResponse = response
		return response
	}

	// MARK: - Config

	var configReadResponse: ConfigReadResponse?
	var configRequirementsReadResponse: ConfigRequirementsReadResponse?
	var configWriteResponse: ConfigWriteResponse?

	func configRead(using connection: CodexConnection, params: ConfigReadParams) async throws -> ConfigReadResponse {
		let response = try await connection.configRead(params)
		configReadResponse = response
		return response
	}

	func configRequirementsRead(using connection: CodexConnection) async throws -> ConfigRequirementsReadResponse {
		let response = try await connection.configRequirementsRead()
		configRequirementsReadResponse = response
		return response
	}

	func configValueWrite(using connection: CodexConnection, params: ConfigValueWriteParams) async throws -> ConfigWriteResponse {
		let response = try await connection.configValueWrite(params)
		configWriteResponse = response
		return response
	}

	func configBatchWrite(using connection: CodexConnection, params: ConfigBatchWriteParams) async throws -> ConfigWriteResponse {
		let response = try await connection.configBatchWrite(params)
		configWriteResponse = response
		return response
	}

	// MARK: - External Agent Config

	var externalAgentConfigDetectResponse: ExternalAgentConfigDetectResponse?
	var externalAgentConfigImportResponse: ExternalAgentConfigImportResponse?

	func externalAgentConfigDetect(using connection: CodexConnection, params: ExternalAgentConfigDetectParams) async throws -> ExternalAgentConfigDetectResponse {
		let response = try await connection.externalAgentConfigDetect(params)
		externalAgentConfigDetectResponse = response
		return response
	}

	func externalAgentConfigImport(using connection: CodexConnection, params: ExternalAgentConfigImportParams) async throws -> ExternalAgentConfigImportResponse {
		let response = try await connection.externalAgentConfigImport(params)
		externalAgentConfigImportResponse = response
		return response
	}

	// MARK: - Fuzzy File Search

	var fuzzyFileSearchResponse: FuzzyFileSearchResponse?

	func fuzzyFileSearch(using connection: CodexConnection, params: FuzzyFileSearchParams) async throws -> FuzzyFileSearchResponse {
		let response = try await connection.fuzzyFileSearch(params)
		fuzzyFileSearchResponse = response
		return response
	}

	// MARK: - Git Diff To Remote

	var gitDiffToRemoteResponse: GitDiffToRemoteResponse?

	func gitDiffToRemote(using connection: CodexConnection, params: GitDiffToRemoteParams) async throws -> GitDiffToRemoteResponse {
		let response = try await connection.gitDiffToRemote(params)
		gitDiffToRemoteResponse = response
		return response
	}

	// MARK: - MCP Servers

	var mcpServerRefreshResponse: McpServerRefreshResponse?
	var mcpServerOauthLoginResponse: McpServerOauthLoginResponse?
	var listMcpServerStatusResponse: ListMcpServerStatusResponse?

	func mcpServerOauthLogin(using connection: CodexConnection, params: McpServerOauthLoginParams) async throws -> McpServerOauthLoginResponse {
		let response = try await connection.mcpServerOauthLogin(params)
		mcpServerOauthLoginResponse = response
		return response
	}

	func configMcpServerReload(using connection: CodexConnection) async throws -> McpServerRefreshResponse {
		let response = try await connection.configMcpServerReload()
		mcpServerRefreshResponse = response
		return response
	}

	func mcpServerStatusList(using connection: CodexConnection, params: ListMcpServerStatusParams) async throws -> ListMcpServerStatusResponse {
		let response = try await connection.mcpServerStatusList(params)
		listMcpServerStatusResponse = response
		return response
	}

	// MARK: - Plugins

	var pluginListResponse: PluginListResponse?
	var pluginInstallResponse: PluginInstallResponse?
	var pluginUninstallResponse: PluginUninstallResponse?

	func pluginList(using connection: CodexConnection, params: PluginListParams) async throws -> PluginListResponse {
		let response = try await connection.pluginList(params)
		pluginListResponse = response
		return response
	}

	func pluginInstall(using connection: CodexConnection, params: PluginInstallParams) async throws -> PluginInstallResponse {
		let response = try await connection.pluginInstall(params)
		pluginInstallResponse = response
		return response
	}

	func pluginUninstall(using connection: CodexConnection, params: PluginUninstallParams) async throws -> PluginUninstallResponse {
		let response = try await connection.pluginUninstall(params)
		pluginUninstallResponse = response
		return response
	}

	// MARK: - Review

	var reviewStartResponse: ReviewStartResponse?

	func reviewStart(using connection: CodexConnection, params: ReviewStartParams) async throws -> ReviewStartResponse {
		let response = try await connection.reviewStart(params)
		reviewStartResponse = response
		return response
	}

	// MARK: - Skills

	var skillsListResponse: SkillsListResponse?
	var skillsRemoteReadResponse: SkillsRemoteReadResponse?
	var skillsRemoteWriteResponse: SkillsRemoteWriteResponse?
	var skillsConfigWriteResponse: SkillsConfigWriteResponse?

	func skillsList(using connection: CodexConnection, params: SkillsListParams) async throws -> SkillsListResponse {
		let response = try await connection.skillsList(params)
		skillsListResponse = response
		return response
	}

	func skillsRemoteList(using connection: CodexConnection, params: SkillsRemoteReadParams) async throws -> SkillsRemoteReadResponse {
		let response = try await connection.skillsRemoteList(params)
		skillsRemoteReadResponse = response
		return response
	}

	func skillsRemoteExport(using connection: CodexConnection, params: SkillsRemoteWriteParams) async throws -> SkillsRemoteWriteResponse {
		let response = try await connection.skillsRemoteExport(params)
		skillsRemoteWriteResponse = response
		return response
	}

	func skillsConfigWrite(using connection: CodexConnection, params: SkillsConfigWriteParams) async throws -> SkillsConfigWriteResponse {
		let response = try await connection.skillsConfigWrite(params)
		skillsConfigWriteResponse = response
		return response
	}
}
