/*
 `SkillsViewModel` is the request/response state holder for local and remote skill discovery plus skill configuration writes. Per the app-server API and README, `skills/list` enumerates locally available skills for one or more working directories, `skills/remote/list` and `skills/remote/export` expose a remote skill catalog and import path, and `skills/config/write` toggles user-level skill enablement by path. Semantically, this file is the typed cache for that skill-management protocol surface.

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

import Foundation
import Observation

@Observable
final class SkillsViewModel {
	var skillsListResponse: SkillsListResponse?
	var skillsRemoteReadResponse: SkillsRemoteReadResponse?
	var skillsRemoteWriteResponse: SkillsRemoteWriteResponse?
	var skillsConfigWriteResponse: SkillsConfigWriteResponse?

	func skillsList(using connection: CodexConnection, params: SkillsListParams) async throws {
		let response = try await connection.skillsList(params)
		skillsListResponse = response
	}

	func skillsRemoteList(using connection: CodexConnection, params: SkillsRemoteReadParams) async throws {
		let response = try await connection.skillsRemoteList(params)
		skillsRemoteReadResponse = response
	}

	func skillsRemoteExport(using connection: CodexConnection, params: SkillsRemoteWriteParams) async throws {
		let response = try await connection.skillsRemoteExport(params)
		skillsRemoteWriteResponse = response
	}

	func skillsConfigWrite(using connection: CodexConnection, params: SkillsConfigWriteParams) async throws {
		let response = try await connection.skillsConfigWrite(params)
		skillsConfigWriteResponse = response
	}
}
