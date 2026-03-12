//
//  CodexOrchestrator+Config.swift
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
 - `configReadResponse`: Holds the most recent `ConfigReadResponse` returned by `config/read`. Semantically, this is the latest resolved configuration snapshot after Codex has applied config layering rules.
 - `configRequirementsReadResponse`: Holds the most recent `ConfigRequirementsReadResponse` returned by `configRequirements/read`. Semantically, this is the latest enforced-policy snapshot describing which approvals, sandbox modes, features, MCP servers, and network settings are allowed or pinned.
 - `configWriteResponse`: Holds the most recent `ConfigWriteResponse` returned by either `config/value/write` or `config/batchWrite`. Semantically, this is the acknowledgement that a user-level config mutation was accepted and written.

 Functions:
 - `configRead(params:)`: Sends the generated `config/read` request with `ConfigReadParams` through the orchestrator-owned runtime, awaits the typed `ConfigReadResponse`, and stores it in `configReadResponse`. Semantically, this fetches the effective current config view without modifying it.
 - `configRequirementsRead()`: Sends the generated zero-parameter `configRequirements/read` request through the orchestrator-owned runtime, awaits the typed `ConfigRequirementsReadResponse`, and stores it in `configRequirementsReadResponse`. Semantically, this fetches the active policy constraints that limit or shape allowable config choices.
 - `configValueWrite(params:)`: Sends the generated `config/value/write` request with `ConfigValueWriteParams` through the orchestrator-owned runtime, awaits the typed `ConfigWriteResponse`, and stores it in `configWriteResponse`. Semantically, this applies a single config key/value mutation to user config on disk.
 - `configBatchWrite(params:)`: Sends the generated `config/batchWrite` request with `ConfigBatchWriteParams` through the orchestrator-owned runtime, awaits the typed `ConfigWriteResponse`, and stores it in `configWriteResponse`. Semantically, this applies multiple config edits atomically as one user-config write operation.

 Properties:
 - `externalAgentConfigDetectResponse`: Holds the most recent `ExternalAgentConfigDetectResponse` returned by `externalAgentConfig/detect`. Semantically, this is the latest discovery snapshot of external-agent artifacts that could be migrated into Codex.
 - `externalAgentConfigImportResponse`: Holds the most recent `ExternalAgentConfigImportResponse` returned by `externalAgentConfig/import`. Semantically, this is the latest acknowledgement of a chosen migration set being applied.

 Functions:
 - `externalAgentConfigDetect(params:)`: Sends the generated `externalAgentConfig/detect` request with `ExternalAgentConfigDetectParams` through the orchestrator-owned runtime, awaits the typed `ExternalAgentConfigDetectResponse`, and stores it in `externalAgentConfigDetectResponse`. Semantically, this asks the server to inspect home and workspace locations for supported external-agent config sources.
 - `externalAgentConfigImport(params:)`: Sends the generated `externalAgentConfig/import` request with `ExternalAgentConfigImportParams` through the orchestrator-owned runtime, awaits the typed `ExternalAgentConfigImportResponse`, and stores it in `externalAgentConfigImportResponse`. Semantically, this applies explicit migration items that were previously detected and approved for import.
 */

extension CodaxOrchestrator {

		// MARK: - Config

	func configRead(params: ConfigReadParams) async throws -> ConfigReadResponse {
		let response = try await runtime.configRead(params)
		configReadResponse = response
		return response
	}

	func configRequirementsRead() async throws -> ConfigRequirementsReadResponse {
		let response = try await runtime.configRequirementsRead()
		configRequirementsReadResponse = response
		return response
	}

	func configValueWrite(params: ConfigValueWriteParams) async throws -> ConfigWriteResponse {
		let response = try await runtime.configValueWrite(params)
		configWriteResponse = response
		return response
	}

	func configBatchWrite(params: ConfigBatchWriteParams) async throws -> ConfigWriteResponse {
		let response = try await runtime.configBatchWrite(params)
		configWriteResponse = response
		return response
	}

		// MARK: - External Agent Config

	func externalAgentConfigDetect(params: ExternalAgentConfigDetectParams) async throws -> ExternalAgentConfigDetectResponse {
		let response = try await runtime.externalAgentConfigDetect(params)
		externalAgentConfigDetectResponse = response
		return response
	}

	func externalAgentConfigImport(params: ExternalAgentConfigImportParams) async throws -> ExternalAgentConfigImportResponse {
		let response = try await runtime.externalAgentConfigImport(params)
		externalAgentConfigImportResponse = response
		return response
	}

}
