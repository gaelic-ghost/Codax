//
//  CodexClient+ServerNotificationEnvelope.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

// MARK: - Client Layer Server Notification Envelope

public enum ServerNotificationEnvelope: Sendable {
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
	static func decode(method: String, params: Data, decoder: JSONDecoder) throws -> ServerNotificationEnvelope {
		switch method {
		case "error":
			return .error(try decoder.decode(ErrorNotification.self, from: params))
		case "serverRequest/resolved":
			return .serverRequestResolved(try decoder.decode(ServerRequestResolvedNotification.self, from: params))

		case "account/updated":
			return .accountUpdated(try decoder.decode(AccountUpdatedNotification.self, from: params))
		case "account/login/completed":
			return .accountLoginCompleted(try decoder.decode(AccountLoginCompletedNotification.self, from: params))

		case "thread/started":
			return .threadStarted(try decoder.decode(ThreadStartedNotification.self, from: params))
		case "thread/status/changed":
			return .threadStatusChanged(try decoder.decode(ThreadStatusChangedNotification.self, from: params))
		case "thread/tokenUsage/updated":
			return .threadTokenUsageUpdated(try decoder.decode(ThreadTokenUsageUpdatedNotification.self, from: params))

		case "turn/started":
			return .turnStarted(try decoder.decode(TurnStartedNotification.self, from: params))
		case "turn/completed":
			return .turnCompleted(try decoder.decode(TurnCompletedNotification.self, from: params))
		case "turn/diff/updated":
			return .turnDiffUpdated(try decoder.decode(TurnDiffUpdatedNotification.self, from: params))
		case "turn/plan/updated":
			return .turnPlanUpdated(try decoder.decode(TurnPlanUpdatedNotification.self, from: params))

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

		default:
			return .unknown(method: method, raw: params)
		}
	}
}
