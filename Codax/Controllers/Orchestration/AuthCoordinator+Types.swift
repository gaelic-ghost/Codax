//
//  AuthCoordinator+Types.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: - Orchestration Layer Auth Types

public enum LoginState: Sendable, Equatable {
	case signedOut
	case authorizing
	case signedIn
	case failed(String)
}
