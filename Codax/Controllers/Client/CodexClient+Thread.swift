//
//  CodexClient+Thread.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: - Client Layer `Thread` Types

public typealias ThreadResumeResponse = ThreadStartResponse

	// MARK: Base Type

public struct Thread: Sendable, Codable {
	public var id: String
	public var preview: String
	public var ephemeral: Bool
	public var modelProvider: String
	public var createdAt: Int
	public var updatedAt: Int
	public var status: JSONValue
	public var path: String?
	public var cwd: String
	public var cliVersion: String
	public var source: JSONValue?
	public var agentNickname: String?
	public var agentRole: String?
	public var gitInfo: JSONValue?
	public var name: String?
	public var turns: [Turn]
}

	// MARK: Params

public struct ThreadStartParams: Sendable, Codable {
	public var model: String?
	public var modelProvider: String?
	public var serviceTier: ServiceTier?
	public var cwd: String?
	public var approvalPolicy: AskForApproval?
	public var sandbox: SandboxMode?
	public var config: [String: JSONValue]?
	public var serviceName: String?
	public var baseInstructions: String?
	public var developerInstructions: String?
	public var personality: Personality?
	public var ephemeral: Bool?
	public var experimentalRawEvents: Bool
	public var persistExtendedHistory: Bool
}

public struct ThreadResumeParams: Sendable, Codable {
	public var threadId: String
	public var history: [JSONValue]?
	public var path: String?
	public var model: String?
	public var modelProvider: String?
	public var serviceTier: ServiceTier?
	public var cwd: String?
	public var approvalPolicy: AskForApproval?
	public var sandbox: SandboxMode?
	public var config: [String: JSONValue]?
	public var baseInstructions: String?
	public var developerInstructions: String?
	public var personality: Personality?
	public var persistExtendedHistory: Bool
}

public struct ThreadReadParams: Sendable, Codable {
	public var threadId: String
	public var includeTurns: Bool
}

	// MARK: Responses

public struct ThreadStartResponse: Sendable, Codable {
	public var thread: Thread
	public var model: String
	public var modelProvider: String
	public var serviceTier: ServiceTier?
	public var cwd: String
	public var approvalPolicy: AskForApproval
	public var sandbox: SandboxPolicy
	public var reasoningEffort: ReasoningEffort?
}

public struct ThreadReadResponse: Sendable, Codable {
	public var thread: Thread
}

	// MARK: Notifications

public struct ThreadStartedNotification: Sendable, Codable {
	public var thread: Thread
}

	// MARK: Errors

