/*
 `ExternalAgentConfigViewModel` is the request/response state holder for external-agent migration discovery and import. Per the app-server API overview, `externalAgentConfig/detect` scans for migratable external-agent artifacts and `externalAgentConfig/import` applies selected migration items into Codex-managed configuration. Semantically, this file represents a protocol-facing migration surface: detection describes what can be imported, and import acknowledges what was brought into the current Codex configuration world.

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

import Foundation
import Observation

@Observable
final class ExternalAgentConfigViewModel {
	var externalAgentConfigDetectResponse: ExternalAgentConfigDetectResponse?
	var externalAgentConfigImportResponse: ExternalAgentConfigImportResponse?

	func externalAgentConfigDetect(using connection: CodexConnection, params: ExternalAgentConfigDetectParams) async throws {
		let response = try await connection.externalAgentConfigDetect(params)
		externalAgentConfigDetectResponse = response
	}

	func externalAgentConfigImport(using connection: CodexConnection, params: ExternalAgentConfigImportParams) async throws {
		let response = try await connection.externalAgentConfigImport(params)
		externalAgentConfigImportResponse = response
	}
}
