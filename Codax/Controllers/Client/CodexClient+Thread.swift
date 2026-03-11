//
//  CodexClient+Thread.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: - Client Layer `Thread` Types

	// MARK: Base Type

public struct Thread: Identifiable, Sendable, Codable, Equatable, Hashable, CodexClientIdentifiable {
	public var id: UUID
	public var codexId: String
	public var preview: String
	public var ephemeral: Bool
	public var modelProvider: String
	public var createdAt: Int
	public var updatedAt: Int
	public var status: ThreadStatus
	public var path: String?
	public var cwd: String
	public var cliVersion: String
	public var source: SessionSource?
	// TODO: Check if this is applicable.
	public var agentNickname: String?
	public var agentRole: String?
	public var gitInfo: GitInfo?
	public var name: String?
	public var turns: [Turn]

	private enum CodingKeys: String, CodingKey {
		case codexId = "id"
		case preview
		case ephemeral
		case modelProvider
		case createdAt
		case updatedAt
		case status
		case path
		case cwd
		case cliVersion
		case source
		case agentNickname
		case agentRole
		case gitInfo
		case name
		case turns
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.codexId = try container.decode(String.self, forKey: .codexId)
		self.id = ClientIdentity.thread(self.codexId)
		self.preview = try container.decode(String.self, forKey: .preview)
		self.ephemeral = try container.decode(Bool.self, forKey: .ephemeral)
		self.modelProvider = try container.decode(String.self, forKey: .modelProvider)
		self.createdAt = try container.decode(Int.self, forKey: .createdAt)
		self.updatedAt = try container.decode(Int.self, forKey: .updatedAt)
		self.status = try container.decode(ThreadStatus.self, forKey: .status)
		self.path = try container.decodeIfPresent(String.self, forKey: .path)
		self.cwd = try container.decode(String.self, forKey: .cwd)
		self.cliVersion = try container.decode(String.self, forKey: .cliVersion)
		self.source = try container.decodeIfPresent(SessionSource.self, forKey: .source)
		self.agentNickname = try container.decodeIfPresent(String.self, forKey: .agentNickname)
		self.agentRole = try container.decodeIfPresent(String.self, forKey: .agentRole)
		self.gitInfo = try container.decodeIfPresent(GitInfo.self, forKey: .gitInfo)
		self.name = try container.decodeIfPresent(String.self, forKey: .name)
		self.turns = try container.decode([Turn].self, forKey: .turns)
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(codexId, forKey: .codexId)
		try container.encode(preview, forKey: .preview)
		try container.encode(ephemeral, forKey: .ephemeral)
		try container.encode(modelProvider, forKey: .modelProvider)
		try container.encode(createdAt, forKey: .createdAt)
		try container.encode(updatedAt, forKey: .updatedAt)
		try container.encode(status, forKey: .status)
		try container.encode(path, forKey: .path)
		try container.encode(cwd, forKey: .cwd)
		try container.encode(cliVersion, forKey: .cliVersion)
		try container.encode(source, forKey: .source)
		try container.encode(agentNickname, forKey: .agentNickname)
		try container.encode(agentRole, forKey: .agentRole)
		try container.encode(gitInfo, forKey: .gitInfo)
		try container.encode(name, forKey: .name)
		try container.encode(turns, forKey: .turns)
	}
}

	// MARK: Params

public struct ThreadStartParams: Sendable, Codable {
	public var model: String?
	public var modelProvider: String?
	public var serviceTier: ServiceTier?
	public var cwd: String?
	public var approvalPolicy: AskForApproval?
	public var sandbox: SandboxMode?
	public var config: [String: CodexValue]?
	public var serviceName: String?
	public var baseInstructions: String?
	public var developerInstructions: String?
	public var personality: Personality?
	public var ephemeral: Bool?
	public var experimentalRawEvents: Bool
	public var persistExtendedHistory: Bool
}

public struct ThreadResumeParams: Sendable, Codable {
	public var threadCodexId: String
	public var history: [CodexValue]?
	public var path: String?
	public var model: String?
	public var modelProvider: String?
	public var serviceTier: ServiceTier?
	public var cwd: String?
	public var approvalPolicy: AskForApproval?
	public var sandbox: SandboxMode?
	public var config: [String: CodexValue]?
	public var baseInstructions: String?
	public var developerInstructions: String?
	public var personality: Personality?
	public var persistExtendedHistory: Bool

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case history
		case path
		case model
		case modelProvider
		case serviceTier
		case cwd
		case approvalPolicy
		case sandbox
		case config
		case baseInstructions
		case developerInstructions
		case personality
		case persistExtendedHistory
	}
}

public struct ThreadReadParams: Sendable, Codable {
	public var threadCodexId: String
	public var includeTurns: Bool

	private enum CodingKeys: String, CodingKey {
		case threadCodexId = "threadId"
		case includeTurns
	}
}

	// MARK: Responses

public struct ThreadStartResponse: Sendable, Codable {
	public var thread: Thread
	public var model: String
	public var modelProvider: String
	public var serviceTier: ServiceTier?
	public var cwd: String
	public var approvalPolicy: AskForApproval
	public var sandbox: SandboxPolicy
	public var reasoningEffort: ReasoningEffort?
}

public struct ThreadResumeResponse: Sendable, Codable {
	public var thread: Thread
	public var model: String
	public var modelProvider: String
	public var serviceTier: ServiceTier?
	public var cwd: String
	public var approvalPolicy: AskForApproval
	public var sandbox: SandboxPolicy
	public var reasoningEffort: ReasoningEffort?
}

public struct ThreadReadResponse: Sendable, Codable {
	public var thread: Thread
}

	// MARK: Notifications

public struct ThreadStartedNotification: Sendable, Codable {
	public var thread: Thread
}

	// MARK: Errors


	// MARK: Other

public struct GitInfo: Sendable, Codable, Equatable, Hashable {
	public var sha: String?
	public var branch: String?
		// TODO: Use Foundation.URL
	public var originUrl: String?
}

public enum SessionSource: Sendable, Codable, Equatable, Hashable {
	case cli
	case vscode
	case exec
	case appServer
	case subAgent(SubAgentSource)
	case unknown

	public init(from decoder: any Decoder) throws {
		self = try CodexCoding.decodeStringOrObject(
			from: decoder,
			typeName: "SessionSource",
			stringMapping: [
				"cli": .cli,
				"vscode": .vscode,
				"exec": .exec,
				"appServer": .appServer,
				"unknown": .unknown,
			]
		) { (container: KeyedDecodingContainer<CodingKeys>) in
			.subAgent(try container.decode(SubAgentSource.self, forKey: .subAgent))
		}
	}

	public func encode(to encoder: any Encoder) throws {
		switch self {
			case .cli:
				try CodexCoding.encodeStringValue("cli", to: encoder)
			case .vscode:
				try CodexCoding.encodeStringValue("vscode", to: encoder)
			case .exec:
				try CodexCoding.encodeStringValue("exec", to: encoder)
			case .appServer:
				try CodexCoding.encodeStringValue("appServer", to: encoder)
			case let .subAgent(rawValue):
				var container = encoder.container(keyedBy: CodingKeys.self)
				try container.encode(rawValue, forKey: .subAgent)
			case .unknown:
				try CodexCoding.encodeStringValue("unknown", to: encoder)
		}
	}

	private enum CodingKeys: String, CodingKey {
		case subAgent
	}
}
