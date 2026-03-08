//
//  CodexClient+ServerNotificationTypes.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: Base Server Notification Type

public struct ErrorNotification: Sendable, Codable {
	public var error: TurnError
	public var willRetry: Bool
	public var threadId: String
	public var turnId: String
}

	// MARK: Account Notification Types
	// See `AuthCoordinator.swift`, `+AuthCoordinator+Types.swift` for related symbols.

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

	// MARK: Turn

	// MARK: Item

public struct ReasoningTextDeltaNotification: Sendable, Codable {
	public var threadId: String
	public var turnId: String
	public var itemId: String
	public var delta: String
	public var contentIndex: Int
}

	// MARK: Reserved for future use

	// MARK: Reserved for future use

	// MARK: Reserved for future use
