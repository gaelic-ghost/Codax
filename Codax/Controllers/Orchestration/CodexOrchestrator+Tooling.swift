//
//  CodexOrchestrator+Tooling.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation

/*
 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `appsListResponse`: Holds the most recent `AppsListResponse` returned by `app/list`. Semantically, this is the latest connector catalog snapshot visible to the client for the requested thread or global config context.

 Functions:
 - `appList(params:)`: Sends the generated `app/list` request with `AppsListParams` through the orchestrator-owned runtime, awaits the typed `AppsListResponse`, and stores it in `appsListResponse`. Semantically, this fetches the available connector/app inventory that Codex can mention or route through.

 Properties:
 - `commandExecResponse`: Holds the most recent `CommandExecResponse` returned by `command/exec`. Semantically, this is the latest command session creation or execution result for a direct sandbox command.
 - `commandExecWriteResponse`: Holds the most recent `CommandExecWriteResponse` returned by `command/exec/write`. Semantically, this is the server acknowledgement that stdin bytes were written to, or closed on, an existing command session.
 - `commandExecTerminateResponse`: Holds the most recent `CommandExecTerminateResponse` returned by `command/exec/terminate`. Semantically, this is the acknowledgement that termination was requested for a running command session.
 - `commandExecResizeResponse`: Holds the most recent `CommandExecResizeResponse` returned by `command/exec/resize`. Semantically, this is the acknowledgement that PTY dimensions were updated for a running command session.

 Functions:
 - `commandExec(params:)`: Sends the generated `command/exec` request with `CommandExecParams` through the orchestrator-owned runtime, awaits the typed `CommandExecResponse`, and stores it in `commandExecResponse`. Semantically, this starts or runs a direct sandbox command outside the thread/turn conversation model.
 - `commandExecWrite(params:)`: Sends the generated `command/exec/write` request with `CommandExecWriteParams` through the orchestrator-owned runtime, awaits the typed `CommandExecWriteResponse`, and stores it in `commandExecWriteResponse`. Semantically, this pushes stdin data or an end-of-input signal into an existing direct command session.
 - `commandExecTerminate(params:)`: Sends the generated `command/exec/terminate` request with `CommandExecTerminateParams` through the orchestrator-owned runtime, awaits the typed `CommandExecTerminateResponse`, and stores it in `commandExecTerminateResponse`. Semantically, this asks the server to stop a running direct command session.
 - `commandExecResize(params:)`: Sends the generated `command/exec/resize` request with `CommandExecResizeParams` through the orchestrator-owned runtime, awaits the typed `CommandExecResizeResponse`, and stores it in `commandExecResizeResponse`. Semantically, this updates terminal dimensions for an existing PTY-backed command session.

 Properties:
 - `fuzzyFileSearchResponse`: Holds the most recent `FuzzyFileSearchResponse` returned by `fuzzyFileSearch`. Semantically, this is the latest typed set of fuzzy-matched file-search results produced by the server.

 Functions:
 - `fuzzyFileSearch(params:)`: Sends the generated `fuzzyFileSearch` request with `FuzzyFileSearchParams` through the orchestrator-owned runtime, awaits the typed `FuzzyFileSearchResponse`, and stores it in `fuzzyFileSearchResponse`. Semantically, this asks the server to resolve an inexact file query into ranked candidate file matches.

 Properties:
 - `gitDiffToRemoteResponse`: Holds the most recent `GitDiffToRemoteResponse` returned by `gitDiffToRemote`. Semantically, this is the latest typed representation of the requested local-versus-remote diff calculation.

 Functions:
 - `gitDiffToRemote(params:)`: Sends the generated `gitDiffToRemote` request with `GitDiffToRemoteParams` through the orchestrator-owned runtime, awaits the typed `GitDiffToRemoteResponse`, and stores it in `gitDiffToRemoteResponse`. Semantically, this asks the server to compare current repository state against a remote reference and return that diff result.

 Properties:
 - `mcpServerRefreshResponse`: Holds the most recent `McpServerRefreshResponse` returned by `config/mcpServer/reload`. Semantically, this is the acknowledgement that MCP configuration was reloaded and that loaded threads can pick up refreshed server state on subsequent work.
 - `mcpServerOauthLoginResponse`: Holds the most recent `McpServerOauthLoginResponse` returned by `mcpServer/oauth/login`. Semantically, this is the start-of-login payload for an MCP OAuth flow, including the authorization URL needed to complete browser authentication.
 - `listMcpServerStatusResponse`: Holds the most recent `ListMcpServerStatusResponse` returned by `mcpServerStatus/list`. Semantically, this is the latest enumerated snapshot of configured MCP servers and their exposed capability/auth metadata.

 Functions:
 - `mcpServerOauthLogin(params:)`: Sends the generated `mcpServer/oauth/login` request with `McpServerOauthLoginParams` through the orchestrator-owned runtime, awaits the typed `McpServerOauthLoginResponse`, and stores it in `mcpServerOauthLoginResponse`. Semantically, this initiates an OAuth browser-login flow for one configured MCP server.
 - `configMcpServerReload()`: Sends the generated zero-parameter `config/mcpServer/reload` request through the orchestrator-owned runtime, awaits the typed `McpServerRefreshResponse`, and stores it in `mcpServerRefreshResponse`. Semantically, this reloads MCP server definitions from config on disk without requiring a full server restart.
 - `mcpServerStatusList(params:)`: Sends the generated `mcpServerStatus/list` request with `ListMcpServerStatusParams` through the orchestrator-owned runtime, awaits the typed `ListMcpServerStatusResponse`, and stores it in `listMcpServerStatusResponse`. Semantically, this fetches the current operational and descriptive status of configured MCP servers.

 Properties:
 - `pluginListResponse`: Holds the most recent `PluginListResponse` returned by `plugin/list`. Semantically, this is the latest discovered plugin inventory together with plugin-state metadata.
 - `pluginInstallResponse`: Holds the most recent `PluginInstallResponse` returned by `plugin/install`. Semantically, this is the acknowledgement and resulting state payload for a plugin installation attempt.
 - `pluginUninstallResponse`: Holds the most recent `PluginUninstallResponse` returned by `plugin/uninstall`. Semantically, this is the acknowledgement and resulting state payload for a plugin removal attempt.

 Functions:
 - `pluginList(params:)`: Sends the generated `plugin/list` request with `PluginListParams` through the orchestrator-owned runtime, awaits the typed `PluginListResponse`, and stores it in `pluginListResponse`. Semantically, this fetches the current plugin catalog and installed-state view.
 - `pluginInstall(params:)`: Sends the generated `plugin/install` request with `PluginInstallParams` through the orchestrator-owned runtime, awaits the typed `PluginInstallResponse`, and stores it in `pluginInstallResponse`. Semantically, this requests installation of a selected marketplace plugin into the local Codex environment.
 - `pluginUninstall(params:)`: Sends the generated `plugin/uninstall` request with `PluginUninstallParams` through the orchestrator-owned runtime, awaits the typed `PluginUninstallResponse`, and stores it in `pluginUninstallResponse`. Semantically, this removes a plugin and its user-level configuration footprint from the current environment.

 Properties:
 - `reviewStartResponse`: Holds the most recent `ReviewStartResponse` returned by `review/start`. Semantically, this is the typed initial review-turn response that confirms the review run has been accepted and created.

 Functions:
 - `reviewStart(params:)`: Sends the generated `review/start` request with `ReviewStartParams` through the orchestrator-owned runtime, awaits the typed `ReviewStartResponse`, and stores it in `reviewStartResponse`. Semantically, this kicks off a review workflow for a thread while leaving the streamed review content to the normal event channels.

 Properties:
 - `skillsListResponse`: Holds the most recent `SkillsListResponse` returned by `skills/list`. Semantically, this is the latest local skill inventory and any associated lookup errors for the requested cwd set.
 - `skillsRemoteReadResponse`: Holds the most recent `SkillsRemoteReadResponse` returned by `skills/remote/list`. Semantically, this is the latest typed catalog of remotely available public skills.
 - `skillsRemoteWriteResponse`: Holds the most recent `SkillsRemoteWriteResponse` returned by `skills/remote/export`. Semantically, this is the acknowledgement or result of exporting a remote skill into the local Codex skills area.
 - `skillsConfigWriteResponse`: Holds the most recent `SkillsConfigWriteResponse` returned by `skills/config/write`. Semantically, this is the acknowledgement that a user-level skill enablement setting was updated.

 Functions:
 - `skillsList(params:)`: Sends the generated `skills/list` request with `SkillsListParams` through the orchestrator-owned runtime, awaits the typed `SkillsListResponse`, and stores it in `skillsListResponse`. Semantically, this fetches the current local skill landscape for the specified workspace contexts.
 - `skillsRemoteList(params:)`: Sends the generated `skills/remote/list` request with `SkillsRemoteReadParams` through the orchestrator-owned runtime, awaits the typed `SkillsRemoteReadResponse`, and stores it in `skillsRemoteReadResponse`. Semantically, this reads the remotely published skill catalog exposed by the server.
 - `skillsRemoteExport(params:)`: Sends the generated `skills/remote/export` request with `SkillsRemoteWriteParams` through the orchestrator-owned runtime, awaits the typed `SkillsRemoteWriteResponse`, and stores it in `skillsRemoteWriteResponse`. Semantically, this imports a chosen remote skill into the local skills area managed by Codex.
 - `skillsConfigWrite(params:)`: Sends the generated `skills/config/write` request with `SkillsConfigWriteParams` through the orchestrator-owned runtime, awaits the typed `SkillsConfigWriteResponse`, and stores it in `skillsConfigWriteResponse`. Semantically, this enables or disables a local skill path in user config.
 */


extension CodaxOrchestrator {

		// MARK: - Apps

	func appList(params: AppsListParams) async throws -> AppsListResponse {
		let response = try await runtime.appList(params)
		appsListResponse = response
		return response
	}

		// MARK: - Commands

	func commandExec(params: CommandExecParams) async throws -> CommandExecResponse {
		let response = try await runtime.commandExec(params)
		commandExecResponse = response
		return response
	}

	func commandExecWrite(params: CommandExecWriteParams) async throws -> CommandExecWriteResponse {
		let response = try await runtime.commandExecWrite(params)
		commandExecWriteResponse = response
		return response
	}

	func commandExecTerminate(params: CommandExecTerminateParams) async throws -> CommandExecTerminateResponse {
		let response = try await runtime.commandExecTerminate(params)
		commandExecTerminateResponse = response
		return response
	}

	func commandExecResize(params: CommandExecResizeParams) async throws -> CommandExecResizeResponse {
		let response = try await runtime.commandExecResize(params)
		commandExecResizeResponse = response
		return response
	}

		// MARK: - Fuzzy File Search

	func fuzzyFileSearch(params: FuzzyFileSearchParams) async throws -> FuzzyFileSearchResponse {
		let response = try await runtime.fuzzyFileSearch(params)
		fuzzyFileSearchResponse = response
		return response
	}

		// MARK: - Git Diff To Remote

	func gitDiffToRemote(params: GitDiffToRemoteParams) async throws -> GitDiffToRemoteResponse {
		let response = try await runtime.gitDiffToRemote(params)
		gitDiffToRemoteResponse = response
		return response
	}

		// MARK: - MCP Servers

	func mcpServerOauthLogin(params: McpServerOauthLoginParams) async throws -> McpServerOauthLoginResponse {
		let response = try await runtime.mcpServerOauthLogin(params)
		mcpServerOauthLoginResponse = response
		return response
	}

	func configMcpServerReload() async throws -> McpServerRefreshResponse {
		let response = try await runtime.configMcpServerReload()
		mcpServerRefreshResponse = response
		return response
	}

	func mcpServerStatusList(params: ListMcpServerStatusParams) async throws -> ListMcpServerStatusResponse {
		let response = try await runtime.mcpServerStatusList(params)
		listMcpServerStatusResponse = response
		return response
	}

		// MARK: - Plugins

	func pluginList(params: PluginListParams) async throws -> PluginListResponse {
		let response = try await runtime.pluginList(params)
		pluginListResponse = response
		return response
	}

	func pluginInstall(params: PluginInstallParams) async throws -> PluginInstallResponse {
		let response = try await runtime.pluginInstall(params)
		pluginInstallResponse = response
		return response
	}

	func pluginUninstall(params: PluginUninstallParams) async throws -> PluginUninstallResponse {
		let response = try await runtime.pluginUninstall(params)
		pluginUninstallResponse = response
		return response
	}

		// MARK: - Review

	func reviewStart(params: ReviewStartParams) async throws -> ReviewStartResponse {
		let response = try await runtime.reviewStart(params)
		reviewStartResponse = response
		return response
	}

		// MARK: - Skills

	func skillsList(params: SkillsListParams) async throws -> SkillsListResponse {
		let response = try await runtime.skillsList(params)
		skillsListResponse = response
		return response
	}

	func skillsRemoteList(params: SkillsRemoteReadParams) async throws -> SkillsRemoteReadResponse {
		let response = try await runtime.skillsRemoteList(params)
		skillsRemoteReadResponse = response
		return response
	}

	func skillsRemoteExport(params: SkillsRemoteWriteParams) async throws -> SkillsRemoteWriteResponse {
		let response = try await runtime.skillsRemoteExport(params)
		skillsRemoteWriteResponse = response
		return response
	}

	func skillsConfigWrite(params: SkillsConfigWriteParams) async throws -> SkillsConfigWriteResponse {
		let response = try await runtime.skillsConfigWrite(params)
		skillsConfigWriteResponse = response
		return response
	}

}
