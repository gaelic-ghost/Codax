//
//  CodexClient+ServerRequestHandlerEnvelope.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: - Client Layer Server Request Handling Envelopes

public enum ServerRequestEnvelope: Sendable {
	case commandApproval(CommandExecutionRequestApprovalParams, id: JSONRPCID)
	case fileChangeApproval(FileChangeRequestApprovalParams, id: JSONRPCID)
	case userInput(ToolRequestUserInputParams, id: JSONRPCID)
	case mcpServerElicitation(McpServerElicitationRequestParams, id: JSONRPCID)
	case chatgptAuthRefresh(ChatgptAuthTokensRefreshParams, id: JSONRPCID)
	case dynamicToolCall(DynamicToolCallParams, id: JSONRPCID)
	case applyPatchApproval(ApplyPatchApprovalParams, id: JSONRPCID)
	case execCommandApproval(ExecCommandApprovalParams, id: JSONRPCID)
	case unknown(method: String, id: JSONRPCID, raw: Data)
}

extension ServerRequestEnvelope {
	static func decode(method: String, id: JSONRPCID, params: Data, decoder: JSONDecoder) throws -> ServerRequestEnvelope {
		switch method {
			case "item/commandExecution/requestApproval":
				return .commandApproval(try decoder.decode(CommandExecutionRequestApprovalParams.self, from: params), id: id)
			case "item/fileChange/requestApproval":
				return .fileChangeApproval(try decoder.decode(FileChangeRequestApprovalParams.self, from: params), id: id)
			case "item/tool/requestUserInput":
				return .userInput(try decoder.decode(ToolRequestUserInputParams.self, from: params), id: id)
			case "mcpServer/elicitation/request":
				return .mcpServerElicitation(try decoder.decode(McpServerElicitationRequestParams.self, from: params), id: id)
			case "account/chatgptAuthTokens/refresh":
				return .chatgptAuthRefresh(try decoder.decode(ChatgptAuthTokensRefreshParams.self, from: params), id: id)
			case "item/tool/call":
				return .dynamicToolCall(try decoder.decode(DynamicToolCallParams.self, from: params), id: id)
			case "applyPatchApproval":
				return .applyPatchApproval(try decoder.decode(ApplyPatchApprovalParams.self, from: params), id: id)
			case "execCommandApproval":
				return .execCommandApproval(try decoder.decode(ExecCommandApprovalParams.self, from: params), id: id)
			default:
				return .unknown(method: method, id: id, raw: params)
		}
	}

	var id: JSONRPCID {
		switch self {
			case let .commandApproval(_, id),
				let .fileChangeApproval(_, id),
				let .userInput(_, id),
				let .mcpServerElicitation(_, id),
				let .chatgptAuthRefresh(_, id),
				let .dynamicToolCall(_, id),
				let .applyPatchApproval(_, id),
				let .execCommandApproval(_, id),
				let .unknown(_, id, _):
				return id
		}
	}
}
