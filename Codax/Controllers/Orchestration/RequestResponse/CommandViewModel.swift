/*
 `CommandViewModel` is the request/response state holder for the Codex app-server standalone command-execution surface. Per the app-server protocol, `command/exec` runs a single sandboxed command without creating a thread or turn, while its sibling routes stream stdin, termination, and PTY resize control to the running process. Semantically, this file models the lifecycle of a direct utility command session at the protocol boundary by remembering the last typed response for each command-control request.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `commandExecResponse`: Holds the most recent `CommandExecResponse` returned by `command/exec`. Semantically, this is the latest command session creation or execution result for a direct sandbox command.
 - `commandExecWriteResponse`: Holds the most recent `CommandExecWriteResponse` returned by `command/exec/write`. Semantically, this is the server acknowledgement that stdin bytes were written to, or closed on, an existing command session.
 - `commandExecTerminateResponse`: Holds the most recent `CommandExecTerminateResponse` returned by `command/exec/terminate`. Semantically, this is the acknowledgement that termination was requested for a running command session.
 - `commandExecResizeResponse`: Holds the most recent `CommandExecResizeResponse` returned by `command/exec/resize`. Semantically, this is the acknowledgement that PTY dimensions were updated for a running command session.

 Functions:
 - `commandExec(using:params:)`: Sends the generated `command/exec` request with `CommandExecParams`, awaits the typed `CommandExecResponse`, and stores it in `commandExecResponse`. Semantically, this starts or runs a direct sandbox command outside the thread/turn conversation model.
 - `commandExecWrite(using:params:)`: Sends the generated `command/exec/write` request with `CommandExecWriteParams`, awaits the typed `CommandExecWriteResponse`, and stores it in `commandExecWriteResponse`. Semantically, this pushes stdin data or an end-of-input signal into an existing direct command session.
 - `commandExecTerminate(using:params:)`: Sends the generated `command/exec/terminate` request with `CommandExecTerminateParams`, awaits the typed `CommandExecTerminateResponse`, and stores it in `commandExecTerminateResponse`. Semantically, this asks the server to stop a running direct command session.
 - `commandExecResize(using:params:)`: Sends the generated `command/exec/resize` request with `CommandExecResizeParams`, awaits the typed `CommandExecResizeResponse`, and stores it in `commandExecResizeResponse`. Semantically, this updates terminal dimensions for an existing PTY-backed command session.
 */

import Foundation
import Observation

@Observable
final class CommandViewModel {
	var commandExecResponse: CommandExecResponse?
	var commandExecWriteResponse: CommandExecWriteResponse?
	var commandExecTerminateResponse: CommandExecTerminateResponse?
	var commandExecResizeResponse: CommandExecResizeResponse?

	func commandExec(using connection: CodexConnection, params: CommandExecParams) async throws {
		let response = try await connection.commandExec(params)
		commandExecResponse = response
	}

	func commandExecWrite(using connection: CodexConnection, params: CommandExecWriteParams) async throws {
		let response = try await connection.commandExecWrite(params)
		commandExecWriteResponse = response
	}

	func commandExecTerminate(using connection: CodexConnection, params: CommandExecTerminateParams) async throws {
		let response = try await connection.commandExecTerminate(params)
		commandExecTerminateResponse = response
	}

	func commandExecResize(using connection: CodexConnection, params: CommandExecResizeParams) async throws {
		let response = try await connection.commandExecResize(params)
		commandExecResizeResponse = response
	}
}
