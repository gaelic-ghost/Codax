//
//  InitializeViewModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import Observation

@Observable
final class InitializeViewModel {
	// MARK: - State

	var initializeResponse: InitializeResponse?

	// MARK: - Requests

	func initialize(using connection: CodexConnection, params: InitializeParams) async throws {
		let response = try await connection.initialize(params)
		initializeResponse = response
	}
}
