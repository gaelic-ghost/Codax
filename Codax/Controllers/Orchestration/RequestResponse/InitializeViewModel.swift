/*
 `InitializeViewModel` is the request/response state holder for the Codex app-server connection handshake. Per the app-server protocol and README, every transport connection must send `initialize` exactly once before any other request, and the server returns connection-level metadata such as the user agent it will present upstream. Semantically, this file caches the typed handshake result for the current connection and nothing more.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `initializeResponse`: Holds the most recent `InitializeResponse` returned by `initialize`. Semantically, this is the current handshake result for the active connection, including any protocol-negotiated metadata the server reports back.

 Functions:
 - `initialize(using:params:)`: Sends the generated `initialize` request with `InitializeParams`, awaits the typed `InitializeResponse`, and stores it in `initializeResponse`. Semantically, this performs the required one-time connection initialization that must precede all normal request traffic on that transport.
 */

import Foundation
import Observation

@Observable
final class InitializeViewModel {
	var initializeResponse: InitializeResponse?

	func initialize(using connection: CodexConnection, params: InitializeParams) async throws {
		let response = try await connection.initialize(params)
		initializeResponse = response
	}
}
