/*
 `AppViewModel` is the request/response state holder for the Codex app-server app-listing surface. Per the Codex app-server documentation, `app/list` enumerates available apps or connectors, including install metadata, accessibility, and enabled state. Semantically, this file exists to cache the last typed app-list response and nothing more; it does not reinterpret app-server semantics or add orchestration logic.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `appsListResponse`: Holds the most recent `AppsListResponse` returned by `app/list`. Semantically, this is the latest connector catalog snapshot visible to the client for the requested thread or global config context.

 Functions:
 - `appList(using:params:)`: Sends the generated `app/list` request with `AppsListParams`, awaits the typed `AppsListResponse`, and stores it in `appsListResponse`. Semantically, this fetches the available connector/app inventory that Codex can mention or route through.
 */

import Foundation
import Observation

@Observable
final class AppViewModel {
	var appsListResponse: AppsListResponse?

	func appList(using connection: CodexConnection, params: AppsListParams) async throws {
		let response = try await connection.appList(params)
		appsListResponse = response
	}
}
