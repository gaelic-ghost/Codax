//
//  CommandViewModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import Observation

@Observable
final class CommandViewModel {
	// MARK: - State

	var commandExecResponse: CommandExecResponse?
	var commandExecWriteResponse: CommandExecWriteResponse?
	var commandExecTerminateResponse: CommandExecTerminateResponse?
	var commandExecResizeResponse: CommandExecResizeResponse?

	// MARK: - Requests

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
