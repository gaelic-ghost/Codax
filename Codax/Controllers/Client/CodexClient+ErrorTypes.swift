//
//  CodexClient+ErrorTypes.swift
//  Codax
//
//  Created by Codex on 3/10/26.
//

import Foundation

public enum CodexErrorInfo: Sendable, Codable, Equatable, Hashable {
	case contextWindowExceeded
	case usageLimitExceeded
	case serverOverloaded
	case httpConnectionFailed(httpStatusCode: Int?)
	case responseStreamConnectionFailed(httpStatusCode: Int?)
	case internalServerError
	case unauthorized
	case badRequest
	case threadRollbackFailed
	case sandboxError
	case responseStreamDisconnected(httpStatusCode: Int?)
	case responseTooManyFailedAttempts(httpStatusCode: Int?)
	case other

	private enum CodingKeys: String, CodingKey {
		case httpConnectionFailed
		case responseStreamConnectionFailed
		case responseStreamDisconnected
		case responseTooManyFailedAttempts
		case httpStatusCode
	}

	public init(from decoder: any Decoder) throws {
		self = try CodexCoding.decodeStringOrObject(
			from: decoder,
			typeName: "CodexErrorInfo",
			stringMapping: [
				"contextWindowExceeded": .contextWindowExceeded,
				"usageLimitExceeded": .usageLimitExceeded,
				"serverOverloaded": .serverOverloaded,
				"internalServerError": .internalServerError,
				"unauthorized": .unauthorized,
				"badRequest": .badRequest,
				"threadRollbackFailed": .threadRollbackFailed,
				"sandboxError": .sandboxError,
				"other": .other,
			]
		) { (_: KeyedDecodingContainer<CodingKeys>) in
			try CodexCoding.decodeKeyedOneOf(
				from: decoder,
				typeName: "CodexErrorInfo",
				tries: [
					(CodingKeys.httpConnectionFailed, { (container: KeyedDecodingContainer<CodingKeys>) in
						let nested = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .httpConnectionFailed)
						return .httpConnectionFailed(httpStatusCode: try nested.decodeIfPresent(Int.self, forKey: .httpStatusCode))
					}),
					(CodingKeys.responseStreamConnectionFailed, { (container: KeyedDecodingContainer<CodingKeys>) in
						let nested = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .responseStreamConnectionFailed)
						return .responseStreamConnectionFailed(httpStatusCode: try nested.decodeIfPresent(Int.self, forKey: .httpStatusCode))
					}),
					(CodingKeys.responseStreamDisconnected, { (container: KeyedDecodingContainer<CodingKeys>) in
						let nested = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .responseStreamDisconnected)
						return .responseStreamDisconnected(httpStatusCode: try nested.decodeIfPresent(Int.self, forKey: .httpStatusCode))
					}),
					(CodingKeys.responseTooManyFailedAttempts, { (container: KeyedDecodingContainer<CodingKeys>) in
						let nested = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .responseTooManyFailedAttempts)
						return .responseTooManyFailedAttempts(httpStatusCode: try nested.decodeIfPresent(Int.self, forKey: .httpStatusCode))
					}),
				]
			)
		}
	}

	public func encode(to encoder: any Encoder) throws {
		switch self {
		case .contextWindowExceeded, .usageLimitExceeded, .serverOverloaded, .internalServerError, .unauthorized, .badRequest, .threadRollbackFailed, .sandboxError, .other:
			switch self {
			case .contextWindowExceeded: try CodexCoding.encodeStringValue("contextWindowExceeded", to: encoder)
			case .usageLimitExceeded: try CodexCoding.encodeStringValue("usageLimitExceeded", to: encoder)
			case .serverOverloaded: try CodexCoding.encodeStringValue("serverOverloaded", to: encoder)
			case .internalServerError: try CodexCoding.encodeStringValue("internalServerError", to: encoder)
			case .unauthorized: try CodexCoding.encodeStringValue("unauthorized", to: encoder)
			case .badRequest: try CodexCoding.encodeStringValue("badRequest", to: encoder)
			case .threadRollbackFailed: try CodexCoding.encodeStringValue("threadRollbackFailed", to: encoder)
			case .sandboxError: try CodexCoding.encodeStringValue("sandboxError", to: encoder)
			case .other: try CodexCoding.encodeStringValue("other", to: encoder)
			default: break
			}
		case let .httpConnectionFailed(httpStatusCode):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(["httpStatusCode": httpStatusCode], forKey: .httpConnectionFailed)
		case let .responseStreamConnectionFailed(httpStatusCode):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(["httpStatusCode": httpStatusCode], forKey: .responseStreamConnectionFailed)
		case let .responseStreamDisconnected(httpStatusCode):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(["httpStatusCode": httpStatusCode], forKey: .responseStreamDisconnected)
		case let .responseTooManyFailedAttempts(httpStatusCode):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(["httpStatusCode": httpStatusCode], forKey: .responseTooManyFailedAttempts)
		}
	}
}

public enum SubAgentSource: Sendable, Codable, Equatable, Hashable {
	case review
	case compact
	case threadSpawn(parentThreadCodexId: String, depth: Int, agentNickname: String?, agentRole: String?)
	case memoryConsolidation
	case other(String)

	private enum CodingKeys: String, CodingKey {
		case threadSpawn = "thread_spawn"
		case parentThreadCodexId = "parent_thread_id"
		case depth
		case agentNickname = "agent_nickname"
		case agentRole = "agent_role"
		case other
	}

	public init(from decoder: any Decoder) throws {
		self = try CodexCoding.decodeStringOrObject(
			from: decoder,
			typeName: "SubAgentSource",
			stringMapping: [
				"review": .review,
				"compact": .compact,
				"memory_consolidation": .memoryConsolidation,
			]
		) { (_: KeyedDecodingContainer<CodingKeys>) in
			try CodexCoding.decodeKeyedOneOf(
				from: decoder,
				typeName: "SubAgentSource",
				tries: [
					(CodingKeys.threadSpawn, { (container: KeyedDecodingContainer<CodingKeys>) in
						let nested = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .threadSpawn)
						return .threadSpawn(
							parentThreadCodexId: try nested.decode(String.self, forKey: .parentThreadCodexId),
							depth: try nested.decode(Int.self, forKey: .depth),
							agentNickname: try nested.decodeIfPresent(String.self, forKey: .agentNickname),
							agentRole: try nested.decodeIfPresent(String.self, forKey: .agentRole)
						)
					}),
					(CodingKeys.other, { (container: KeyedDecodingContainer<CodingKeys>) in
						.other(try container.decode(String.self, forKey: .other))
					}),
				]
			)
		}
	}

	public func encode(to encoder: any Encoder) throws {
		switch self {
		case .review:
			try CodexCoding.encodeStringValue("review", to: encoder)
		case .compact:
			try CodexCoding.encodeStringValue("compact", to: encoder)
		case .memoryConsolidation:
			try CodexCoding.encodeStringValue("memory_consolidation", to: encoder)
		case let .threadSpawn(parentThreadCodexId, depth, agentNickname, agentRole):
			var container = encoder.container(keyedBy: CodingKeys.self)
			var nested = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .threadSpawn)
			try nested.encode(parentThreadCodexId, forKey: .parentThreadCodexId)
			try nested.encode(depth, forKey: .depth)
			try nested.encodeIfPresent(agentNickname, forKey: .agentNickname)
			try nested.encodeIfPresent(agentRole, forKey: .agentRole)
		case let .other(value):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(value, forKey: .other)
		}
	}
}

public enum ParsedCommand: Sendable, Codable, Equatable, Hashable {
	case read(cmd: String, name: String, path: String)
	case listFiles(cmd: String, path: String?)
	case search(cmd: String, query: String?, path: String?)
	case unknown(cmd: String)

	private enum CodingKeys: String, CodingKey {
		case type
		case cmd
		case name
		case path
		case query
	}

	private enum Kind: String, Codable {
		case read
		case listFiles = "list_files"
		case search
		case unknown
	}

	public init(from decoder: any Decoder) throws {
		let (kind, container) = try CodexCoding.decodeTaggedKind(
			from: decoder,
			codingKeys: CodingKeys.self,
			typeKey: .type,
			kindType: Kind.self,
			typeName: "ParsedCommand"
		)
		switch kind {
		case .read:
			self = .read(
				cmd: try container.decode(String.self, forKey: .cmd),
				name: try container.decode(String.self, forKey: .name),
				path: try container.decode(String.self, forKey: .path)
			)
		case .listFiles:
			self = .listFiles(
				cmd: try container.decode(String.self, forKey: .cmd),
				path: try container.decodeIfPresent(String.self, forKey: .path)
			)
		case .search:
			self = .search(
				cmd: try container.decode(String.self, forKey: .cmd),
				query: try container.decodeIfPresent(String.self, forKey: .query),
				path: try container.decodeIfPresent(String.self, forKey: .path)
			)
		case .unknown:
			self = .unknown(cmd: try container.decode(String.self, forKey: .cmd))
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .read(cmd, name, path):
			try container.encode(Kind.read, forKey: .type)
			try container.encode(cmd, forKey: .cmd)
			try container.encode(name, forKey: .name)
			try container.encode(path, forKey: .path)
		case let .listFiles(cmd, path):
			try container.encode(Kind.listFiles, forKey: .type)
			try container.encode(cmd, forKey: .cmd)
			try container.encodeIfPresent(path, forKey: .path)
		case let .search(cmd, query, path):
			try container.encode(Kind.search, forKey: .type)
			try container.encode(cmd, forKey: .cmd)
			try container.encodeIfPresent(query, forKey: .query)
			try container.encodeIfPresent(path, forKey: .path)
		case let .unknown(cmd):
			try container.encode(Kind.unknown, forKey: .type)
			try container.encode(cmd, forKey: .cmd)
		}
	}
}

public enum FileChange: Sendable, Codable, Equatable, Hashable {
	case add(content: String)
	case delete(content: String)
	case update(unifiedDiff: String, movePath: String?)

	private enum CodingKeys: String, CodingKey {
		case type
		case content
		case unifiedDiff = "unified_diff"
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
			typeName: "FileChange"
		)
		switch kind {
		case .add:
			self = .add(content: try container.decode(String.self, forKey: .content))
		case .delete:
			self = .delete(content: try container.decode(String.self, forKey: .content))
		case .update:
			self = .update(
				unifiedDiff: try container.decode(String.self, forKey: .unifiedDiff),
				movePath: try container.decodeIfPresent(String.self, forKey: .movePath)
			)
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .add(content):
			try container.encode(Kind.add, forKey: .type)
			try container.encode(content, forKey: .content)
		case let .delete(content):
			try container.encode(Kind.delete, forKey: .type)
			try container.encode(content, forKey: .content)
		case let .update(unifiedDiff, movePath):
			try container.encode(Kind.update, forKey: .type)
			try container.encode(unifiedDiff, forKey: .unifiedDiff)
			try container.encodeIfPresent(movePath, forKey: .movePath)
		}
	}
}
