//
//  GetAuthStatusViewModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import Observation

@Observable
final class GetAuthStatusViewModel {
	// MARK: - State

	var getAuthStatusResponse: GetAuthStatusResponse?

	// MARK: - Requests

	func getAuthStatus(using connection: CodexConnection, params: GetAuthStatusParams) async throws {
		let response = try await connection.getAuthStatus(params)
		getAuthStatusResponse = response
	}
}
