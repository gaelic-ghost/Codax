//
//  CodexProcess+Types.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

// MARK: - Transport Layer Codex Process Management Types

import Foundation

public struct CodexProcessStderrSnapshot: Sendable, Equatable {
	public let text: String
	public let truncated: Bool
}

public enum CodexProcessLifecycleState: Sendable, Equatable {
	case idle
	case launching
	case running(processIdentifier: Int32?)
	case terminating(processIdentifier: Int32?)
	case exited(status: Int32)
	case failedLaunch
}

public enum CodexProcessError: Error, LocalizedError, Sendable {
	case launchFailed(command: String, reason: String, stderrSnapshot: CodexProcessStderrSnapshot?)
	case transitionInProgress(state: CodexProcessLifecycleState)

	public var errorDescription: String? {
		switch self {
			case let .launchFailed(command, reason, _):
				return "Failed to launch `\(command)`: \(reason)"
			case let .transitionInProgress(state):
				return "Codex process transition already in progress: \(String(describing: state))"
		}
	}
}
