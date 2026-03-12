//
//  CodaxViewModel+Types.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

// MARK: - View Model Types

public enum CodaxCompatibilityState: Sendable, Equatable {
	case unknown
	case checking
	case supported(version: CodexCLIVersion, path: String?)
	case unsupported(version: CodexCLIVersion?, path: String?, supportedRange: String, reason: String)

	init(_ compatibility: CodexCLICompatibility) {
		switch compatibility {
			case .unknown:
				self = .unknown
			case .checking:
				self = .checking
			case let .supported(version, path):
				self = .supported(version: version, path: path)
			case let .unsupported(version, path, supportedRange, reason):
				self = .unsupported(
					version: version,
					path: path,
					supportedRange: supportedRange,
					reason: reason
				)
		}
	}
}

struct CodaxViewModelError: Equatable {
	let message: String
}

struct CodaxCompatibilityDebugInfo: Equatable {
	let formattedDescription: String
}

struct CodaxPendingLogin: Equatable {
	let loginId: String
	let authURL: String
}

struct CodaxProjectState: Identifiable, Equatable, Sendable {
	let id: UUID
	var name: String
	var rootPath: String
	var isActive: Bool
	var threadCodexIDs: [String]
	var updatedAt: Date
}

struct CodaxThreadSessionState: Equatable, Sendable {
	let threadCodexId: String
	var model: String
	var modelProvider: String
	var serviceTier: ServiceTier?
	var cwd: String
	var approvalPolicy: AskForApproval
	var sandboxPolicy: SandboxPolicy
	var reasoningEffort: ReasoningEffort?
}

struct CodaxThreadGitDiffState: Equatable, Sendable {
	let threadCodexId: String
	var response: GitDiffToRemoteResponse?
	var errorMessage: String?
	var updatedAt: Date
}
