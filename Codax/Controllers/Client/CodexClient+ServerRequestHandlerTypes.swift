//
//  CodexClient+ServerRequestHandlerTypes.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: - Client Layer Server Request Handling Types

	// MARK: - Server Request Handler Protocol

public protocol CodexServerRequestHandler: Sendable {
	func handle(_ request: ServerRequestEnvelope) async -> ServerRequestResult
}

	// MARK: - Server Request Envelopes

nonisolated public enum ServerRequestEnvelope: Sendable {
		// MARK: Auth Refresh
	case chatgptAuthRefresh(ChatgptAuthTokensRefreshParams, id: JSONRPCID)
		// MARK: File Change/Apply Patch Approvals
	case fileChangeApproval(FileChangeRequestApprovalParams, id: JSONRPCID)
	case applyPatchApproval(ApplyPatchApprovalParams, id: JSONRPCID)
		// MARK: Tool Reqs/Approvals
	case userInput(ToolRequestUserInputParams, id: JSONRPCID)
	case dynamicToolCall(DynamicToolCallParams, id: JSONRPCID)
		// MARK: MCP Elicitation
	case mcpServerElicitation(McpServerElicitationRequestParams, id: JSONRPCID)
		// MARK: Command Approvals
	case commandApproval(CommandExecutionRequestApprovalParams, id: JSONRPCID)
	case execCommandApproval(ExecCommandApprovalParams, id: JSONRPCID)
		// MARK: DEFAULT
	case unknown(method: String, id: JSONRPCID, raw: Data)
}

extension ServerRequestEnvelope {
	nonisolated static func decode(method: String, id: JSONRPCID, params: Data, decoder: JSONDecoder) throws -> ServerRequestEnvelope {
		switch method {
					// MARK: Auth Refresh
			case "account/chatgptAuthTokens/refresh":
				return .chatgptAuthRefresh(try decoder.decode(ChatgptAuthTokensRefreshParams.self, from: params), id: id)
					// MARK: File Change/Apply Patch Approvals
			case "item/fileChange/requestApproval":
				return .fileChangeApproval(try decoder.decode(FileChangeRequestApprovalParams.self, from: params), id: id)
			case "applyPatchApproval":
				return .applyPatchApproval(try decoder.decode(ApplyPatchApprovalParams.self, from: params), id: id)
					// MARK: Tool Reqs/Approvals
			case "item/tool/requestUserInput":
				return .userInput(try decoder.decode(ToolRequestUserInputParams.self, from: params), id: id)
			case "item/tool/call":
				return .dynamicToolCall(try decoder.decode(DynamicToolCallParams.self, from: params), id: id)
			case "mcpServer/elicitation/request":
					// MARK: MCP Elicitation
				return .mcpServerElicitation(try decoder.decode(McpServerElicitationRequestParams.self, from: params), id: id)
					// MARK: Command Approvals
			case "item/commandExecution/requestApproval":
				return .commandApproval(try decoder.decode(CommandExecutionRequestApprovalParams.self, from: params), id: id)
			case "execCommandApproval":
				return .execCommandApproval(try decoder.decode(ExecCommandApprovalParams.self, from: params), id: id)
					// MARK: DEFAULT
			default:
				return .unknown(method: method, id: id, raw: params)
		}
	}

	nonisolated var id: JSONRPCID {
		switch self {
					// MARK: Auth Refresh
			case let .chatgptAuthRefresh(_, id),
					// MARK: File Change/Apply Patch Approvals
				let .fileChangeApproval(_, id),
				let .applyPatchApproval(_, id),
					// MARK: Tool Reqs/Approvals
				let .userInput(_, id),
				let .dynamicToolCall(_, id),
					// MARK: MCP Elicitation
				let .mcpServerElicitation(_, id),
					// MARK: Command Approvals
				let .commandApproval(_, id),
				let .execCommandApproval(_, id),
					// MARK: DEFAULT
				let .unknown(_, id, _):
				return id
		}
	}
}

	// MARK: - Server Request Types

	// MARK: Base Type

public enum ServerRequestResult: Sendable {
		// MARK: Auth Refresh
	case chatgptAuthRefresh(ChatgptAuthTokensRefreshResponse)
		// MARK: File Change/Apply Patch Approvals
	case fileChangeApproval(FileChangeRequestApprovalResponse)
	case applyPatchApproval(ApplyPatchApprovalResponse)
		// MARK: Tool Reqs/Approvals
	case userInput(ToolRequestUserInputResponse)
	case dynamicToolCall(DynamicToolCallResponse)
	case mcpServerElicitation(McpServerElicitationRequestResponse)
	case commandApproval(CommandExecutionRequestApprovalResponse)
	case execCommandApproval(ExecCommandApprovalResponse)
	case unhandled
}

	// MARK: Review Decision Types
	// Relevant for `ApplyPatchApprovalResponse`, `ExecCommandApprovalResponse`,

public enum ReviewDecision: Sendable, Codable {
	case approved
	case approvedForSession
	case denied
	case abort
	case custom(JSONValue)

	public init(from decoder: any Decoder) throws {
		let value = try JSONValue(from: decoder)
		switch value {
			case .string("approved"): self = .approved
			case .string("approved_for_session"): self = .approvedForSession
			case .string("denied"): self = .denied
			case .string("abort"): self = .abort
			default: self = .custom(value)
		}
	}

	public func encode(to encoder: any Encoder) throws {
		switch self {
			case .approved:
				try JSONValue.string("approved").encode(to: encoder)
			case .approvedForSession:
				try JSONValue.string("approved_for_session").encode(to: encoder)
			case .denied:
				try JSONValue.string("denied").encode(to: encoder)
			case .abort:
				try JSONValue.string("abort").encode(to: encoder)
			case let .custom(value):
				try value.encode(to: encoder)
		}
	}
}

	// MARK: Auth Refresh Types
	// Extracted to CodexClient+Account.swift

	// MARK: File Change & Apply Patch Approval Types

public struct FileChangeRequestApprovalResponse: Sendable, Codable {
	public var decision: FileChangeApprovalDecision
}

public enum FileChangeApprovalDecision: String, Sendable, Codable {
	case accept
	case acceptForSession
	case decline
	case cancel
}

public struct FileChangeRequestApprovalParams: Sendable, Codable {
	public var threadId: String
	public var turnId: String
	public var itemId: String
	public var reason: String?
	public var grantRoot: String?
}

public struct ApplyPatchApprovalResponse: Sendable, Codable {
	public var decision: ReviewDecision
}

public struct ApplyPatchApprovalParams: Sendable, Codable {
	public var conversationId: String
	public var callId: String
	public var fileChanges: [String: JSONValue]
	public var reason: String?
	public var grantRoot: String?
}

	// MARK: Tool Request/Approval Types

public struct ToolRequestUserInputResponse: Sendable, Codable {
	public var answers: [String: ToolRequestUserInputAnswer]
}

public struct ToolRequestUserInputAnswer: Sendable, Codable {
	public var answers: [String]
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

public struct DynamicToolCallParams: Sendable, Codable {
	public var threadId: String
	public var turnId: String
	public var callId: String
	public var tool: String
	public var arguments: JSONValue
}

public struct DynamicToolCallResponse: Sendable, Codable {
	public var contentItems: [DynamicToolCallOutputContentItem]
	public var success: Bool
}

	// MARK: MCP Elicitation Types

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

public struct McpServerElicitationRequestResponse: Sendable, Codable {
	public var action: McpServerElicitationAction
	public var content: JSONValue?
}

public enum McpServerElicitationAction: String, Sendable, Codable {
	case accept
	case decline
	case cancel
}

	// MARK: Command Approval Types

public struct CommandExecutionRequestApprovalResponse: Sendable, Codable {
	public var decision: CommandExecutionApprovalDecision
}

public enum CommandExecutionApprovalDecision: Sendable, Codable {
	case accept
	case acceptForSession
	case decline
	case cancel
	case custom(JSONValue)

	public init(from decoder: any Decoder) throws {
		let value = try JSONValue(from: decoder)
		switch value {
			case .string("accept"): self = .accept
			case .string("acceptForSession"): self = .acceptForSession
			case .string("decline"): self = .decline
			case .string("cancel"): self = .cancel
			default: self = .custom(value)
		}
	}

	public func encode(to encoder: any Encoder) throws {
		switch self {
			case .accept:
				try JSONValue.string("accept").encode(to: encoder)
			case .acceptForSession:
				try JSONValue.string("acceptForSession").encode(to: encoder)
			case .decline:
				try JSONValue.string("decline").encode(to: encoder)
			case .cancel:
				try JSONValue.string("cancel").encode(to: encoder)
			case let .custom(value):
				try value.encode(to: encoder)
		}
	}
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
public struct ExecCommandApprovalParams: Sendable, Codable {
	public var conversationId: String
	public var callId: String
	public var approvalId: String?
	public var command: [String]
	public var cwd: String
	public var reason: String?
	public var parsedCmd: [JSONValue]
}

public struct ExecCommandApprovalResponse: Sendable, Codable {
	public var decision: ReviewDecision
}

	// MARK: Reserved for future catagories

	// MARK: Reserved for future catagories

	// MARK: Reserved for future catagories



