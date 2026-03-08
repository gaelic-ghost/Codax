//
//  CodexClient+Envelopes.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

	// MARK: - Inbound Envelopes

public enum CodexInboundMessage: Sendable {
	case response(JSONRPCID, Data)
	case error(JSONRPCID?, JSONRPCErrorObject)
	case serverNotification(ServerNotificationEnvelope)
	case serverRequest(ServerRequestEnvelope)
}

public enum ServerNotificationEnvelope: Sendable {
	case threadStarted(ThreadStartedNotification)
	case turnStarted(TurnStartedNotification)
	case itemStarted(ItemStartedNotification)
	case accountUpdated(AccountUpdatedNotification)
	case accountLoginCompleted(AccountLoginCompletedNotification)
	case reasoningTextDelta(ReasoningTextDeltaNotification)
	case unknown(method: String, raw: Data)
}

public enum ServerRequestEnvelope: Sendable {
	case commandApproval(CommandExecutionRequestApprovalParams, id: JSONRPCID)
	case fileChangeApproval(FileChangeRequestApprovalParams, id: JSONRPCID)
	case userInput(ToolRequestUserInputParams, id: JSONRPCID)
	case chatgptAuthRefresh(ChatgptAuthTokensRefreshParams, id: JSONRPCID)
	case dynamicToolCall(DynamicToolCallParams, id: JSONRPCID)
	case unknown(method: String, id: JSONRPCID, raw: Data)
}
