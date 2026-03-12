/*
 `PluginViewModel` is the request/response state holder for plugin discovery and installation management. Per the app-server API overview, `plugin/list` reports discovered plugin marketplaces and plugin state, while `plugin/install` and `plugin/uninstall` mutate the locally installed plugin set. Semantically, this file is the typed cache of the last response seen for each plugin-management request and does not add lifecycle policy beyond what the protocol already defines.

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

import Foundation
import Observation

@Observable
final class PluginViewModel {
	var pluginListResponse: PluginListResponse?
	var pluginInstallResponse: PluginInstallResponse?
	var pluginUninstallResponse: PluginUninstallResponse?

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
