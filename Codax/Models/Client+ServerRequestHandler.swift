//
//  Client+ServerRequestHandler.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import Foundation

// MARK: - Client Layer Server Request Handling Types

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

public enum FileChangeApprovalDecision: String, Sendable, Codable {
	case accept
	case acceptForSession
	case decline
	case cancel
}

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

public enum McpServerElicitationAction: String, Sendable, Codable {
	case accept
	case decline
	case cancel
}

public struct CommandExecutionRequestApprovalResponse: Sendable, Codable {
	public var decision: CommandExecutionApprovalDecision
}

public struct FileChangeRequestApprovalResponse: Sendable, Codable {
	public var decision: FileChangeApprovalDecision
}

public struct ToolRequestUserInputResponse: Sendable, Codable {
	public var answers: [String: ToolRequestUserInputAnswer]
}

public struct DynamicToolCallResponse: Sendable, Codable {
	public var contentItems: [DynamicToolCallOutputContentItem]
	public var success: Bool
}

public struct McpServerElicitationRequestResponse: Sendable, Codable {
	public var action: McpServerElicitationAction
	public var content: JSONValue?
}

public struct ApplyPatchApprovalResponse: Sendable, Codable {
	public var decision: ReviewDecision
}

public struct ExecCommandApprovalResponse: Sendable, Codable {
	public var decision: ReviewDecision
}

public enum ServerRequestResult: Sendable {
	case commandApproval(CommandExecutionRequestApprovalResponse)
	case fileChangeApproval(FileChangeRequestApprovalResponse)
	case userInput(ToolRequestUserInputResponse)
	case mcpServerElicitation(McpServerElicitationRequestResponse)
	case dynamicToolCall(DynamicToolCallResponse)
	case chatgptAuthRefresh(ChatgptAuthTokensRefreshResponse)
	case applyPatchApproval(ApplyPatchApprovalResponse)
	case execCommandApproval(ExecCommandApprovalResponse)
	case unhandled
}
