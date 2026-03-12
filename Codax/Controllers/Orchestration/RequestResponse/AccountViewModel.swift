/*
 `AccountViewModel` is the request/response state holder for the Codex app-server account and authentication surface. Per the Codex app-server API overview and auth documentation, this surface covers reading the current auth state, starting or cancelling login, logging out, and reading ChatGPT rate-limit information. Semantically, this file does not model business logic; it is a thin Observation-backed cache of the last typed response received for each account-related request so the rest of the app can react to concrete protocol results.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `loginAccountResponse`: Holds the most recent `LoginAccountResponse` returned by `account/login/start`. Semantically, this captures the beginning of an auth flow, either confirming API-key login immediately or carrying ChatGPT browser-login data such as the login identifier and authorization URL.
 - `cancelLoginAccountResponse`: Holds the most recent `CancelLoginAccountResponse` returned by `account/login/cancel`. Semantically, this represents the server's acknowledgement that a pending ChatGPT login attempt was cancelled or resolved through the cancellation path.
 - `logoutAccountResponse`: Holds the most recent `LogoutAccountResponse` returned by `account/logout`. Semantically, this is the typed acknowledgement that the current authenticated session was cleared.
 - `getAccountRateLimitsResponse`: Holds the most recent `GetAccountRateLimitsResponse` returned by `account/rateLimits/read`. Semantically, this is the most recently fetched quota window and usage snapshot for ChatGPT-backed authentication.
 - `getAccountResponse`: Holds the most recent `GetAccountResponse` returned by `account/read`. Semantically, this is the canonical local snapshot of current auth mode, current account identity if any, and whether OpenAI authentication is required for the active provider setup.

 Functions:
 - `accountLoginStart(using:params:)`: Sends the generated `account/login/start` request through `CodexConnection` using the exact generated `LoginAccountParams`, awaits the typed `LoginAccountResponse`, and stores it in `loginAccountResponse`. Semantically, this begins a new login attempt using either API-key or ChatGPT-managed authentication.
 - `accountLoginCancel(using:params:)`: Sends the generated `account/login/cancel` request with `CancelLoginAccountParams`, awaits the typed `CancelLoginAccountResponse`, and stores it in `cancelLoginAccountResponse`. Semantically, this asks the server to stop an in-flight ChatGPT browser login associated with a specific login identifier.
 - `accountLogout(using:)`: Sends the generated zero-parameter `account/logout` request, awaits the typed `LogoutAccountResponse`, and stores it in `logoutAccountResponse`. Semantically, this clears the current auth session from the server side.
 - `accountRateLimitsRead(using:)`: Sends the generated zero-parameter `account/rateLimits/read` request, awaits the typed `GetAccountRateLimitsResponse`, and stores it in `getAccountRateLimitsResponse`. Semantically, this refreshes the current rate-limit view for ChatGPT-backed usage.
 - `accountRead(using:params:)`: Sends the generated `account/read` request with `GetAccountParams`, awaits the typed `GetAccountResponse`, and stores it in `getAccountResponse`. Semantically, this fetches the current authenticated account state without changing it.
 */

import Foundation
import Observation

@Observable
final class AccountViewModel {
	var loginAccountResponse: LoginAccountResponse?
	var cancelLoginAccountResponse: CancelLoginAccountResponse?
	var logoutAccountResponse: LogoutAccountResponse?
	var getAccountRateLimitsResponse: GetAccountRateLimitsResponse?
	var getAccountResponse: GetAccountResponse?

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
