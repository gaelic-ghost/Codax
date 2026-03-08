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
		// MARK: Account
	case accountUpdated(AccountUpdatedNotification)
	case accountLoginCompleted(AccountLoginCompletedNotification)
		// MARK: Thread
	case threadStarted(ThreadStartedNotification)
		// MARK: Turn
	case turnStarted(TurnStartedNotification)
	case turnCompleted(TurnCompletedNotification)
		// MARK: Item
	case itemStarted(ItemStartedNotification)
	case itemCompleted(ItemCompletedNotification)
	case reasoningTextDelta(ReasoningTextDeltaNotification)
		// MARK: DEFAULT
	case unknown(method: String, raw: Data)
}

extension ServerNotificationEnvelope {
	static func decode(method: String, params: Data, decoder: JSONDecoder) throws -> ServerNotificationEnvelope {
		switch method {
					// MARK: Base

			case "error":
				return .error(try decoder.decode(ErrorNotification.self, from: params))
					// MARK: Account
			case "account/updated":
				return .accountUpdated(try decoder.decode(AccountUpdatedNotification.self, from: params))
			case "account/login/completed":
				return .accountLoginCompleted(try decoder.decode(AccountLoginCompletedNotification.self, from: params))
					// MARK: Thread
			case "thread/started":
				return .threadStarted(try decoder.decode(ThreadStartedNotification.self, from: params))
					// MARK: Turn
			case "turn/started":
				return .turnStarted(try decoder.decode(TurnStartedNotification.self, from: params))
			case "turn/completed":
				return .turnCompleted(try decoder.decode(TurnCompletedNotification.self, from: params))
					// MARK: Item
			case "item/started":
				return .itemStarted(try decoder.decode(ItemStartedNotification.self, from: params))
			case "item/completed":
				return .itemCompleted(try decoder.decode(ItemCompletedNotification.self, from: params))
			case "item/reasoning/textDelta":
				return .reasoningTextDelta(try decoder.decode(ReasoningTextDeltaNotification.self, from: params))
				// MARK: DEFAULT
			default:
				return .unknown(method: method, raw: params)
		}
	}
}
