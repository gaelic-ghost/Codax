//
//  CodexClient+ServerNotificationTypes.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

// MARK: Base

public struct ErrorNotification: Sendable, Codable {
	public var error: TurnError
	public var willRetry: Bool
	public var threadId: String
	public var turnId: String
}

public struct ServerRequestResolvedNotification: Sendable, Codable {
	public var threadId: String
	public var requestId: JSONRPCID
}

// MARK: Account
// See `AuthCoordinator.swift`, `AuthCoordinator+Types.swift` for related symbols.

public struct AccountUpdatedNotification: Sendable, Codable {
	public var authMode: AuthMode?
	public var planType: PlanType?
}

public struct AccountLoginCompletedNotification: Sendable, Codable {
	public var loginId: String?
	public var success: Bool
	public var error: String?
}

// MARK: Thread

public enum ThreadActiveFlag: String, Sendable, Codable {
	case waitingOnApproval
	case waitingOnUserInput
}

public enum ThreadStatus: Sendable, Codable {
	case notLoaded
	case idle
	case systemError
	case active(activeFlags: [ThreadActiveFlag])

	private enum CodingKeys: String, CodingKey {
		case type
		case activeFlags
	}

	private enum Kind: String, Codable {
		case notLoaded
		case idle
		case systemError
		case active
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		switch try container.decode(Kind.self, forKey: .type) {
		case .notLoaded:
			self = .notLoaded
		case .idle:
			self = .idle
		case .systemError:
			self = .systemError
		case .active:
			self = .active(activeFlags: try container.decode([ThreadActiveFlag].self, forKey: .activeFlags))
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case .notLoaded:
			try container.encode(Kind.notLoaded, forKey: .type)
		case .idle:
			try container.encode(Kind.idle, forKey: .type)
		case .systemError:
			try container.encode(Kind.systemError, forKey: .type)
		case let .active(activeFlags):
			try container.encode(Kind.active, forKey: .type)
			try container.encode(activeFlags, forKey: .activeFlags)
		}
	}
}

public struct ThreadStatusChangedNotification: Sendable, Codable {
	public var threadId: String
	public var status: ThreadStatus
}

public struct TokenUsageBreakdown: Sendable, Codable {
	public var totalTokens: Int
	public var inputTokens: Int
	public var cachedInputTokens: Int
	public var outputTokens: Int
	public var reasoningOutputTokens: Int
}

public struct ThreadTokenUsage: Sendable, Codable {
	public var total: TokenUsageBreakdown
	public var last: TokenUsageBreakdown
	public var modelContextWindow: Int?
}

public struct ThreadTokenUsageUpdatedNotification: Sendable, Codable {
	public var threadId: String
	public var turnId: String
	public var tokenUsage: ThreadTokenUsage
}

// MARK: Turn

public struct TurnDiffUpdatedNotification: Sendable, Codable {
	public var threadId: String
	public var turnId: String
	public var diff: String
}

public enum TurnPlanStepStatus: String, Sendable, Codable {
	case pending
	case inProgress
	case completed
}

public struct TurnPlanStep: Sendable, Codable {
	public var step: String
	public var status: TurnPlanStepStatus
}

public struct TurnPlanUpdatedNotification: Sendable, Codable {
	public var threadId: String
	public var turnId: String
	public var explanation: String?
	public var plan: [TurnPlanStep]
}

// MARK: Item

public struct AgentMessageDeltaNotification: Sendable, Codable {
	public var threadId: String
	public var turnId: String
	public var itemId: String
	public var delta: String
}

public struct CommandExecutionOutputDeltaNotification: Sendable, Codable {
	public var threadId: String
	public var turnId: String
	public var itemId: String
	public var delta: String
}

public struct FileChangeOutputDeltaNotification: Sendable, Codable {
	public var threadId: String
	public var turnId: String
	public var itemId: String
	public var delta: String
}

public struct ReasoningTextDeltaNotification: Sendable, Codable {
	public var threadId: String
	public var turnId: String
	public var itemId: String
	public var delta: String
	public var contentIndex: Int
}

public struct ReasoningSummaryTextDeltaNotification: Sendable, Codable {
	public var threadId: String
	public var turnId: String
	public var itemId: String
	public var delta: String
	public var summaryIndex: Int
}

public struct ReasoningSummaryPartAddedNotification: Sendable, Codable {
	public var threadId: String
	public var turnId: String
	public var itemId: String
	public var summaryIndex: Int
}
