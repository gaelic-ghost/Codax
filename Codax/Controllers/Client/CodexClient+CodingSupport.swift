//
//  CodexClient+CodingSupport.swift
//  Codax
//
//  Created by Codex on 3/10/26.
//

import Foundation

public indirect enum CodexValue: Sendable, Codable, Equatable, Hashable {
	case null
	case bool(Bool)
	case number(Double)
	case string(String)
	case array([CodexValue])
	case object([String: CodexValue])

	public init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		if container.decodeNil() {
			self = .null
		} else if let bool = try? container.decode(Bool.self) {
			self = .bool(bool)
		} else if let number = try? container.decode(Double.self) {
			self = .number(number)
		} else if let string = try? container.decode(String.self) {
			self = .string(string)
		} else if let array = try? container.decode([CodexValue].self) {
			self = .array(array)
		} else if let object = try? container.decode([String: CodexValue].self) {
			self = .object(object)
		} else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported CodexValue payload.")
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		switch self {
		case .null:
			try container.encodeNil()
		case let .bool(value):
			try container.encode(value)
		case let .number(value):
			try container.encode(value)
		case let .string(value):
			try container.encode(value)
		case let .array(value):
			try container.encode(value)
		case let .object(value):
			try container.encode(value)
		}
	}
}

extension CodexValue {
	static func decode<T: Decodable>(_ type: T.Type, from value: CodexValue, using decoder: JSONDecoder = JSONDecoder()) throws -> T {
		let data = try JSONEncoder().encode(value)
		return try decoder.decode(T.self, from: data)
	}

	static func encode<T: Encodable>(_ value: T, using encoder: JSONEncoder = JSONEncoder()) throws -> CodexValue {
		let data = try encoder.encode(value)
		return try JSONDecoder().decode(CodexValue.self, from: data)
	}
}

enum CodexCoding {
	static func decodeStringCase<Value>(
		from decoder: any Decoder,
		typeName: String,
		mapping: [String: Value]
	) throws -> Value {
		let container = try decoder.singleValueContainer()
		let rawValue = try container.decode(String.self)
		guard let value = mapping[rawValue] else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported \(typeName) value: \(rawValue)")
		}
		return value
	}

	static func decodeStringOrObject<Keys: CodingKey, Value>(
		from decoder: any Decoder,
		typeName: String,
		stringMapping: [String: Value],
		object: (KeyedDecodingContainer<Keys>) throws -> Value
	) throws -> Value {
		if let container = try? decoder.singleValueContainer(), let rawValue = try? container.decode(String.self) {
			guard let value = stringMapping[rawValue] else {
				throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported \(typeName) value: \(rawValue)")
			}
			return value
		}

		let container = try decoder.container(keyedBy: Keys.self)
		return try object(container)
	}

	static func decodeKeyedOneOf<Keys: CodingKey, Value>(
		from decoder: any Decoder,
		typeName: String,
		tries: [(Keys, (KeyedDecodingContainer<Keys>) throws -> Value)]
	) throws -> Value {
		let container = try decoder.container(keyedBy: Keys.self)
		for (key, decode) in tries where container.contains(key) {
			return try decode(container)
		}
		throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unsupported \(typeName) payload."))
	}

	static func decodeTaggedKind<Keys: CodingKey, Kind: RawRepresentable>(
		from decoder: any Decoder,
		codingKeys: Keys.Type,
		typeKey: Keys,
		kindType: Kind.Type,
		typeName: String
	) throws -> (kind: Kind, container: KeyedDecodingContainer<Keys>)
	where Kind.RawValue == String
	{
		let container = try decoder.container(keyedBy: codingKeys)
		let rawValue = try container.decode(String.self, forKey: typeKey)
		guard let kind = Kind(rawValue: rawValue) else {
			throw DecodingError.dataCorruptedError(forKey: typeKey, in: container, debugDescription: "Unsupported \(typeName) type: \(rawValue)")
		}
		return (kind, container)
	}

	static func encodeStringValue(_ value: String, to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(value)
	}

	static func encodeTaggedObject<T: Encodable, Kind: RawRepresentable>(
		_ value: T,
		kind: Kind,
		typeKey: String = "type",
		to encoder: any Encoder
	) throws
	where Kind.RawValue == String
	{
		let encoded = try CodexValue.encode(value)
		guard case var .object(object) = encoded else {
			throw EncodingError.invalidValue(
				value,
				.init(codingPath: encoder.codingPath, debugDescription: "Tagged payloads must encode as JSON objects.")
			)
		}
		object[typeKey] = .string(kind.rawValue)
		try CodexValue.object(object).encode(to: encoder)
	}
}
