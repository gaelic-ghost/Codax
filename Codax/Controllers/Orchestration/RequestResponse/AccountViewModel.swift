//
//  AccountViewModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import Observation

@Observable
final class AccountViewModel {
	// MARK: - State

	var loginAccountResponse: LoginAccountResponse?
	var cancelLoginAccountResponse: CancelLoginAccountResponse?
	var logoutAccountResponse: LogoutAccountResponse?
	var getAccountRateLimitsResponse: GetAccountRateLimitsResponse?
	var getAccountResponse: GetAccountResponse?

	// MARK: - Requests

	func accountLoginStart(using connection: CodexConnection, params: LoginAccountParams) async throws {
		let response = try await connection.accountLoginStart(params)
		loginAccountResponse = response
	}

	func accountLoginCancel(using connection: CodexConnection, params: CancelLoginAccountParams) async throws {
		let response = try await connection.accountLoginCancel(params)
		cancelLoginAccountResponse = response
	}

	func accountLogout(using connection: CodexConnection) async throws {
		let response = try await connection.accountLogout()
		logoutAccountResponse = response
	}

	func accountRateLimitsRead(using connection: CodexConnection) async throws {
		let response = try await connection.accountRateLimitsRead()
		getAccountRateLimitsResponse = response
	}

	func accountRead(using connection: CodexConnection, params: GetAccountParams) async throws {
		let response = try await connection.accountRead(params)
		getAccountResponse = response
	}
}
