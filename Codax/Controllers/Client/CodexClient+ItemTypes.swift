//
//  CodexClient+ItemTypes.swift
//  Codax
//
//  Created by Codex on 3/10/26.
//

import Foundation

public enum MessagePhase: String, Sendable, Codable, Equatable, Hashable {
	case commentary
	case finalAnswer = "final_answer"
}

public enum CommandExecutionStatus: String, Sendable, Codable, Equatable, Hashable {
	case inProgress
	case completed
	case failed
	case declined
}

public enum PatchApplyStatus: String, Sendable, Codable, Equatable, Hashable {
	case inProgress
	case completed
	case failed
	case declined
}

public enum McpToolCallStatus: String, Sendable, Codable, Equatable, Hashable {
	case inProgress
	case completed
	case failed
}

public enum DynamicToolCallStatus: String, Sendable, Codable, Equatable, Hashable {
	case inProgress
	case completed
	case failed
}

public enum PatchChangeKind: Sendable, Codable, Equatable, Hashable {
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
		let (kind, container) = try CodexCoding.decodeTaggedKind(
			from: decoder,
			codingKeys: CodingKeys.self,
			typeKey: .type,
			kindType: Kind.self,
			typeName: "PatchChangeKind"
		)
		switch kind {
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

public enum WebSearchAction: Sendable, Codable, Equatable, Hashable {
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
		let (kind, container) = try CodexCoding.decodeTaggedKind(
			from: decoder,
			codingKeys: CodingKeys.self,
			typeKey: .type,
			kindType: Kind.self,
			typeName: "WebSearchAction"
		)
		switch kind {
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

public enum CommandAction: Sendable, Codable, Equatable, Hashable {
	case read(command: String, name: String, path: String)
	case listFiles(command: String, path: String?)
	case search(command: String, query: String?, path: String?)
	case unknown(command: String)

	private enum CodingKeys: String, CodingKey {
		case type
		case command
		case name
		case path
		case query
	}

	private enum Kind: String, Codable {
		case read
		case listFiles
		case search
		case unknown
	}

	public init(from decoder: any Decoder) throws {
		let (kind, container) = try CodexCoding.decodeTaggedKind(
			from: decoder,
			codingKeys: CodingKeys.self,
			typeKey: .type,
			kindType: Kind.self,
			typeName: "CommandAction"
		)
		switch kind {
		case .read:
			self = .read(
				command: try container.decode(String.self, forKey: .command),
				name: try container.decode(String.self, forKey: .name),
				path: try container.decode(String.self, forKey: .path)
			)
		case .listFiles:
			self = .listFiles(
				command: try container.decode(String.self, forKey: .command),
				path: try container.decodeIfPresent(String.self, forKey: .path)
			)
		case .search:
			self = .search(
				command: try container.decode(String.self, forKey: .command),
				query: try container.decodeIfPresent(String.self, forKey: .query),
				path: try container.decodeIfPresent(String.self, forKey: .path)
			)
		case .unknown:
			self = .unknown(command: try container.decode(String.self, forKey: .command))
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .read(command, name, path):
			try container.encode(Kind.read, forKey: .type)
			try container.encode(command, forKey: .command)
			try container.encode(name, forKey: .name)
			try container.encode(path, forKey: .path)
		case let .listFiles(command, path):
			try container.encode(Kind.listFiles, forKey: .type)
			try container.encode(command, forKey: .command)
			try container.encode(path, forKey: .path)
		case let .search(command, query, path):
			try container.encode(Kind.search, forKey: .type)
			try container.encode(command, forKey: .command)
			try container.encode(query, forKey: .query)
			try container.encode(path, forKey: .path)
		case let .unknown(command):
			try container.encode(Kind.unknown, forKey: .type)
			try container.encode(command, forKey: .command)
		}
	}
}

public enum CollabAgentStatus: String, Sendable, Codable, Equatable, Hashable {
	case pendingInit
	case running
	case completed
	case errored
	case shutdown
	case notFound
}

public struct CollabAgentState: Sendable, Codable, Equatable, Hashable {
	public var status: CollabAgentStatus
	public var message: String?
}

public enum CollabAgentTool: String, Sendable, Codable, Equatable, Hashable {
	case spawnAgent
	case sendInput
	case resumeAgent
	case wait
	case closeAgent
}

public enum CollabAgentToolCallStatus: String, Sendable, Codable, Equatable, Hashable {
	case inProgress
	case completed
	case failed
}
