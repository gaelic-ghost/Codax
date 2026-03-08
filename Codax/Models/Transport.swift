//
//  Transport.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import Foundation

// MARK: - Transport Layer Types

public enum JSONValue: Sendable, Codable {
	case string(String)
	case number(Double)
	case bool(Bool)
	case object([String: JSONValue])
	case array([JSONValue])
	case null

	public init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()

		if container.decodeNil() {
			self = .null
		} else if let value = try? container.decode(Bool.self) {
			self = .bool(value)
		} else if let value = try? container.decode(Double.self) {
			self = .number(value)
		} else if let value = try? container.decode(String.self) {
			self = .string(value)
		} else if let value = try? container.decode([String: JSONValue].self) {
			self = .object(value)
		} else if let value = try? container.decode([JSONValue].self) {
			self = .array(value)
		} else {
			throw DecodingError.dataCorruptedError(
				in: container,
				debugDescription: "Unsupported JSON value"
			)
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()

		switch self {
		case let .string(value):
			try container.encode(value)
		case let .number(value):
			try container.encode(value)
		case let .bool(value):
			try container.encode(value)
		case let .object(value):
			try container.encode(value)
		case let .array(value):
			try container.encode(value)
		case .null:
			try container.encodeNil()
		}
	}
}

public enum CodexTransportError: Error, LocalizedError, Sendable {
	case endOfStream
	case invalidFrame
	case closed

	public var errorDescription: String? {
		switch self {
		case .endOfStream:
			return "The transport closed before another message was received."
		case .invalidFrame:
			return "The transport produced an invalid JSONL frame."
		case .closed:
			return "The transport is already closed."
		}
	}
}
