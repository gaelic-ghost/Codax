/*
 `ExperimentalFeatureViewModel` is the request/response state holder for the Codex app-server experimental-feature catalog. Per the app-server API overview, `experimentalFeature/list` returns feature-flag entries with lifecycle stage metadata such as beta, under-development, or stable status. Semantically, this file exposes the last typed feature-list response so the UI can reason about surfaced feature flags without embedding protocol logic elsewhere.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `experimentalFeatureListResponse`: Holds the most recent `ExperimentalFeatureListResponse` returned by `experimentalFeature/list`. Semantically, this is the latest server-advertised catalog of feature flags and their rollout metadata.

 Functions:
 - `experimentalFeatureList(using:params:)`: Sends the generated `experimentalFeature/list` request with `ExperimentalFeatureListParams`, awaits the typed `ExperimentalFeatureListResponse`, and stores it in `experimentalFeatureListResponse`. Semantically, this fetches the current experimental feature registry that the server wants the client to know about.
 */

import Foundation
import Observation

@Observable
final class ExperimentalFeatureViewModel {
	var experimentalFeatureListResponse: ExperimentalFeatureListResponse?

	func experimentalFeatureList(using connection: CodexConnection, params: ExperimentalFeatureListParams) async throws {
		let response = try await connection.experimentalFeatureList(params)
		experimentalFeatureListResponse = response
	}
}
