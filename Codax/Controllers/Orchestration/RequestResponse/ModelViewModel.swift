/*
 `ModelViewModel` is the request/response state holder for the Codex model catalog surface. Per the app-server API, `model/list` returns available models and related metadata such as hidden status, reasoning options, and possible upgrade information. Semantically, this file caches the last typed model catalog response for the client without folding it into broader configuration logic.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `modelListResponse`: Holds the most recent `ModelListResponse` returned by `model/list`. Semantically, this is the latest typed catalog of models the server currently exposes to the client.

 Functions:
 - `modelList(using:params:)`: Sends the generated `model/list` request with `ModelListParams`, awaits the typed `ModelListResponse`, and stores it in `modelListResponse`. Semantically, this fetches the set of available model choices and their metadata for the current server context.
 */

import Foundation
import Observation

@Observable
final class ModelViewModel {
	var modelListResponse: ModelListResponse?

	func modelList(using connection: CodexConnection, params: ModelListParams) async throws {
		let response = try await connection.modelList(params)
		modelListResponse = response
	}
}
