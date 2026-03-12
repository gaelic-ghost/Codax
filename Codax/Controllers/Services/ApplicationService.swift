import Foundation

/*
 `ApplicationService` includes the account and authentication request/response surface for the Codex app-server. Per the Codex app-server API overview and auth documentation, this section covers reading the current auth state, starting or cancelling login, logging out, and reading ChatGPT rate-limit information. Semantically, this section does not model business logic; it is a thin Observation-backed cache of the last typed response received for each account-related request so the rest of the app can react to concrete protocol results.

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

/*
 `ApplicationService` includes the auth-status request/response surface for the generated connection schema. Semantically, this section preserves the latest typed answer to a server auth-status question without merging it into the broader account-login flow. It is intentionally narrow: one request, one typed cached response, no additional interpretation.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `getAuthStatusResponse`: Holds the most recent `GetAuthStatusResponse` returned by `getAuthStatus`. Semantically, this is the latest typed snapshot describing the server-reported auth status for the queried context.

 Functions:
 - `getAuthStatus(using:params:)`: Sends the generated `getAuthStatus` request with `GetAuthStatusParams`, awaits the typed `GetAuthStatusResponse`, and stores it in `getAuthStatusResponse`. Semantically, this performs a read-only auth-status query through the generated connection surface.
 */

/*
 `ApplicationService` includes the connection-initialization request/response surface for the Codex app-server. Per the app-server protocol and README, every transport connection must send `initialize` exactly once before any other request, and the server returns connection-level metadata such as the user agent it will present upstream. Semantically, this section caches the typed handshake result for the current connection and nothing more.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `initializeResponse`: Holds the most recent `InitializeResponse` returned by `initialize`. Semantically, this is the current handshake result for the active connection, including any protocol-negotiated metadata the server reports back.

 Functions:
 - `initialize(using:params:)`: Sends the generated `initialize` request with `InitializeParams`, awaits the typed `InitializeResponse`, and stores it in `initializeResponse`. Semantically, this performs the required one-time connection initialization that must precede all normal request traffic on that transport.
 */

/*
 `ApplicationService` includes the model-catalog request/response surface for the Codex app-server. Per the app-server API, `model/list` returns available models and related metadata such as hidden status, reasoning options, and possible upgrade information. Semantically, this section caches the last typed model catalog response for the client without folding it into broader configuration logic.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `modelListResponse`: Holds the most recent `ModelListResponse` returned by `model/list`. Semantically, this is the latest typed catalog of models the server currently exposes to the client.

 Functions:
 - `modelList(using:params:)`: Sends the generated `model/list` request with `ModelListParams`, awaits the typed `ModelListResponse`, and stores it in `modelListResponse`. Semantically, this fetches the set of available model choices and their metadata for the current server context.
 */

/*
 `ApplicationService` includes the experimental-feature catalog request/response surface for the Codex app-server. Per the app-server API overview, `experimentalFeature/list` returns feature-flag entries with lifecycle stage metadata such as beta, under-development, or stable status. Semantically, this section exposes the last typed feature-list response so the UI can reason about surfaced feature flags without embedding protocol logic elsewhere.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `experimentalFeatureListResponse`: Holds the most recent `ExperimentalFeatureListResponse` returned by `experimentalFeature/list`. Semantically, this is the latest server-advertised catalog of feature flags and their rollout metadata.

 Functions:
 - `experimentalFeatureList(using:params:)`: Sends the generated `experimentalFeature/list` request with `ExperimentalFeatureListParams`, awaits the typed `ExperimentalFeatureListResponse`, and stores it in `experimentalFeatureListResponse`. Semantically, this fetches the current experimental feature registry that the server wants the client to know about.
 */

final class ApplicationService {
	// MARK: - Account

	var loginAccountResponse: LoginAccountResponse?
	var cancelLoginAccountResponse: CancelLoginAccountResponse?
	var logoutAccountResponse: LogoutAccountResponse?
	var getAccountRateLimitsResponse: GetAccountRateLimitsResponse?
	var getAccountResponse: GetAccountResponse?

		// MARK: - Auth Status

	var getAuthStatusResponse: GetAuthStatusResponse?

		// MARK: - Initialization

	var initializeResponse: InitializeResponse?

		// MARK: - Models

	var modelListResponse: ModelListResponse?

		// MARK: - Experimental Features

	var experimentalFeatureListResponse: ExperimentalFeatureListResponse?

}

	// MARK: INTERNAL METHODS

extension ApplicationService {

		// MARK: - Account

	func accountLoginStart(using connection: CodexConnection, params: LoginAccountParams) async throws -> LoginAccountResponse {
		let response = try await connection.accountLoginStart(params)
		loginAccountResponse = response
		return response
	}

	func accountLoginCancel(using connection: CodexConnection, params: CancelLoginAccountParams) async throws -> CancelLoginAccountResponse {
		let response = try await connection.accountLoginCancel(params)
		cancelLoginAccountResponse = response
		return response
	}

	func accountLogout(using connection: CodexConnection) async throws -> LogoutAccountResponse {
		let response = try await connection.accountLogout()
		logoutAccountResponse = response
		return response
	}

	func accountRateLimitsRead(using connection: CodexConnection) async throws -> GetAccountRateLimitsResponse {
		let response = try await connection.accountRateLimitsRead()
		getAccountRateLimitsResponse = response
		return response
	}

	func accountRead(using connection: CodexConnection, params: GetAccountParams) async throws -> GetAccountResponse {
		let response = try await connection.accountRead(params)
		getAccountResponse = response
		return response
	}

		// MARK: - Auth Status

	func getAuthStatus(using connection: CodexConnection, params: GetAuthStatusParams) async throws -> GetAuthStatusResponse {
		let response = try await connection.getAuthStatus(params)
		getAuthStatusResponse = response
		return response
	}

		// MARK: - Initialization

	func initialize(using connection: CodexConnection, params: InitializeParams) async throws -> InitializeResponse {
		let response = try await connection.initialize(params)
		initializeResponse = response
		return response
	}

		// MARK: - Models

	func modelList(using connection: CodexConnection, params: ModelListParams) async throws -> ModelListResponse {
		let response = try await connection.modelList(params)
		modelListResponse = response
		return response
	}

		// MARK: - Experimental Features

	func experimentalFeatureList(using connection: CodexConnection, params: ExperimentalFeatureListParams) async throws -> ExperimentalFeatureListResponse {
		let response = try await connection.experimentalFeatureList(params)
		experimentalFeatureListResponse = response
		return response
	}

}
