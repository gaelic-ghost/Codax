//
//  GitDiffToRemoteViewModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import Observation

@Observable
final class GitDiffToRemoteViewModel {
	// MARK: - State

	var gitDiffToRemoteResponse: GitDiffToRemoteResponse?

	// MARK: - Requests

	func gitDiffToRemote(using connection: CodexConnection, params: GitDiffToRemoteParams) async throws {
		let response = try await connection.gitDiffToRemote(params)
		gitDiffToRemoteResponse = response
	}
}
