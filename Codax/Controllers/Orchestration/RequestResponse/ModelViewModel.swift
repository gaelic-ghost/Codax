//
//  ModelViewModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import Observation

@Observable
final class ModelViewModel {
	// MARK: - State

	var modelListResponse: ModelListResponse?

	// MARK: - Requests

	func modelList(using connection: CodexConnection, params: ModelListParams) async throws {
		let response = try await connection.modelList(params)
		modelListResponse = response
	}
}
