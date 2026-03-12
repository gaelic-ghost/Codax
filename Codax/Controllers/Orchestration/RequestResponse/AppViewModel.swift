//
//  AppViewModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import Observation

@Observable
final class AppViewModel {
	// MARK: - State

	var appsListResponse: AppsListResponse?

	// MARK: - Requests

	func appList(using connection: CodexConnection, params: AppsListParams) async throws {
		let response = try await connection.appList(params)
		appsListResponse = response
	}
}
