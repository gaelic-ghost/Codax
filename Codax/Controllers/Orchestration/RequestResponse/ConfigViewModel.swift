//
//  ConfigViewModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import Observation

@Observable
final class ConfigViewModel {
	// MARK: - State

	var configReadResponse: ConfigReadResponse?
	var configRequirementsReadResponse: ConfigRequirementsReadResponse?
	var configWriteResponse: ConfigWriteResponse?

	// MARK: - Requests

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
