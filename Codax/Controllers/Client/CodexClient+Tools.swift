//
//  CodexClient+Tools.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: - Client Layer Tool Types

	// MARK: Base Type

	// MARK: Params

public struct ToolRequestUserInputParams: Sendable, Codable {
	public var threadId: String
	public var turnId: String
	public var itemId: String
	public var questions: [ToolRequestUserInputQuestion]
}

public struct DynamicToolCallParams: Sendable, Codable {
	public var threadId: String
	public var turnId: String
	public var callId: String
	public var tool: String
	public var arguments: JSONValue
}

	// MARK: Responses

	// MARK: Notifications

	// MARK: Errors


public struct ToolRequestUserInputQuestion: Sendable, Codable {
	public var id: String
	public var header: String
	public var question: String
	public var isOther: Bool
	public var isSecret: Bool
	public var options: [JSONValue]?
}



public struct ToolRequestUserInputAnswer: Sendable, Codable {
	public var answers: [String]
}
