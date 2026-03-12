/*
 `GetConversationSummaryViewModel` is the request/response state holder for the generated conversation-summary query surface. Semantically, this file represents a read-only summary boundary: it asks the server for a typed summary of conversation state and stores the most recent answer verbatim, without synthesizing additional presentation state.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `getConversationSummaryResponse`: Holds the most recent `GetConversationSummaryResponse` returned by `getConversationSummary`. Semantically, this is the latest typed server summary of the requested conversation context.

 Functions:
 - `getConversationSummary(using:params:)`: Sends the generated `getConversationSummary` request with `GetConversationSummaryParams`, awaits the typed `GetConversationSummaryResponse`, and stores it in `getConversationSummaryResponse`. Semantically, this fetches a server-produced summary projection instead of the full underlying conversation payload.
 */

import Foundation
import Observation

@Observable
final class GetConversationSummaryViewModel {
	var getConversationSummaryResponse: GetConversationSummaryResponse?

	func getConversationSummary(using connection: CodexConnection, params: GetConversationSummaryParams) async throws {
		let response = try await connection.getConversationSummary(params)
		getConversationSummaryResponse = response
	}
}
