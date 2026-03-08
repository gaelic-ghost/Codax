//
//  Client.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import Foundation

// MARK: - Client Layer Types

public typealias AskForApproval = JSONValue
public typealias SandboxMode = JSONValue
public typealias SandboxPolicy = JSONValue
public typealias Personality = JSONValue
public typealias CollaborationMode = JSONValue
public typealias ThreadItem = JSONValue
public typealias DynamicToolCallOutputContentItem = JSONValue
public typealias ServiceTier = String
public typealias ReasoningEffort = String
public typealias TurnStatus = String

public struct ClientInfo: Sendable, Codable {
	public var name: String
	public var title: String?
	public var version: String
}

public struct InitializeCapabilities: Sendable, Codable {
	public var experimentalApi: Bool
	public var optOutNotificationMethods: [String]?
}

public struct InitializeParams: Sendable, Codable {
	public var clientInfo: ClientInfo
	public var capabilities: InitializeCapabilities?
}

public struct InitializeResponse: Sendable, Codable {
	public var userAgent: String
}

public struct TurnError: Sendable, Codable {
	public var message: String
	public var codexErrorInfo: JSONValue?
	public var additionalDetails: String?
}

public struct Turn: Sendable, Codable {
	public var id: String
	public var items: [ThreadItem]
	public var status: TurnStatus
	public var error: TurnError?
}

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

public typealias ThreadResumeResponse = ThreadStartResponse

public struct ThreadReadParams: Sendable, Codable {
	public var threadId: String
	public var includeTurns: Bool
}

public struct ThreadReadResponse: Sendable, Codable {
	public var thread: Thread
}

public struct TurnStartParams: Sendable, Codable {
	public var threadId: String
	public var input: [JSONValue]
	public var cwd: String?
	public var approvalPolicy: AskForApproval?
	public var sandboxPolicy: SandboxPolicy?
	public var model: String?
	public var serviceTier: ServiceTier?
	public var effort: ReasoningEffort?
	public var summary: JSONValue?
	public var personality: Personality?
	public var outputSchema: JSONValue?
	public var collaborationMode: CollaborationMode?
}

public struct TurnStartResponse: Sendable, Codable {
	public var turn: Turn
}

public struct TurnInterruptParams: Sendable, Codable {
	public var threadId: String
	public var turnId: String
}

public struct TurnInterruptResponse: Sendable, Codable {
	public init() {}
}

public struct AccountUpdatedNotification: Sendable, Codable {
	public var authMode: AuthMode?
	public var planType: PlanType?
}

public struct ThreadStartedNotification: Sendable, Codable {
	public var thread: Thread
}

public struct TurnStartedNotification: Sendable, Codable {
	public var threadId: String
	public var turn: Turn
}

public struct TurnCompletedNotification: Sendable, Codable {
	public var threadId: String
	public var turn: Turn
}

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

public struct AccountLoginCompletedNotification: Sendable, Codable {
	public var loginId: String?
	public var success: Bool
	public var error: String?
}

public struct ReasoningTextDeltaNotification: Sendable, Codable {
	public var threadId: String
	public var turnId: String
	public var itemId: String
	public var delta: String
	public var contentIndex: Int
}

public struct ErrorNotification: Sendable, Codable {
	public var error: TurnError
	public var willRetry: Bool
	public var threadId: String
	public var turnId: String
}

public struct CommandExecutionRequestApprovalParams: Sendable, Codable {
	public var threadId: String
	public var turnId: String
	public var itemId: String
	public var approvalId: String?
	public var reason: String?
	public var command: String?
	public var cwd: String?
	public var commandActions: [JSONValue]?
	public var additionalPermissions: JSONValue?
	public var proposedExecpolicyAmendment: JSONValue?
	public var proposedNetworkPolicyAmendments: [JSONValue]?
	public var availableDecisions: [JSONValue]?
}

public struct FileChangeRequestApprovalParams: Sendable, Codable {
	public var threadId: String
	public var turnId: String
	public var itemId: String
	public var reason: String?
	public var grantRoot: String?
}

public struct ToolRequestUserInputQuestion: Sendable, Codable {
	public var id: String
	public var header: String
	public var question: String
	public var isOther: Bool
	public var isSecret: Bool
	public var options: [JSONValue]?
}

public struct ToolRequestUserInputParams: Sendable, Codable {
	public var threadId: String
	public var turnId: String
	public var itemId: String
	public var questions: [ToolRequestUserInputQuestion]
}

public struct ToolRequestUserInputAnswer: Sendable, Codable {
	public var answers: [String]
}

public struct DynamicToolCallParams: Sendable, Codable {
	public var threadId: String
	public var turnId: String
	public var callId: String
	public var tool: String
	public var arguments: JSONValue
}

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

public struct ApplyPatchApprovalParams: Sendable, Codable {
	public var conversationId: String
	public var callId: String
	public var fileChanges: [String: JSONValue]
	public var reason: String?
	public var grantRoot: String?
}

public struct ExecCommandApprovalParams: Sendable, Codable {
	public var conversationId: String
	public var callId: String
	public var approvalId: String?
	public var command: [String]
	public var cwd: String
	public var reason: String?
	public var parsedCmd: [JSONValue]
}
