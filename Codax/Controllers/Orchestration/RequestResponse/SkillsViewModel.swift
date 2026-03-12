//
//  SkillsViewModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import Observation

@Observable
final class SkillsViewModel {
	// MARK: - State

	var skillsListResponse: SkillsListResponse?
	var skillsRemoteReadResponse: SkillsRemoteReadResponse?
	var skillsRemoteWriteResponse: SkillsRemoteWriteResponse?
	var skillsConfigWriteResponse: SkillsConfigWriteResponse?

	// MARK: - Requests

	func skillsList(using connection: CodexConnection, params: SkillsListParams) async throws {
		let response = try await connection.skillsList(params)
		skillsListResponse = response
	}

	func skillsRemoteList(using connection: CodexConnection, params: SkillsRemoteReadParams) async throws {
		let response = try await connection.skillsRemoteList(params)
		skillsRemoteReadResponse = response
	}

	func skillsRemoteExport(using connection: CodexConnection, params: SkillsRemoteWriteParams) async throws {
		let response = try await connection.skillsRemoteExport(params)
		skillsRemoteWriteResponse = response
	}

	func skillsConfigWrite(using connection: CodexConnection, params: SkillsConfigWriteParams) async throws {
		let response = try await connection.skillsConfigWrite(params)
		skillsConfigWriteResponse = response
	}
}
