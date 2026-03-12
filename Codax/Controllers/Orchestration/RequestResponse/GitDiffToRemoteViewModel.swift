/*
 `GitDiffToRemoteViewModel` is the request/response state holder for the generated git-diff query surface. Semantically, this file captures a transport-level repository comparison result: it asks the server to compute a diff against a remote target and stores the typed answer exactly as returned, without post-processing the diff or mixing it into thread state.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `gitDiffToRemoteResponse`: Holds the most recent `GitDiffToRemoteResponse` returned by `gitDiffToRemote`. Semantically, this is the latest typed representation of the requested local-versus-remote diff calculation.

 Functions:
 - `gitDiffToRemote(using:params:)`: Sends the generated `gitDiffToRemote` request with `GitDiffToRemoteParams`, awaits the typed `GitDiffToRemoteResponse`, and stores it in `gitDiffToRemoteResponse`. Semantically, this asks the server to compare current repository state against a remote reference and return that diff result.
 */

import Foundation
import Observation

@Observable
final class GitDiffToRemoteViewModel {
	var gitDiffToRemoteResponse: GitDiffToRemoteResponse?

	func gitDiffToRemote(using connection: CodexConnection, params: GitDiffToRemoteParams) async throws {
		let response = try await connection.gitDiffToRemote(params)
		gitDiffToRemoteResponse = response
	}
}
