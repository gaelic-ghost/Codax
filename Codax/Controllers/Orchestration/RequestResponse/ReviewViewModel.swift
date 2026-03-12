/*
 `ReviewViewModel` is the request/response state holder for the Codex automated-review surface. Per the app-server API overview, `review/start` begins a review turn for an existing thread and then streams the actual review work through normal turn and item notifications. Semantically, this file stores the initial typed acceptance response for that review request, not the streamed review body itself.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `reviewStartResponse`: Holds the most recent `ReviewStartResponse` returned by `review/start`. Semantically, this is the typed initial review-turn response that confirms the review run has been accepted and created.

 Functions:
 - `reviewStart(using:params:)`: Sends the generated `review/start` request with `ReviewStartParams`, awaits the typed `ReviewStartResponse`, and stores it in `reviewStartResponse`. Semantically, this kicks off a review workflow for a thread while leaving the streamed review content to the normal event channels.
 */

import Foundation
import Observation

@Observable
final class ReviewViewModel {
	var reviewStartResponse: ReviewStartResponse?

	func reviewStart(using connection: CodexConnection, params: ReviewStartParams) async throws {
		let response = try await connection.reviewStart(params)
		reviewStartResponse = response
	}
}
