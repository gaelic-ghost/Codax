//
//  CodexConnection+Messages.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

	// MARK: - JSON-RPC Message Types

public struct JSONRPCRequestMessage<Params: Encodable>: Encodable, Sendable {
	public let jsonrpc: String = "2.0"
	public let id: JSONRPCID
	public let method: String
	public let params: Params
}

public struct JSONRPCNotificationMessage<Params: Encodable>: Encodable, Sendable {
	public let jsonrpc: String = "2.0"
	public let method: String
	public let params: Params
}

public struct JSONRPCResponseMessage<Result: Decodable>: Decodable, Sendable {
	public let jsonrpc: String
	public let id: JSONRPCID
	public let result: Result
}

public struct JSONRPCErrorMessage: Decodable, Sendable {
	public let jsonrpc: String
	public let id: JSONRPCID?
	public let error: JSONRPCErrorObject
}

public enum JSONRPCID: Hashable, Sendable, Codable {
	case string(String)
	case int(Int64)
}
