//
//  CodexClient+ServerRequestTypes.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

// MARK: - Client Layer Server Request Types

public protocol CodexServerRequestResponder: Sendable {
	func handle(_ request: ServerRequestEnvelope) async -> ServerRequestResponse
}

nonisolated public enum ServerRequestEnvelope: Sendable {
	case chatgptAuthRefresh(ChatgptAuthTokensRefreshParams, id: JSONRPCID)
	case fileChangeApproval(FileChangeRequestApprovalParams, id: JSONRPCID)
	case applyPatchApproval(ApplyPatchApprovalParams, id: JSONRPCID)
	case userInput(ToolRequestUserInputParams, id: JSONRPCID)
	case dynamicToolCall(DynamicToolCallParams, id: JSONRPCID)
	case mcpServerElicitation(McpServerElicitationRequestParams, id: JSONRPCID)
	case commandApproval(CommandExecutionRequestApprovalParams, id: JSONRPCID)
	case execCommandApproval(ExecCommandApprovalParams, id: JSONRPCID)
	case unknown(method: String, id: JSONRPCID, raw: Data)
}

extension ServerRequestEnvelope {
	nonisolated static func decode(method: String, id: JSONRPCID, params: Data, decoder: JSONDecoder) throws -> ServerRequestEnvelope {
		switch method {
		case "account/chatgptAuthTokens/refresh":
			return .chatgptAuthRefresh(try decoder.decode(ChatgptAuthTokensRefreshParams.self, from: params), id: id)
		case "item/fileChange/requestApproval":
			return .fileChangeApproval(try decoder.decode(FileChangeRequestApprovalParams.self, from: params), id: id)
		case "applyPatchApproval":
			return .applyPatchApproval(try decoder.decode(ApplyPatchApprovalParams.self, from: params), id: id)
		case "item/tool/requestUserInput":
			return .userInput(try decoder.decode(ToolRequestUserInputParams.self, from: params), id: id)
		case "item/tool/call":
			return .dynamicToolCall(try decoder.decode(DynamicToolCallParams.self, from: params), id: id)
		case "mcpServer/elicitation/request":
			return .mcpServerElicitation(try decoder.decode(McpServerElicitationRequestParams.self, from: params), id: id)
		case "item/commandExecution/requestApproval":
			return .commandApproval(try decoder.decode(CommandExecutionRequestApprovalParams.self, from: params), id: id)
		case "execCommandApproval":
			return .execCommandApproval(try decoder.decode(ExecCommandApprovalParams.self, from: params), id: id)
		default:
			return .unknown(method: method, id: id, raw: params)
		}
	}

	nonisolated var id: JSONRPCID {
		switch self {
		case let .chatgptAuthRefresh(_, id),
			let .fileChangeApproval(_, id),
			let .applyPatchApproval(_, id),
			let .userInput(_, id),
			let .dynamicToolCall(_, id),
			let .mcpServerElicitation(_, id),
			let .commandApproval(_, id),
			let .execCommandApproval(_, id),
			let .unknown(_, id, _):
			return id
		}
	}
}

public enum ServerRequestResponse: Sendable {
	case chatgptAuthRefresh(ChatgptAuthTokensRefreshResponse)
	case fileChangeApproval(FileChangeRequestApprovalResponse)
	case applyPatchApproval(ApplyPatchApprovalResponse)
	case userInput(ToolRequestUserInputResponse)
	case dynamicToolCall(DynamicToolCallResponse)
	case mcpServerElicitation(McpServerElicitationRequestResponse)
	case commandApproval(CommandExecutionRequestApprovalResponse)
	case execCommandApproval(ExecCommandApprovalResponse)
	case unhandled
}

// MARK: Auth Types

public struct ChatgptAuthTokensRefreshParams: Sendable, Codable {
	public var reason: String
	public var previousAccountId: String?
}

public struct ChatgptAuthTokensRefreshResponse: Sendable, Codable {
	public var accessToken: String
	public var chatgptAccountId: String
	public var chatgptPlanType: String?
}

public enum ReviewDecision: Sendable, Codable, Equatable, Hashable {
	case approved
	case approvedExecPolicyAmendment(ExecPolicyAmendment)
	case approvedForSession
	case networkPolicyAmendment(NetworkPolicyAmendment)
	case denied
	case abort

	private enum CodingKeys: String, CodingKey {
		case approvedExecPolicyAmendment = "approved_execpolicy_amendment"
		case networkPolicyAmendment = "network_policy_amendment"
		case proposedExecPolicyAmendment = "proposed_execpolicy_amendment"
	}

	private struct ApprovedExecPolicyPayload: Codable, Equatable, Hashable, Sendable {
		var proposedExecPolicyAmendment: ExecPolicyAmendment

		private enum CodingKeys: String, CodingKey {
			case proposedExecPolicyAmendment = "proposed_execpolicy_amendment"
		}
	}

	private struct NetworkPolicyPayload: Codable, Equatable, Hashable, Sendable {
		var networkPolicyAmendment: NetworkPolicyAmendment

		private enum CodingKeys: String, CodingKey {
			case networkPolicyAmendment = "network_policy_amendment"
		}
	}

	public init(from decoder: any Decoder) throws {
		self = try CodexCoding.decodeStringOrObject(
			from: decoder,
			typeName: "ReviewDecision",
			stringMapping: [
				"approved": .approved,
				"approved_for_session": .approvedForSession,
				"denied": .denied,
				"abort": .abort,
			]
		) { (_: KeyedDecodingContainer<CodingKeys>) in
			try CodexCoding.decodeKeyedOneOf(
				from: decoder,
				typeName: "ReviewDecision",
				tries: [
					(CodingKeys.approvedExecPolicyAmendment, { (container: KeyedDecodingContainer<CodingKeys>) in
						let payload = try container.decode(ApprovedExecPolicyPayload.self, forKey: .approvedExecPolicyAmendment)
						return .approvedExecPolicyAmendment(payload.proposedExecPolicyAmendment)
					}),
					(CodingKeys.networkPolicyAmendment, { (container: KeyedDecodingContainer<CodingKeys>) in
						let payload = try container.decode(NetworkPolicyPayload.self, forKey: .networkPolicyAmendment)
						return .networkPolicyAmendment(payload.networkPolicyAmendment)
					}),
				]
			)
		}
	}

	public func encode(to encoder: any Encoder) throws {
		switch self {
		case .approved:
			try CodexCoding.encodeStringValue("approved", to: encoder)
		case let .approvedExecPolicyAmendment(amendment):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(
				ApprovedExecPolicyPayload(proposedExecPolicyAmendment: amendment),
				forKey: .approvedExecPolicyAmendment
			)
		case .approvedForSession:
			try CodexCoding.encodeStringValue("approved_for_session", to: encoder)
		case let .networkPolicyAmendment(amendment):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(
				NetworkPolicyPayload(networkPolicyAmendment: amendment),
				forKey: .networkPolicyAmendment
			)
		case .denied:
			try CodexCoding.encodeStringValue("denied", to: encoder)
		case .abort:
			try CodexCoding.encodeStringValue("abort", to: encoder)
		}
	}
}

// MARK: File Change Types

public struct FileChangeRequestApprovalResponse: Sendable, Codable, Equatable, Hashable {
	public var decision: FileChangeApprovalDecision
}

public enum FileChangeApprovalDecision: String, Sendable, Codable, Equatable, Hashable {
	case accept
	case acceptForSession
	case decline
	case cancel
}

public struct FileChangeRequestApprovalParams: Sendable, Codable, Equatable, Hashable {
	public var threadCodexId: String
	public var turnCodexId: String
	public var itemCodexId: String
	public var reason: String?
	public var grantRoot: String?

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case turnCodexId = "turnId"
		case itemCodexId = "itemId"
		case reason
		case grantRoot
	}
}

// MARK: Apply Patch Types

public struct ApplyPatchApprovalResponse: Sendable, Codable, Equatable, Hashable {
	public var decision: ReviewDecision
}

public struct ApplyPatchApprovalParams: Sendable, Codable, Equatable, Hashable {
	public var conversationCodexId: String
	public var callId: String
	public var fileChanges: [String: FileChange]
	public var reason: String?
	public var grantRoot: String?

	private enum CodingKeys: String, CodingKey {
		case conversationCodexId = "conversationId"
		case callId
		case fileChanges
		case reason
		case grantRoot
	}
}

// MARK: Tool Request Types

public struct ToolRequestUserInputResponse: Sendable, Codable, Equatable, Hashable {
	public var answers: [String: ToolRequestUserInputAnswer]
}

public struct ToolRequestUserInputAnswer: Sendable, Codable, Equatable, Hashable {
	public var answers: [String]
}

public struct ToolRequestUserInputQuestion: Sendable, Codable, Equatable, Hashable {
	public var id: String
	public var header: String
	public var question: String
	public var isOther: Bool
	public var isSecret: Bool
	public var options: [ToolRequestUserInputOption]?
}

public struct ToolRequestUserInputParams: Sendable, Codable, Equatable, Hashable {
	public var threadCodexId: String
	public var turnCodexId: String
	public var itemCodexId: String
	public var questions: [ToolRequestUserInputQuestion]

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case turnCodexId = "turnId"
		case itemCodexId = "itemId"
		case questions
	}
}

public struct DynamicToolCallParams: Sendable, Codable, Equatable, Hashable {
	public var threadCodexId: String
	public var turnCodexId: String
	public var callId: String
	public var tool: String
	public var arguments: CodexValue

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case turnCodexId = "turnId"
		case callId
		case tool
		case arguments
	}
}

public struct DynamicToolCallResponse: Sendable, Codable, Equatable, Hashable {
	public var contentItems: [DynamicToolCallOutputContentItem]
	public var success: Bool
}

// MARK: MCP Types

public enum McpServerElicitationMode: String, Sendable, Codable, Equatable, Hashable {
	case form
	case url
}

public struct McpServerElicitationRequestParams: Sendable, Codable, Equatable, Hashable {
	public var threadCodexId: String
	public var turnCodexId: String?
	public var serverName: String
	public var mode: McpServerElicitationMode
	public var message: String
	public var requestedSchema: CodexValue?
	public var url: String?
	public var elicitationId: String?

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case turnCodexId = "turnId"
		case serverName
		case mode
		case message
		case requestedSchema
		case url
		case elicitationId
	}
}

public struct McpServerElicitationRequestResponse: Sendable, Codable, Equatable, Hashable {
	public var action: McpServerElicitationAction
	public var content: CodexValue?
}

public enum McpServerElicitationAction: String, Sendable, Codable, Equatable, Hashable {
	case accept
	case decline
	case cancel
}

// MARK: Command Types

public struct CommandExecutionRequestApprovalResponse: Sendable, Codable, Equatable, Hashable {
	public var decision: CommandExecutionApprovalDecision
}

public enum CommandExecutionApprovalDecision: Sendable, Codable, Equatable, Hashable {
	case accept
	case acceptForSession
	case acceptWithExecPolicyAmendment(ExecPolicyAmendment)
	case applyNetworkPolicyAmendment(NetworkPolicyAmendment)
	case decline
	case cancel

	private enum CodingKeys: String, CodingKey {
		case acceptWithExecPolicyAmendment = "acceptWithExecpolicyAmendment"
		case applyNetworkPolicyAmendment
		case execPolicyAmendment = "execpolicy_amendment"
		case networkPolicyAmendment = "network_policy_amendment"
	}

	private struct ExecPolicyPayload: Codable, Equatable, Hashable, Sendable {
		var execPolicyAmendment: ExecPolicyAmendment

		private enum CodingKeys: String, CodingKey {
			case execPolicyAmendment = "execpolicy_amendment"
		}
	}

	private struct NetworkPolicyPayload: Codable, Equatable, Hashable, Sendable {
		var networkPolicyAmendment: NetworkPolicyAmendment

		private enum CodingKeys: String, CodingKey {
			case networkPolicyAmendment = "network_policy_amendment"
		}
	}

	public init(from decoder: any Decoder) throws {
		self = try CodexCoding.decodeStringOrObject(
			from: decoder,
			typeName: "CommandExecutionApprovalDecision",
			stringMapping: [
				"accept": .accept,
				"acceptForSession": .acceptForSession,
				"decline": .decline,
				"cancel": .cancel,
			]
		) { (_: KeyedDecodingContainer<CodingKeys>) in
			try CodexCoding.decodeKeyedOneOf(
				from: decoder,
				typeName: "CommandExecutionApprovalDecision",
				tries: [
					(CodingKeys.acceptWithExecPolicyAmendment, { (container: KeyedDecodingContainer<CodingKeys>) in
						let payload = try container.decode(ExecPolicyPayload.self, forKey: .acceptWithExecPolicyAmendment)
						return .acceptWithExecPolicyAmendment(payload.execPolicyAmendment)
					}),
					(CodingKeys.applyNetworkPolicyAmendment, { (container: KeyedDecodingContainer<CodingKeys>) in
						let payload = try container.decode(NetworkPolicyPayload.self, forKey: .applyNetworkPolicyAmendment)
						return .applyNetworkPolicyAmendment(payload.networkPolicyAmendment)
					}),
				]
			)
		}
	}

	public func encode(to encoder: any Encoder) throws {
		switch self {
		case .accept:
			try CodexCoding.encodeStringValue("accept", to: encoder)
		case .acceptForSession:
			try CodexCoding.encodeStringValue("acceptForSession", to: encoder)
		case let .acceptWithExecPolicyAmendment(amendment):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(ExecPolicyPayload(execPolicyAmendment: amendment), forKey: .acceptWithExecPolicyAmendment)
		case let .applyNetworkPolicyAmendment(amendment):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(NetworkPolicyPayload(networkPolicyAmendment: amendment), forKey: .applyNetworkPolicyAmendment)
		case .decline:
			try CodexCoding.encodeStringValue("decline", to: encoder)
		case .cancel:
			try CodexCoding.encodeStringValue("cancel", to: encoder)
		}
	}
}

public struct CommandExecutionRequestApprovalParams: Sendable, Codable, Equatable, Hashable {
	public var threadCodexId: String
	public var turnCodexId: String
	public var itemCodexId: String
	public var approvalId: String?
	public var reason: String?
	public var command: String?
	public var cwd: String?
	public var commandActions: [CommandAction]?
	public var additionalPermissions: AdditionalPermissionProfile?
	public var proposedExecPolicyAmendment: ExecPolicyAmendment?
	public var proposedNetworkPolicyAmendments: [NetworkPolicyAmendment]?
	public var availableDecisions: [CommandExecutionApprovalDecision]?

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case turnCodexId = "turnId"
		case itemCodexId = "itemId"
		case approvalId
		case reason
		case command
		case cwd
		case commandActions
		case additionalPermissions
		case proposedExecPolicyAmendment = "proposedExecpolicyAmendment"
		case proposedNetworkPolicyAmendments
		case availableDecisions
	}
}

public struct ExecCommandApprovalParams: Sendable, Codable, Equatable, Hashable {
	public var conversationCodexId: String
	public var callId: String
	public var approvalId: String?
	public var command: [String]
	public var cwd: String
	public var reason: String?
	public var parsedCommand: [ParsedCommand]

	private enum CodingKeys: String, CodingKey {
		case conversationCodexId = "conversationId"
		case callId
		case approvalId
		case command
		case cwd
		case reason
		case parsedCommand = "parsedCmd"
	}
}

public struct ExecCommandApprovalResponse: Sendable, Codable, Equatable, Hashable {
	public var decision: ReviewDecision
}
