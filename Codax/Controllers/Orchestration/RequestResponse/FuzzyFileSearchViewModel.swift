//
//  FuzzyFileSearchViewModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import Observation

@Observable
final class FuzzyFileSearchViewModel {
	// MARK: - State

	var fuzzyFileSearchResponse: FuzzyFileSearchResponse?

	// MARK: - Requests

	func fuzzyFileSearch(using connection: CodexConnection, params: FuzzyFileSearchParams) async throws {
		let response = try await connection.fuzzyFileSearch(params)
		fuzzyFileSearchResponse = response
	}
}
