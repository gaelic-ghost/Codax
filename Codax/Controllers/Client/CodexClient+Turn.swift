//
//  CodexClient+Turn.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: - Client Layer `Turn` Types

	// MARK: Base Types

public struct Turn: Identifiable, Sendable, Codable, Equatable, Hashable {
	public var id: UUID
	public var codexId: String
	/// The app-server currently leaves this empty on `turn/started` and `turn/completed`.
	/// Treat live `item/*` notifications as the canonical item stream.
	public var items: [ThreadItem]
	public var status: TurnStatus
	public var error: TurnError?

	private enum CodingKeys: String, CodingKey {
		case codexId = "id"
		case items
		case status
		case error
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let codexId = try container.decode(String.self, forKey: .codexId)
		self.id = ClientIdentity.turn(codexId)
		self.codexId = codexId
		self.items = try container.decode([ThreadItem].self, forKey: .items)
		self.status = try container.decode(TurnStatus.self, forKey: .status)
		self.error = try container.decodeIfPresent(TurnError.self, forKey: .error)
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(codexId, forKey: .codexId)
		try container.encode(items, forKey: .items)
		try container.encode(status, forKey: .status)
		try container.encode(error, forKey: .error)
	}
}

	// MARK: Params

public struct TurnStartParams: Sendable, Codable {
	public var threadCodexId: String
	public var input: [UserInput]
	public var cwd: String?
	public var approvalPolicy: AskForApproval?
	public var sandboxPolicy: SandboxPolicy?
	public var model: String?
	public var serviceTier: ServiceTier?
	public var effort: ReasoningEffort?
	public var summary: ReasoningSummary?
	public var personality: Personality?
	public var outputSchema: CodexValue?
	public var collaborationMode: CollaborationMode?

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case input
		case cwd
		case approvalPolicy
		case sandboxPolicy
		case model
		case serviceTier
		case effort
		case summary
		case personality
		case outputSchema
		case collaborationMode
	}
}

public struct TurnInterruptParams: Sendable, Codable {
	public var threadCodexId: String
	public var turnCodexId: String

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case turnCodexId = "turnId"
	}
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
	public var threadCodexId: String
	public var turn: Turn

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case turn
	}
}

public struct TurnCompletedNotification: Sendable, Codable {
	public var threadCodexId: String
	public var turn: Turn

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case turn
	}
}

	// MARK: Errors

public struct TurnError: Sendable, Codable, Equatable, Hashable {
	public var message: String
	public var codexErrorInfo: CodexErrorInfo?
	public var additionalDetails: String?
}

	// MARK: Other

public enum TurnStatus: String, Sendable, Codable, Equatable {
	case completed
	case interrupted
	case failed
	case inProgress
}

public enum ReasoningSummary: String, Sendable, Codable, Equatable, Hashable {
	case auto
	case concise
	case detailed
	case none
}


