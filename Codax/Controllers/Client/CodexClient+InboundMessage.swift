//
//  CodexClient+InboundMessage.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: - Inbound Message Envelopes

public enum CodexInboundMessage: Sendable {
	case response(JSONRPCID, Data)
	case error(JSONRPCID?, JSONRPCErrorObject)
	case serverNotification(ServerNotificationEnvelope)
	case serverRequest(ServerRequestEnvelope)
}
