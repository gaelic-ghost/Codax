//
//  CodexClient+ServerNotificationEnvelope.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: - Client Layer Server Notification Envelope

public enum ServerNotificationEnvelope: Sendable {
	case error(ErrorNotification)
	case threadStarted(ThreadStartedNotification)
	case turnStarted(TurnStartedNotification)
	case turnCompleted(TurnCompletedNotification)
	case itemStarted(ItemStartedNotification)
	case itemCompleted(ItemCompletedNotification)
	case accountUpdated(AccountUpdatedNotification)
	case accountLoginCompleted(AccountLoginCompletedNotification)
	case reasoningTextDelta(ReasoningTextDeltaNotification)
	case unknown(method: String, raw: Data)
}

extension ServerNotificationEnvelope {
	static func decode(method: String, params: Data, decoder: JSONDecoder) throws -> ServerNotificationEnvelope {
		switch method {
			case "error":
				return .error(try decoder.decode(ErrorNotification.self, from: params))
			case "thread/started":
				return .threadStarted(try decoder.decode(ThreadStartedNotification.self, from: params))
			case "turn/started":
				return .turnStarted(try decoder.decode(TurnStartedNotification.self, from: params))
			case "turn/completed":
				return .turnCompleted(try decoder.decode(TurnCompletedNotification.self, from: params))
			case "item/started":
				return .itemStarted(try decoder.decode(ItemStartedNotification.self, from: params))
			case "item/completed":
				return .itemCompleted(try decoder.decode(ItemCompletedNotification.self, from: params))
			case "account/updated":
				return .accountUpdated(try decoder.decode(AccountUpdatedNotification.self, from: params))
			case "account/login/completed":
				return .accountLoginCompleted(try decoder.decode(AccountLoginCompletedNotification.self, from: params))
			case "item/reasoning/textDelta":
				return .reasoningTextDelta(try decoder.decode(ReasoningTextDeltaNotification.self, from: params))
			default:
				return .unknown(method: method, raw: params)
		}
	}
}
