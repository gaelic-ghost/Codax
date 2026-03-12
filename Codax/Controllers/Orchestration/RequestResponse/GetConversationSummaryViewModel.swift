//
//  GetConversationSummaryViewModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import Observation

@Observable
final class GetConversationSummaryViewModel {
	// MARK: - State

	var getConversationSummaryResponse: GetConversationSummaryResponse?

	// MARK: - Requests

	func getConversationSummary(using connection: CodexConnection, params: GetConversationSummaryParams) async throws {
		let response = try await connection.getConversationSummary(params)
		getConversationSummaryResponse = response
	}
}
