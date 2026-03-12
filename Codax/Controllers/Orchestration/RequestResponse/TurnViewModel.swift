/*
 `TurnViewModel` is the request/response state holder for the Codex app-server turn surface. Per the app-server protocol and README, a turn is one conversational unit inside a thread: it begins with user input, streams item-level execution and model output, and finishes with a final turn status. This file only caches the initial typed responses for turn control requests; the richer live execution details continue to arrive over notifications outside this class.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `turnStartResponse`: Holds the most recent `TurnStartResponse` returned by `turn/start`. Semantically, this is the initial accepted turn payload for a new user message inside a thread.
 - `turnSteerResponse`: Holds the most recent `TurnSteerResponse` returned by `turn/steer`. Semantically, this is the acknowledgement that additional user input was attached to an already active in-flight turn.
 - `turnInterruptResponse`: Holds the most recent `TurnInterruptResponse` returned by `turn/interrupt`. Semantically, this is the acknowledgement that cancellation was requested for a running turn.

 Functions:
 - `turnStart(using:params:)`: Sends the generated `turn/start` request with `TurnStartParams`, awaits the typed `TurnStartResponse`, and stores it in `turnStartResponse`. Semantically, this begins a new turn inside an existing thread and triggers the streamed turn/item lifecycle.
 - `turnSteer(using:params:)`: Sends the generated `turn/steer` request with `TurnSteerParams`, awaits the typed `TurnSteerResponse`, and stores it in `turnSteerResponse`. Semantically, this injects additional guidance into the currently active turn instead of starting a separate turn.
 - `turnInterrupt(using:params:)`: Sends the generated `turn/interrupt` request with `TurnInterruptParams`, awaits the typed `TurnInterruptResponse`, and stores it in `turnInterruptResponse`. Semantically, this requests early termination of the active turn so it can finish in an interrupted state.
 */

import Foundation
import Observation

@Observable
final class TurnViewModel {
	var turnStartResponse: TurnStartResponse?
	var turnSteerResponse: TurnSteerResponse?
	var turnInterruptResponse: TurnInterruptResponse?

	func turnStart(using connection: CodexConnection, params: TurnStartParams) async throws {
		let response = try await connection.turnStart(params)
		turnStartResponse = response
	}

	func turnSteer(using connection: CodexConnection, params: TurnSteerParams) async throws {
		let response = try await connection.turnSteer(params)
		turnSteerResponse = response
	}

	func turnInterrupt(using connection: CodexConnection, params: TurnInterruptParams) async throws {
		let response = try await connection.turnInterrupt(params)
		turnInterruptResponse = response
	}
}
