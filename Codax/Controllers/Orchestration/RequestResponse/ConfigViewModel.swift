/*
 `ConfigViewModel` is the request/response state holder for Codex configuration reads, writes, and admin requirement reads. Per the Codex CLI config reference and the app-server API, `config/read` returns the effective layered configuration, `config/value/write` and `config/batchWrite` persist user-level config edits to `config.toml`, and `configRequirements/read` returns enforced constraints from `requirements.toml` or managed policy sources. Semantically, this file captures the protocol boundary for configuration state rather than deriving any higher-level settings model of its own.

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

import Foundation
import Observation

@Observable
final class ConfigViewModel {
	var configReadResponse: ConfigReadResponse?
	var configRequirementsReadResponse: ConfigRequirementsReadResponse?
	var configWriteResponse: ConfigWriteResponse?

	func configRead(using connection: CodexConnection, params: ConfigReadParams) async throws {
		let response = try await connection.configRead(params)
		configReadResponse = response
	}

	func configRequirementsRead(using connection: CodexConnection) async throws {
		let response = try await connection.configRequirementsRead()
		configRequirementsReadResponse = response
	}

	func configValueWrite(using connection: CodexConnection, params: ConfigValueWriteParams) async throws {
		let response = try await connection.configValueWrite(params)
		configWriteResponse = response
	}

	func configBatchWrite(using connection: CodexConnection, params: ConfigBatchWriteParams) async throws {
		let response = try await connection.configBatchWrite(params)
		configWriteResponse = response
	}
}
