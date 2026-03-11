//
//  CodexClient+ServerNotificationTypes.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: - Client Layer Server Notification Types

	// MARK: Server Notification Envelopes

nonisolated public enum ServerNotificationEnvelope: Sendable {
		// MARK: Base
	case error(ErrorNotification)
	case serverRequestResolved(ServerRequestResolvedNotification)

		// MARK: Account
	case accountUpdated(AccountUpdatedNotification)
	case accountLoginCompleted(AccountLoginCompletedNotification)

		// MARK: Thread
	case threadStarted(ThreadStartedNotification)
	case threadStatusChanged(ThreadStatusChangedNotification)
	case threadTokenUsageUpdated(ThreadTokenUsageUpdatedNotification)

		// MARK: Turn
	case turnStarted(TurnStartedNotification)
	case turnCompleted(TurnCompletedNotification)
	case turnDiffUpdated(TurnDiffUpdatedNotification)
	case turnPlanUpdated(TurnPlanUpdatedNotification)

		// MARK: Item
	case itemStarted(ItemStartedNotification)
	case itemCompleted(ItemCompletedNotification)
	case agentMessageDelta(AgentMessageDeltaNotification)
	case commandExecutionOutputDelta(CommandExecutionOutputDeltaNotification)
	case fileChangeOutputDelta(FileChangeOutputDeltaNotification)
	case reasoningTextDelta(ReasoningTextDeltaNotification)
	case reasoningSummaryTextDelta(ReasoningSummaryTextDeltaNotification)
	case reasoningSummaryPartAdded(ReasoningSummaryPartAddedNotification)

		// MARK: Default
	case unknown(method: String, raw: Data)
}

extension ServerNotificationEnvelope {
	nonisolated static func decode(method: String, params: Data, decoder: JSONDecoder) throws -> ServerNotificationEnvelope {
		switch method {
					// MARK: Base
			case "error":
				return .error(try decoder.decode(ErrorNotification.self, from: params))
			case "serverRequest/resolved":
				return .serverRequestResolved(try decoder.decode(ServerRequestResolvedNotification.self, from: params))
					// MARK: Account
			case "account/updated":
				return .accountUpdated(try decoder.decode(AccountUpdatedNotification.self, from: params))
			case "account/login/completed":
				return .accountLoginCompleted(try decoder.decode(AccountLoginCompletedNotification.self, from: params))
					// MARK: Thread
			case "thread/started":
				return .threadStarted(try decoder.decode(ThreadStartedNotification.self, from: params))
			case "thread/status/changed":
				return .threadStatusChanged(try decoder.decode(ThreadStatusChangedNotification.self, from: params))
			case "thread/tokenUsage/updated":
				return .threadTokenUsageUpdated(try decoder.decode(ThreadTokenUsageUpdatedNotification.self, from: params))
					// MARK: Turn
			case "turn/started":
				return .turnStarted(try decoder.decode(TurnStartedNotification.self, from: params))
			case "turn/completed":
				return .turnCompleted(try decoder.decode(TurnCompletedNotification.self, from: params))
			case "turn/diff/updated":
				return .turnDiffUpdated(try decoder.decode(TurnDiffUpdatedNotification.self, from: params))
			case "turn/plan/updated":
				return .turnPlanUpdated(try decoder.decode(TurnPlanUpdatedNotification.self, from: params))
					// MARK: Item
			case "item/started":
				return .itemStarted(try decoder.decode(ItemStartedNotification.self, from: params))
			case "item/completed":
				return .itemCompleted(try decoder.decode(ItemCompletedNotification.self, from: params))
			case "item/agentMessage/delta":
				return .agentMessageDelta(try decoder.decode(AgentMessageDeltaNotification.self, from: params))
			case "item/commandExecution/outputDelta":
				return .commandExecutionOutputDelta(try decoder.decode(CommandExecutionOutputDeltaNotification.self, from: params))
			case "item/fileChange/outputDelta":
				return .fileChangeOutputDelta(try decoder.decode(FileChangeOutputDeltaNotification.self, from: params))
			case "item/reasoning/textDelta":
				return .reasoningTextDelta(try decoder.decode(ReasoningTextDeltaNotification.self, from: params))
			case "item/reasoning/summaryTextDelta":
				return .reasoningSummaryTextDelta(try decoder.decode(ReasoningSummaryTextDeltaNotification.self, from: params))
			case "item/reasoning/summaryPartAdded":
				return .reasoningSummaryPartAdded(try decoder.decode(ReasoningSummaryPartAddedNotification.self, from: params))
					// MARK: DEFAULT
			default:
				return .unknown(method: method, raw: params)
		}
	}
}

// MARK: Server Notification Types

// MARK: Base

public struct ErrorNotification: Sendable, Codable {
	public var error: TurnError
	public var willRetry: Bool
	public var threadCodexId: String
	public var turnCodexId: String

	private enum CodingKeys: String, CodingKey {
		case error
		case willRetry
		case threadCodexId = "threadId"
		case turnCodexId = "turnId"
	}
}

public struct ServerRequestResolvedNotification: Sendable, Codable {
	public var threadCodexId: String
	public var requestId: JSONRPCID

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case requestId
	}
}

// MARK: Account

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

public enum ThreadActiveFlag: String, Sendable, Codable, Equatable {
	case waitingOnApproval
	case waitingOnUserInput
}

public enum ThreadStatus: Sendable, Codable, Equatable, Hashable {
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
		let (kind, container) = try CodexCoding.decodeTaggedKind(
			from: decoder,
			codingKeys: CodingKeys.self,
			typeKey: .type,
			kindType: Kind.self,
			typeName: "ThreadStatus"
		)
		switch kind {
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

	// MARK: Thread

public struct ThreadStatusChangedNotification: Sendable, Codable {
	public var threadCodexId: String
	public var status: ThreadStatus

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case status
	}
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
	public var threadCodexId: String
	public var turnCodexId: String
	public var tokenUsage: ThreadTokenUsage

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case turnCodexId = "turnId"
		case tokenUsage
	}
}

// MARK: Turn

public struct TurnDiffUpdatedNotification: Sendable, Codable {
	public var threadCodexId: String
	public var turnCodexId: String
	public var diff: String

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case turnCodexId = "turnId"
		case diff
	}
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
	public var threadCodexId: String
	public var turnCodexId: String
	public var explanation: String?
	public var plan: [TurnPlanStep]

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case turnCodexId = "turnId"
		case explanation
		case plan
	}
}

// MARK: Item

public struct AgentMessageDeltaNotification: Sendable, Codable {
	public var threadCodexId: String
	public var turnCodexId: String
	public var itemCodexId: String
	public var delta: String

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case turnCodexId = "turnId"
		case itemCodexId = "itemId"
		case delta
	}
}

public struct CommandExecutionOutputDeltaNotification: Sendable, Codable {
	public var threadCodexId: String
	public var turnCodexId: String
	public var itemCodexId: String
	public var delta: String

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case turnCodexId = "turnId"
		case itemCodexId = "itemId"
		case delta
	}
}

public struct FileChangeOutputDeltaNotification: Sendable, Codable {
	public var threadCodexId: String
	public var turnCodexId: String
	public var itemCodexId: String
	public var delta: String

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case turnCodexId = "turnId"
		case itemCodexId = "itemId"
		case delta
	}
}

public struct ReasoningTextDeltaNotification: Sendable, Codable {
	public var threadCodexId: String
	public var turnCodexId: String
	public var itemCodexId: String
	public var delta: String
	public var contentIndex: Int

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case turnCodexId = "turnId"
		case itemCodexId = "itemId"
		case delta
		case contentIndex
	}
}

public struct ReasoningSummaryTextDeltaNotification: Sendable, Codable {
	public var threadCodexId: String
	public var turnCodexId: String
	public var itemCodexId: String
	public var delta: String
	public var summaryIndex: Int

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case turnCodexId = "turnId"
		case itemCodexId = "itemId"
		case delta
		case summaryIndex
	}
}

public struct ReasoningSummaryPartAddedNotification: Sendable, Codable {
	public var threadCodexId: String
	public var turnCodexId: String
	public var itemCodexId: String
	public var summaryIndex: Int

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case turnCodexId = "turnId"
		case itemCodexId = "itemId"
		case summaryIndex
	}
}
