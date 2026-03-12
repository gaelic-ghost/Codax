/*
 `FuzzyFileSearchViewModel` is the request/response state holder for the fuzzy file-search surface exposed by the generated connection schema. Semantically, this file represents a typed file-discovery query boundary: it sends a search request expressed in generated params and stores the exact generated search result without layering additional ranking or selection logic on top.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `fuzzyFileSearchResponse`: Holds the most recent `FuzzyFileSearchResponse` returned by `fuzzyFileSearch`. Semantically, this is the latest typed set of fuzzy-matched file-search results produced by the server.

 Functions:
 - `fuzzyFileSearch(using:params:)`: Sends the generated `fuzzyFileSearch` request with `FuzzyFileSearchParams`, awaits the typed `FuzzyFileSearchResponse`, and stores it in `fuzzyFileSearchResponse`. Semantically, this asks the server to resolve an inexact file query into ranked candidate file matches.
 */

import Foundation
import Observation

@Observable
final class FuzzyFileSearchViewModel {
	var fuzzyFileSearchResponse: FuzzyFileSearchResponse?

	func fuzzyFileSearch(using connection: CodexConnection, params: FuzzyFileSearchParams) async throws {
		let response = try await connection.fuzzyFileSearch(params)
		fuzzyFileSearchResponse = response
	}
}
