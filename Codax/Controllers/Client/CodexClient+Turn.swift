//
//  CodexClient+Turn.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: - Client Layer `Turn` Types

public enum TurnStatus: String, Sendable, Codable, Equatable {
	case completed
	case interrupted
	case failed
	case inProgress
}

	// MARK: Base Types

public struct Turn: Sendable, Codable, Equatable {
	public var id: String
	/// The app-server currently leaves this empty on `turn/started` and `turn/completed`.
	/// Treat live `item/*` notifications as the canonical item stream.
	public var items: [ThreadItem]
	public var status: TurnStatus
	public var error: TurnError?
}

	// MARK: Params

public struct TurnStartParams: Sendable, Codable {
	public var threadId: String
	public var input: [JSONValue]
	public var cwd: String?
	public var approvalPolicy: AskForApproval?
	public var sandboxPolicy: SandboxPolicy?
	public var model: String?
	public var serviceTier: ServiceTier?
	public var effort: ReasoningEffort?
	public var summary: JSONValue?
	public var personality: Personality?
	public var outputSchema: JSONValue?
	public var collaborationMode: CollaborationMode?
}

public struct TurnInterruptParams: Sendable, Codable {
	public var threadId: String
	public var turnId: String
}

	// MARK: Responses

public struct TurnStartResponse: Sendable, Codable {
	public var turn: Turn
}

public struct TurnInterruptResponse: Sendable, Codable {
	public init() {}
}

	// MARK: Notifications

public struct TurnStartedNotification: Sendable, Codable {
	public var threadId: String
	public var turn: Turn
}

public struct TurnCompletedNotification: Sendable, Codable {
	public var threadId: String
	public var turn: Turn
}

	// MARK: Errors

public struct TurnError: Sendable, Codable, Equatable {
	public var message: String
	public var codexErrorInfo: JSONValue?
	public var additionalDetails: String?
}




