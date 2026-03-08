//
//  AuthCoordinator.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import Foundation

	// MARK: - Authentication Coordinator for future, optional in-app Auth flow
	// would support a bundled/pinned Codex executable, if needed in future.

	// MARK: Protocol

@MainActor
public protocol AuthCoordinator: AnyObject {
	func openAuthURL(_ url: URL) async throws
}

	// MARK: Concrete Implementation
