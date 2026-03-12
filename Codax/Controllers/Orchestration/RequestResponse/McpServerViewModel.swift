/*
 `McpServerViewModel` is the request/response state holder for MCP-server authentication, reload, and status enumeration. Per the app-server API and CLI config reference, Codex can launch or connect to MCP servers, authenticate to them through OAuth, reload their configuration from `config.toml`, and list each configured server's tools, resources, and auth status. Semantically, this file is the typed protocol cache for that MCP-management surface.

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

import Foundation
import Observation

@Observable
final class McpServerViewModel {
	var mcpServerRefreshResponse: McpServerRefreshResponse?
	var mcpServerOauthLoginResponse: McpServerOauthLoginResponse?
	var listMcpServerStatusResponse: ListMcpServerStatusResponse?

	func mcpServerOauthLogin(using connection: CodexConnection, params: McpServerOauthLoginParams) async throws {
		let response = try await connection.mcpServerOauthLogin(params)
		mcpServerOauthLoginResponse = response
	}

	func configMcpServerReload(using connection: CodexConnection) async throws {
		let response = try await connection.configMcpServerReload()
		mcpServerRefreshResponse = response
	}

	func mcpServerStatusList(using connection: CodexConnection, params: ListMcpServerStatusParams) async throws {
		let response = try await connection.mcpServerStatusList(params)
		listMcpServerStatusResponse = response
	}
}
