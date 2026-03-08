//
//  CodexClient+MCP.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: - Client Layer MCP Types

	// MARK: Base Type

	// MARK: Params

public struct McpServerElicitationRequestParams: Sendable, Codable {
	public var threadId: String
	public var turnId: String?
	public var serverName: String
	public var mode: String
	public var message: String
	public var requestedSchema: JSONValue?
	public var url: String?
	public var elicitationId: String?
}

	// MARK: Responses

	// MARK: Notifications

	// MARK: Errors
