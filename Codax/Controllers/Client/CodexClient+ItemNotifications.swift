//
//  CodexClient+ItemNotifications.swift
//  Codax
//
//  Created by Codex on 3/10/26.
//

import Foundation

public enum ThreadItem: Sendable, Codable, Equatable, Hashable {
	case userMessage(UserMessageItem)
	case agentMessage(AgentMessageItem)
	case plan(PlanItem)
	case reasoning(ReasoningItem)
	case commandExecution(CommandExecutionItem)
	case fileChange(FileChangeItem)
	case mcpToolCall(McpToolCallItem)
	case dynamicToolCall(DynamicToolCallItem)
	case collabAgentToolCall(CollabAgentToolCallItem)
	case webSearch(WebSearchItem)
	case imageView(ImageViewItem)
	case imageGeneration(ImageGenerationItem)
	case enteredReviewMode(ReviewModeItem)
	case exitedReviewMode(ReviewModeItem)
	case contextCompaction(ContextCompactionItem)
	case unknown(raw: CodexValue)

	private enum CodingKeys: String, CodingKey {
		case type
	}

	private enum Kind: String, Codable {
		case userMessage
		case agentMessage
		case plan
		case reasoning
		case commandExecution
		case fileChange
		case mcpToolCall
		case dynamicToolCall
		case collabAgentToolCall
		case webSearch
		case imageView
		case imageGeneration
		case enteredReviewMode
		case exitedReviewMode
		case contextCompaction
	}

	public init(from decoder: any Decoder) throws {
		let fallback = try CodexValue(from: decoder)
		guard
			case let .object(object) = fallback,
			case let .string(type)? = object["type"],
			let kind = Kind(rawValue: type)
		else {
			self = .unknown(raw: fallback)
			return
		}

		switch kind {
		case .userMessage: self = .userMessage(try Self.decode(UserMessageItem.self, from: fallback))
		case .agentMessage: self = .agentMessage(try Self.decode(AgentMessageItem.self, from: fallback))
		case .plan: self = .plan(try Self.decode(PlanItem.self, from: fallback))
		case .reasoning: self = .reasoning(try Self.decode(ReasoningItem.self, from: fallback))
		case .commandExecution: self = .commandExecution(try Self.decode(CommandExecutionItem.self, from: fallback))
		case .fileChange: self = .fileChange(try Self.decode(FileChangeItem.self, from: fallback))
		case .mcpToolCall: self = .mcpToolCall(try Self.decode(McpToolCallItem.self, from: fallback))
		case .dynamicToolCall: self = .dynamicToolCall(try Self.decode(DynamicToolCallItem.self, from: fallback))
		case .collabAgentToolCall: self = .collabAgentToolCall(try Self.decode(CollabAgentToolCallItem.self, from: fallback))
		case .webSearch: self = .webSearch(try Self.decode(WebSearchItem.self, from: fallback))
		case .imageView: self = .imageView(try Self.decode(ImageViewItem.self, from: fallback))
		case .imageGeneration: self = .imageGeneration(try Self.decode(ImageGenerationItem.self, from: fallback))
		case .enteredReviewMode: self = .enteredReviewMode(try Self.decode(ReviewModeItem.self, from: fallback))
		case .exitedReviewMode: self = .exitedReviewMode(try Self.decode(ReviewModeItem.self, from: fallback))
		case .contextCompaction: self = .contextCompaction(try Self.decode(ContextCompactionItem.self, from: fallback))
		}
	}

	public func encode(to encoder: any Encoder) throws {
		switch self {
		case let .userMessage(item): try CodexCoding.encodeTaggedObject(item, kind: Kind.userMessage, to: encoder)
		case let .agentMessage(item): try CodexCoding.encodeTaggedObject(item, kind: Kind.agentMessage, to: encoder)
		case let .plan(item): try CodexCoding.encodeTaggedObject(item, kind: Kind.plan, to: encoder)
		case let .reasoning(item): try CodexCoding.encodeTaggedObject(item, kind: Kind.reasoning, to: encoder)
		case let .commandExecution(item): try CodexCoding.encodeTaggedObject(item, kind: Kind.commandExecution, to: encoder)
		case let .fileChange(item): try CodexCoding.encodeTaggedObject(item, kind: Kind.fileChange, to: encoder)
		case let .mcpToolCall(item): try CodexCoding.encodeTaggedObject(item, kind: Kind.mcpToolCall, to: encoder)
		case let .dynamicToolCall(item): try CodexCoding.encodeTaggedObject(item, kind: Kind.dynamicToolCall, to: encoder)
		case let .collabAgentToolCall(item): try CodexCoding.encodeTaggedObject(item, kind: Kind.collabAgentToolCall, to: encoder)
		case let .webSearch(item): try CodexCoding.encodeTaggedObject(item, kind: Kind.webSearch, to: encoder)
		case let .imageView(item): try CodexCoding.encodeTaggedObject(item, kind: Kind.imageView, to: encoder)
		case let .imageGeneration(item): try CodexCoding.encodeTaggedObject(item, kind: Kind.imageGeneration, to: encoder)
		case let .enteredReviewMode(item): try CodexCoding.encodeTaggedObject(item, kind: Kind.enteredReviewMode, to: encoder)
		case let .exitedReviewMode(item): try CodexCoding.encodeTaggedObject(item, kind: Kind.exitedReviewMode, to: encoder)
		case let .contextCompaction(item): try CodexCoding.encodeTaggedObject(item, kind: Kind.contextCompaction, to: encoder)
		case let .unknown(raw): try raw.encode(to: encoder)
		}
	}

	private static func decode<T: Decodable>(_ type: T.Type, from value: CodexValue) throws -> T {
		try CodexValue.decode(type, from: value)
	}
}

public struct ItemStartedNotification: Sendable, Codable, Equatable {
	public var item: ThreadItem
	public var threadCodexId: String
	public var turnCodexId: String

	private enum CodingKeys: String, CodingKey {
		case item
		case threadCodexId = "threadId"
		case turnCodexId = "turnId"
	}
}

public struct ItemCompletedNotification: Sendable, Codable, Equatable {
	public var item: ThreadItem
	public var threadCodexId: String
	public var turnCodexId: String

	private enum CodingKeys: String, CodingKey {
		case item
		case threadCodexId = "threadId"
		case turnCodexId = "turnId"
	}
}
