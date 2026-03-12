/*
 `GetAuthStatusViewModel` is the request/response state holder for the generated auth-status query surface. Semantically, this file exists to preserve the latest typed answer to a server auth-status question without merging it into the broader account-login flow. It is intentionally narrow: one request, one typed cached response, no additional interpretation.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `getAuthStatusResponse`: Holds the most recent `GetAuthStatusResponse` returned by `getAuthStatus`. Semantically, this is the latest typed snapshot describing the server-reported auth status for the queried context.

 Functions:
 - `getAuthStatus(using:params:)`: Sends the generated `getAuthStatus` request with `GetAuthStatusParams`, awaits the typed `GetAuthStatusResponse`, and stores it in `getAuthStatusResponse`. Semantically, this performs a read-only auth-status query through the generated connection surface.
 */

import Foundation
import Observation

@Observable
final class GetAuthStatusViewModel {
	var getAuthStatusResponse: GetAuthStatusResponse?

	func getAuthStatus(using connection: CodexConnection, params: GetAuthStatusParams) async throws {
		let response = try await connection.getAuthStatus(params)
		getAuthStatusResponse = response
	}
}
