//
//  CodexClient+Item.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: - Client Layer `Item` Types

public enum MessagePhase: String, Sendable, Codable, Equatable {
	case commentary
	case finalAnswer = "final_answer"
}

public enum CommandExecutionStatus: String, Sendable, Codable, Equatable {
	case inProgress
	case completed
	case failed
	case declined
}

public enum PatchApplyStatus: String, Sendable, Codable, Equatable {
	case inProgress
	case completed
	case failed
	case declined
}

public enum McpToolCallStatus: String, Sendable, Codable, Equatable {
	case inProgress
	case completed
	case failed
}

public enum DynamicToolCallStatus: String, Sendable, Codable, Equatable {
	case inProgress
	case completed
	case failed
}

public enum PatchChangeKind: Sendable, Codable, Equatable {
	case add
	case delete
	case update(movePath: String?)

	private enum CodingKeys: String, CodingKey {
		case type
		case movePath = "move_path"
	}

	private enum Kind: String, Codable {
		case add
		case delete
		case update
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		switch try container.decode(Kind.self, forKey: .type) {
		case .add:
			self = .add
		case .delete:
			self = .delete
		case .update:
			self = .update(movePath: try container.decodeIfPresent(String.self, forKey: .movePath))
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case .add:
			try container.encode(Kind.add, forKey: .type)
		case .delete:
			try container.encode(Kind.delete, forKey: .type)
		case let .update(movePath):
			try container.encode(Kind.update, forKey: .type)
			try container.encode(movePath, forKey: .movePath)
		}
	}
}

public enum WebSearchAction: Sendable, Codable, Equatable {
	case search(query: String?, queries: [String]?)
	case openPage(url: String?)
	case findInPage(url: String?, pattern: String?)
	case other

	private enum CodingKeys: String, CodingKey {
		case type
		case query
		case queries
		case url
		case pattern
	}

	private enum Kind: String, Codable {
		case search
		case openPage
		case findInPage
		case other
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		switch try container.decode(Kind.self, forKey: .type) {
		case .search:
			self = .search(
				query: try container.decodeIfPresent(String.self, forKey: .query),
				queries: try container.decodeIfPresent([String].self, forKey: .queries)
			)
		case .openPage:
			self = .openPage(url: try container.decodeIfPresent(String.self, forKey: .url))
		case .findInPage:
			self = .findInPage(
				url: try container.decodeIfPresent(String.self, forKey: .url),
				pattern: try container.decodeIfPresent(String.self, forKey: .pattern)
			)
		case .other:
			self = .other
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .search(query, queries):
			try container.encode(Kind.search, forKey: .type)
			try container.encode(query, forKey: .query)
			try container.encode(queries, forKey: .queries)
		case let .openPage(url):
			try container.encode(Kind.openPage, forKey: .type)
			try container.encode(url, forKey: .url)
		case let .findInPage(url, pattern):
			try container.encode(Kind.findInPage, forKey: .type)
			try container.encode(url, forKey: .url)
			try container.encode(pattern, forKey: .pattern)
		case .other:
			try container.encode(Kind.other, forKey: .type)
		}
	}
}

public struct UserMessageItem: Sendable, Codable, Equatable {
	public var id: String
	public var content: [JSONValue]
}

public struct AgentMessageItem: Sendable, Codable, Equatable {
	public var id: String
	public var text: String
	public var phase: MessagePhase?
}

public struct PlanItem: Sendable, Codable, Equatable {
	public var id: String
	public var text: String
}

public struct ReasoningItem: Sendable, Codable, Equatable {
	public var id: String
	public var summary: [String]
	public var content: [String]
}

public struct CommandExecutionItem: Sendable, Codable, Equatable {
	public var id: String
	public var command: String
	public var cwd: String
	public var processId: String?
	public var status: CommandExecutionStatus
	public var commandActions: [JSONValue]
	public var aggregatedOutput: String?
	public var exitCode: Int?
	public var durationMs: Int?
}

public struct FileUpdateChange: Sendable, Codable, Equatable {
	public var path: String
	public var kind: PatchChangeKind
	public var diff: String
}

public struct FileChangeItem: Sendable, Codable, Equatable {
	public var id: String
	public var changes: [FileUpdateChange]
	public var status: PatchApplyStatus
}

public struct McpToolCallResult: Sendable, Codable, Equatable {
	public var content: [JSONValue]
	public var structuredContent: JSONValue?
}

public struct McpToolCallError: Sendable, Codable, Equatable {
	public var message: String
}

public struct McpToolCallItem: Sendable, Codable, Equatable {
	public var id: String
	public var server: String
	public var tool: String
	public var status: McpToolCallStatus
	public var arguments: JSONValue
	public var result: McpToolCallResult?
	public var error: McpToolCallError?
	public var durationMs: Int?
}

public struct DynamicToolCallItem: Sendable, Codable, Equatable {
	public var id: String
	public var tool: String
	public var arguments: JSONValue
	public var status: DynamicToolCallStatus
	public var contentItems: [JSONValue]?
	public var success: Bool?
	public var durationMs: Int?
}

public struct WebSearchItem: Sendable, Codable, Equatable {
	public var id: String
	public var query: String
	public var action: WebSearchAction?
}

public struct ImageViewItem: Sendable, Codable, Equatable {
	public var id: String
	public var path: String
}

public struct ReviewModeItem: Sendable, Codable, Equatable {
	public var id: String
	public var review: String
}

public struct ContextCompactionItem: Sendable, Codable, Equatable {
	public var id: String
}

public enum ThreadItem: Sendable, Codable, Equatable {
	case userMessage(UserMessageItem)
	case agentMessage(AgentMessageItem)
	case plan(PlanItem)
	case reasoning(ReasoningItem)
	case commandExecution(CommandExecutionItem)
	case fileChange(FileChangeItem)
	case mcpToolCall(McpToolCallItem)
	case dynamicToolCall(DynamicToolCallItem)
	case webSearch(WebSearchItem)
	case imageView(ImageViewItem)
	case enteredReviewMode(ReviewModeItem)
	case exitedReviewMode(ReviewModeItem)
	case contextCompaction(ContextCompactionItem)
	case unknown(raw: JSONValue)

	private enum CodingKeys: String, CodingKey {
		case type
	}

	public init(from decoder: any Decoder) throws {
		let rawValue = try JSONValue(from: decoder)
		guard
			case let .object(object) = rawValue,
			case let .string(type)? = object["type"]
		else {
			self = .unknown(raw: rawValue)
			return
		}

		let nestedDecoder = ThreadItemDecoder(rawValue: rawValue)
		switch type {
		case "userMessage":
			self = .userMessage(try UserMessageItem(from: nestedDecoder))
		case "agentMessage":
			self = .agentMessage(try AgentMessageItem(from: nestedDecoder))
		case "plan":
			self = .plan(try PlanItem(from: nestedDecoder))
		case "reasoning":
			self = .reasoning(try ReasoningItem(from: nestedDecoder))
		case "commandExecution":
			self = .commandExecution(try CommandExecutionItem(from: nestedDecoder))
		case "fileChange":
			self = .fileChange(try FileChangeItem(from: nestedDecoder))
		case "mcpToolCall":
			self = .mcpToolCall(try McpToolCallItem(from: nestedDecoder))
		case "dynamicToolCall":
			self = .dynamicToolCall(try DynamicToolCallItem(from: nestedDecoder))
		case "webSearch":
			self = .webSearch(try WebSearchItem(from: nestedDecoder))
		case "imageView":
			self = .imageView(try ImageViewItem(from: nestedDecoder))
		case "enteredReviewMode":
			self = .enteredReviewMode(try ReviewModeItem(from: nestedDecoder))
		case "exitedReviewMode":
			self = .exitedReviewMode(try ReviewModeItem(from: nestedDecoder))
		case "contextCompaction":
			self = .contextCompaction(try ContextCompactionItem(from: nestedDecoder))
		default:
			self = .unknown(raw: rawValue)
		}
	}

	public func encode(to encoder: any Encoder) throws {
		switch self {
		case let .userMessage(item):
			try Self.jsonValue(for: item).encode(to: encoder)
		case let .agentMessage(item):
			try Self.jsonValue(for: item).encode(to: encoder)
		case let .plan(item):
			try Self.jsonValue(for: item).encode(to: encoder)
		case let .reasoning(item):
			try Self.jsonValue(for: item).encode(to: encoder)
		case let .commandExecution(item):
			try Self.jsonValue(for: item).encode(to: encoder)
		case let .fileChange(item):
			try Self.jsonValue(for: item).encode(to: encoder)
		case let .mcpToolCall(item):
			try Self.jsonValue(for: item).encode(to: encoder)
		case let .dynamicToolCall(item):
			try Self.jsonValue(for: item).encode(to: encoder)
		case let .webSearch(item):
			try Self.jsonValue(for: item).encode(to: encoder)
		case let .imageView(item):
			try Self.jsonValue(for: item).encode(to: encoder)
		case let .enteredReviewMode(item):
			try Self.jsonValue(for: item, type: "enteredReviewMode").encode(to: encoder)
		case let .exitedReviewMode(item):
			try Self.jsonValue(for: item, type: "exitedReviewMode").encode(to: encoder)
		case let .contextCompaction(item):
			try Self.jsonValue(for: item).encode(to: encoder)
		case let .unknown(raw):
			try raw.encode(to: encoder)
		}
	}

	private static func jsonValue(for item: UserMessageItem) -> JSONValue {
		.object([
			"type": .string("userMessage"),
			"id": .string(item.id),
			"content": .array(item.content),
		])
	}

	private static func jsonValue(for item: AgentMessageItem) -> JSONValue {
		.object([
			"type": .string("agentMessage"),
			"id": .string(item.id),
			"text": .string(item.text),
			"phase": item.phase.map { .string($0.rawValue) } ?? .null,
		])
	}

	private static func jsonValue(for item: PlanItem) -> JSONValue {
		.object([
			"type": .string("plan"),
			"id": .string(item.id),
			"text": .string(item.text),
		])
	}

	private static func jsonValue(for item: ReasoningItem) -> JSONValue {
		.object([
			"type": .string("reasoning"),
			"id": .string(item.id),
			"summary": .array(item.summary.map(JSONValue.string)),
			"content": .array(item.content.map(JSONValue.string)),
		])
	}

	private static func jsonValue(for item: CommandExecutionItem) -> JSONValue {
		.object([
			"type": .string("commandExecution"),
			"id": .string(item.id),
			"command": .string(item.command),
			"cwd": .string(item.cwd),
			"processId": item.processId.map { .string($0) } ?? .null,
			"status": .string(item.status.rawValue),
			"commandActions": .array(item.commandActions),
			"aggregatedOutput": item.aggregatedOutput.map { .string($0) } ?? .null,
			"exitCode": item.exitCode.map { .number(Double($0)) } ?? .null,
			"durationMs": item.durationMs.map { .number(Double($0)) } ?? .null,
		])
	}

	private static func jsonValue(for item: FileChangeItem) -> JSONValue {
		.object([
			"type": .string("fileChange"),
			"id": .string(item.id),
			"changes": .array(item.changes.map(jsonValue)),
			"status": .string(item.status.rawValue),
		])
	}

	private static func jsonValue(for change: FileUpdateChange) -> JSONValue {
		.object([
			"path": .string(change.path),
			"kind": jsonValue(for: change.kind),
			"diff": .string(change.diff),
		])
	}

	private static func jsonValue(for kind: PatchChangeKind) -> JSONValue {
		switch kind {
		case .add:
			return .object(["type": .string("add")])
		case .delete:
			return .object(["type": .string("delete")])
		case let .update(movePath):
			return .object([
				"type": .string("update"),
				"move_path": movePath.map { .string($0) } ?? .null,
			])
		}
	}

	private static func jsonValue(for item: McpToolCallItem) -> JSONValue {
		.object([
			"type": .string("mcpToolCall"),
			"id": .string(item.id),
			"server": .string(item.server),
			"tool": .string(item.tool),
			"status": .string(item.status.rawValue),
			"arguments": item.arguments,
			"result": item.result.map(jsonValue) ?? .null,
			"error": item.error.map(jsonValue) ?? .null,
			"durationMs": item.durationMs.map { .number(Double($0)) } ?? .null,
		])
	}

	private static func jsonValue(for result: McpToolCallResult) -> JSONValue {
		.object([
			"content": .array(result.content),
			"structuredContent": result.structuredContent ?? .null,
		])
	}

	private static func jsonValue(for error: McpToolCallError) -> JSONValue {
		.object(["message": .string(error.message)])
	}

	private static func jsonValue(for item: DynamicToolCallItem) -> JSONValue {
		.object([
			"type": .string("dynamicToolCall"),
			"id": .string(item.id),
			"tool": .string(item.tool),
			"arguments": item.arguments,
			"status": .string(item.status.rawValue),
			"contentItems": item.contentItems.map { .array($0) } ?? .null,
			"success": item.success.map { .bool($0) } ?? .null,
			"durationMs": item.durationMs.map { .number(Double($0)) } ?? .null,
		])
	}

	private static func jsonValue(for item: WebSearchItem) -> JSONValue {
		.object([
			"type": .string("webSearch"),
			"id": .string(item.id),
			"query": .string(item.query),
			"action": item.action.map(jsonValue) ?? .null,
		])
	}

	private static func jsonValue(for action: WebSearchAction) -> JSONValue {
		switch action {
		case let .search(query, queries):
			return .object([
				"type": .string("search"),
				"query": query.map { .string($0) } ?? .null,
				"queries": queries.map { .array($0.map(JSONValue.string)) } ?? .null,
			])
		case let .openPage(url):
			return .object([
				"type": .string("openPage"),
				"url": url.map { .string($0) } ?? .null,
			])
		case let .findInPage(url, pattern):
			return .object([
				"type": .string("findInPage"),
				"url": url.map { .string($0) } ?? .null,
				"pattern": pattern.map { .string($0) } ?? .null,
			])
		case .other:
			return .object(["type": .string("other")])
		}
	}

	private static func jsonValue(for item: ImageViewItem) -> JSONValue {
		.object([
			"type": .string("imageView"),
			"id": .string(item.id),
			"path": .string(item.path),
		])
	}

	private static func jsonValue(for item: ReviewModeItem, type: String) -> JSONValue {
		.object([
			"type": .string(type),
			"id": .string(item.id),
			"review": .string(item.review),
		])
	}

	private static func jsonValue(for item: ContextCompactionItem) -> JSONValue {
		.object([
			"type": .string("contextCompaction"),
			"id": .string(item.id),
		])
	}
}

	// MARK: Notifications

public struct ItemStartedNotification: Sendable, Codable, Equatable {
	public var item: ThreadItem
	public var threadId: String
	public var turnId: String
}

public struct ItemCompletedNotification: Sendable, Codable, Equatable {
	public var item: ThreadItem
	public var threadId: String
	public var turnId: String
}

private struct ThreadItemDecoder: Decoder {
	let rawValue: JSONValue

	var codingPath: [any CodingKey] { [] }
	var userInfo: [CodingUserInfoKey: Any] { [:] }

	func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
		let decoder = JSONValueDecoder(rawValue: rawValue)
		return try decoder.container(keyedBy: type)
	}

	func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
		try JSONValueDecoder(rawValue: rawValue).unkeyedContainer()
	}

	func singleValueContainer() throws -> any SingleValueDecodingContainer {
		try JSONValueDecoder(rawValue: rawValue).singleValueContainer()
	}
}

private struct JSONValueDecoder: Decoder {
	let rawValue: JSONValue

	var codingPath: [any CodingKey] { [] }
	var userInfo: [CodingUserInfoKey: Any] { [:] }

	func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
		guard case let .object(object) = rawValue else {
			throw DecodingError.typeMismatch(
				[String: JSONValue].self,
				.init(codingPath: codingPath, debugDescription: "Expected object.")
			)
		}
		return KeyedDecodingContainer(JSONValueKeyedDecodingContainer(object: object))
	}

	func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
		guard case let .array(array) = rawValue else {
			throw DecodingError.typeMismatch(
				[JSONValue].self,
				.init(codingPath: codingPath, debugDescription: "Expected array.")
			)
		}
		return JSONValueUnkeyedDecodingContainer(array: array)
	}

	func singleValueContainer() throws -> any SingleValueDecodingContainer {
		JSONValueSingleValueDecodingContainer(rawValue: rawValue)
	}
}

private struct JSONValueKeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
	let object: [String: JSONValue]

	var codingPath: [any CodingKey] { [] }
	var allKeys: [Key] { object.keys.compactMap(Key.init(stringValue:)) }

	func contains(_ key: Key) -> Bool {
		object[key.stringValue] != nil
	}

	func decodeNil(forKey key: Key) throws -> Bool {
		object[key.stringValue] == .null
	}

	func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
		guard let value = object[key.stringValue] else {
			throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "Missing key \(key.stringValue)."))
		}
		return try T(from: JSONValueDecoder(rawValue: value))
	}

	func decodeIfPresent<T>(_ type: T.Type, forKey key: Key) throws -> T? where T : Decodable {
		guard let value = object[key.stringValue], value != .null else {
			return nil
		}
		return try T(from: JSONValueDecoder(rawValue: value))
	}

	func nestedContainer<NestedKey>(
		keyedBy keyType: NestedKey.Type,
		forKey key: Key
	) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
		guard let value = object[key.stringValue] else {
			throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "Missing key \(key.stringValue)."))
		}
		return try JSONValueDecoder(rawValue: value).container(keyedBy: keyType)
	}

	func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
		guard let value = object[key.stringValue] else {
			throw DecodingError.keyNotFound(key, .init(codingPath: codingPath, debugDescription: "Missing key \(key.stringValue)."))
		}
		return try JSONValueDecoder(rawValue: value).unkeyedContainer()
	}

	func superDecoder() throws -> any Decoder {
		JSONValueDecoder(rawValue: .object(object))
	}

	func superDecoder(forKey key: Key) throws -> any Decoder {
		JSONValueDecoder(rawValue: object[key.stringValue] ?? .null)
	}
}

private struct JSONValueUnkeyedDecodingContainer: UnkeyedDecodingContainer {
	let array: [JSONValue]
	var codingPath: [any CodingKey] = []
	var currentIndex = 0

	var count: Int? { array.count }
	var isAtEnd: Bool { currentIndex >= array.count }

	mutating func decodeNil() throws -> Bool {
		guard !isAtEnd else {
			throw DecodingError.valueNotFound(
				JSONValue.self,
				.init(codingPath: codingPath, debugDescription: "Unkeyed container is at end.")
			)
		}
		if array[currentIndex] == .null {
			currentIndex += 1
			return true
		}
		return false
	}

	mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
		guard !isAtEnd else {
			throw DecodingError.valueNotFound(
				T.self,
				.init(codingPath: codingPath, debugDescription: "Unkeyed container is at end.")
			)
		}
		let value = array[currentIndex]
		currentIndex += 1
		return try T(from: JSONValueDecoder(rawValue: value))
	}

	mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
		guard !isAtEnd else {
			throw DecodingError.valueNotFound(
				[NestedKey: JSONValue].self,
				.init(codingPath: codingPath, debugDescription: "Unkeyed container is at end.")
			)
		}
		let value = array[currentIndex]
		currentIndex += 1
		return try JSONValueDecoder(rawValue: value).container(keyedBy: keyType)
	}

	mutating func nestedUnkeyedContainer() throws -> any UnkeyedDecodingContainer {
		guard !isAtEnd else {
			throw DecodingError.valueNotFound(
				[JSONValue].self,
				.init(codingPath: codingPath, debugDescription: "Unkeyed container is at end.")
			)
		}
		let value = array[currentIndex]
		currentIndex += 1
		return try JSONValueDecoder(rawValue: value).unkeyedContainer()
	}

	mutating func superDecoder() throws -> any Decoder {
		guard !isAtEnd else {
			throw DecodingError.valueNotFound(
				JSONValue.self,
				.init(codingPath: codingPath, debugDescription: "Unkeyed container is at end.")
			)
		}
		let value = array[currentIndex]
		currentIndex += 1
		return JSONValueDecoder(rawValue: value)
	}
}

private struct JSONValueSingleValueDecodingContainer: SingleValueDecodingContainer {
	let rawValue: JSONValue
	var codingPath: [any CodingKey] { [] }

	func decodeNil() -> Bool {
		rawValue == .null
	}

	func decode(_ type: Bool.Type) throws -> Bool {
		guard case let .bool(value) = rawValue else {
			throw typeMismatch(type)
		}
		return value
	}

	func decode(_ type: String.Type) throws -> String {
		guard case let .string(value) = rawValue else {
			throw typeMismatch(type)
		}
		return value
	}

	func decode(_ type: Double.Type) throws -> Double {
		guard case let .number(value) = rawValue else {
			throw typeMismatch(type)
		}
		return value
	}

	func decode(_ type: Float.Type) throws -> Float {
		Float(try decode(Double.self))
	}

	func decode(_ type: Int.Type) throws -> Int {
		try integerValue(type)
	}

	func decode(_ type: Int8.Type) throws -> Int8 {
		try integerValue(type)
	}

	func decode(_ type: Int16.Type) throws -> Int16 {
		try integerValue(type)
	}

	func decode(_ type: Int32.Type) throws -> Int32 {
		try integerValue(type)
	}

	func decode(_ type: Int64.Type) throws -> Int64 {
		try integerValue(type)
	}

	func decode(_ type: UInt.Type) throws -> UInt {
		try unsignedIntegerValue(type)
	}

	func decode(_ type: UInt8.Type) throws -> UInt8 {
		try unsignedIntegerValue(type)
	}

	func decode(_ type: UInt16.Type) throws -> UInt16 {
		try unsignedIntegerValue(type)
	}

	func decode(_ type: UInt32.Type) throws -> UInt32 {
		try unsignedIntegerValue(type)
	}

	func decode(_ type: UInt64.Type) throws -> UInt64 {
		try unsignedIntegerValue(type)
	}

	func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
		if type == JSONValue.self {
			return rawValue as! T
		}
		return try T(from: JSONValueDecoder(rawValue: rawValue))
	}

	private func integerValue<T: FixedWidthInteger>(_ type: T.Type) throws -> T {
		guard case let .number(value) = rawValue else {
			throw typeMismatch(type)
		}
		let rounded = value.rounded()
		guard rounded == value, let integer = T(exactly: rounded) else {
			throw typeMismatch(type)
		}
		return integer
	}

	private func unsignedIntegerValue<T: FixedWidthInteger & UnsignedInteger>(_ type: T.Type) throws -> T {
		try integerValue(type)
	}

	private func typeMismatch<T>(_ type: T.Type) -> DecodingError {
		DecodingError.typeMismatch(
			type,
			.init(codingPath: codingPath, debugDescription: "Could not decode \(type) from JSONValue.")
		)
	}
}
