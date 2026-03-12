//
//  PluginViewModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import Observation

@Observable
final class PluginViewModel {
	// MARK: - State

	var pluginListResponse: PluginListResponse?
	var pluginInstallResponse: PluginInstallResponse?
	var pluginUninstallResponse: PluginUninstallResponse?

	// MARK: - Requests

	func pluginList(using connection: CodexConnection, params: PluginListParams) async throws {
		let response = try await connection.pluginList(params)
		pluginListResponse = response
	}

	func pluginInstall(using connection: CodexConnection, params: PluginInstallParams) async throws {
		let response = try await connection.pluginInstall(params)
		pluginInstallResponse = response
	}

	func pluginUninstall(using connection: CodexConnection, params: PluginUninstallParams) async throws {
		let response = try await connection.pluginUninstall(params)
		pluginUninstallResponse = response
	}
}
