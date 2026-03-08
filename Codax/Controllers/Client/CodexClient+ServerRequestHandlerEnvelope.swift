//
//  CodexClient+ServerRequestHandlerEnvelope.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: - Client Layer Server Request Handling Envelopes

public enum ServerRequestEnvelope: Sendable {
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
	static func decode(method: String, id: JSONRPCID, params: Data, decoder: JSONDecoder) throws -> ServerRequestEnvelope {
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

	var id: JSONRPCID {
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
