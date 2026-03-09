//
//  CodexConnection+Messages.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import Foundation

	// MARK: - Connection Layer JSON-RPC Message Types

public struct JSONRPCRequestMessage<Params: Encodable>: Encodable, Sendable {
	public let id: JSONRPCID
	public let method: String
	public let params: Params
}

public struct JSONRPCNotificationMessage<Params: Encodable>: Encodable, Sendable {
	public let method: String
	public let params: Params
}

public struct JSONRPCClientNotificationMessage: Encodable, Sendable {
	public let method: String
}

public struct JSONRPCResponseMessage<Result: Decodable>: Decodable, Sendable {
	public let id: JSONRPCID
	public let result: Result
}

public struct JSONRPCErrorMessage: Decodable, Sendable {
	public let id: JSONRPCID?
	public let error: JSONRPCErrorObject
}

public struct JSONRPCResponseEnvelope<Result: Encodable>: Encodable, Sendable {
	public let id: JSONRPCID
	public let result: Result
}

public struct JSONRPCErrorEnvelope: Encodable, Sendable {
	public let id: JSONRPCID?
	public let error: JSONRPCErrorObject
}

public struct JSONRPCErrorObject: Sendable, Codable {
	public let code: Int
	public let message: String
	public let data: JSONValue?

	public init(code: Int, message: String, data: JSONValue? = nil) {
		self.code = code
		self.message = message
		self.data = data
	}
}

public enum JSONRPCID: Hashable, Sendable, Codable {
	case string(String)
	case int(Int64)

	public init(rawValue: Any) throws {
		switch rawValue {
		case let value as String:
			self = .string(value)
		case let value as NSNumber where CFGetTypeID(value) != CFBooleanGetTypeID():
			self = .int(value.int64Value)
		default:
			throw CodexConnectionError.invalidMessage
		}
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		if let stringValue = try? container.decode(String.self) {
			self = .string(stringValue)
			return
		}
		if let intValue = try? container.decode(Int64.self) {
			self = .int(intValue)
			return
		}
		throw CodexConnectionError.invalidMessage
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		switch self {
		case let .string(value):
			try container.encode(value)
		case let .int(value):
			try container.encode(value)
		}
	}
}
