//
//  McpServerViewModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import Observation

@Observable
final class McpServerViewModel {
	// MARK: - State

	var mcpServerRefreshResponse: McpServerRefreshResponse?
	var mcpServerOauthLoginResponse: McpServerOauthLoginResponse?
	var listMcpServerStatusResponse: ListMcpServerStatusResponse?

	// MARK: - Requests

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
