//
//  ExperimentalFeatureViewModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import Observation

@Observable
final class ExperimentalFeatureViewModel {
	// MARK: - State

	var experimentalFeatureListResponse: ExperimentalFeatureListResponse?

	// MARK: - Requests

	func experimentalFeatureList(using connection: CodexConnection, params: ExperimentalFeatureListParams) async throws {
		let response = try await connection.experimentalFeatureList(params)
		experimentalFeatureListResponse = response
	}
}
