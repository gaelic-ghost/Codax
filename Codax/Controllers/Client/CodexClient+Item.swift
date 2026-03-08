//
//  CodexClient+Item.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: - Client Layer Item Types

	// MARK: Base Type

	// MARK: Params

	// MARK: Responses

	// MARK: Notifications

public struct ItemStartedNotification: Sendable, Codable {
	public var item: ThreadItem
	public var threadId: String
	public var turnId: String
}

public struct ItemCompletedNotification: Sendable, Codable {
	public var item: ThreadItem
	public var threadId: String
	public var turnId: String
}

	// MARK: Errors
