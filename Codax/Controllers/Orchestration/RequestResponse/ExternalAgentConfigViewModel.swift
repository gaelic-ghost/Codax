//
//  ExternalAgentConfigViewModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import Observation

@Observable
final class ExternalAgentConfigViewModel {
	// MARK: - State

	var externalAgentConfigDetectResponse: ExternalAgentConfigDetectResponse?
	var externalAgentConfigImportResponse: ExternalAgentConfigImportResponse?

	// MARK: - Requests

	func externalAgentConfigDetect(using connection: CodexConnection, params: ExternalAgentConfigDetectParams) async throws {
		let response = try await connection.externalAgentConfigDetect(params)
		externalAgentConfigDetectResponse = response
	}

	func externalAgentConfigImport(using connection: CodexConnection, params: ExternalAgentConfigImportParams) async throws {
		let response = try await connection.externalAgentConfigImport(params)
		externalAgentConfigImportResponse = response
	}
}
