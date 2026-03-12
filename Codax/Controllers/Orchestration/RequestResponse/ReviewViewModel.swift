//
//  ReviewViewModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import Observation

@Observable
final class ReviewViewModel {
	// MARK: - State

	var reviewStartResponse: ReviewStartResponse?

	// MARK: - Requests

	func reviewStart(using connection: CodexConnection, params: ReviewStartParams) async throws {
		let response = try await connection.reviewStart(params)
		reviewStartResponse = response
	}
}
