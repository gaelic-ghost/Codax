//
//  CodexClient+ServerResponseTypes.swift
//  Codax
//
//  Created by Gale Williams on 3/10/26.
//

import Foundation

	// MARK: - Client Layer Server Response Types

	// MARK: Client Inbound Message Envelopes

public enum CodexInboundMessage: Sendable {
	case response(JSONRPCID, Data)
	case error(JSONRPCID?, JSONRPCErrorObject)
	case serverNotification(ServerNotificationEnvelope)
	case serverRequest(ServerRequestEnvelope)
}



	// MARK: Account/Auth Types
	// Extracted to CodexClient.swift

	// MARK: Initialization/Startup Types

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

	// MARK: Item Types
	// Extracted to CodexClient+Item.swift

	// MARK: Model Types



	// MARK: Service Types



	// MARK: Thread Types
	// Extracted to CodexClient+Thread.swift

	// MARK: Turn Types
	// Extracted to CodexClient+Turn.swift
