//
//  TurnViewModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import Observation

@Observable
final class TurnViewModel {
	// MARK: - State

	var turnStartResponse: TurnStartResponse?
	var turnSteerResponse: TurnSteerResponse?
	var turnInterruptResponse: TurnInterruptResponse?

	// MARK: - Requests

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
