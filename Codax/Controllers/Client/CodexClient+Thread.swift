//
//  CodexClient+Thread.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: - Client Layer `Thread` Types

public struct GitInfo: Sendable, Codable, Equatable {
	public var sha: String?
	public var branch: String?
	// TODO: Use Foundation.URL
	public var originUrl: String?
}

// TODO: Determine if applicable to our client.
public enum SessionSource: Sendable, Codable, Equatable {
	case cli
	case vscode
	case exec
	case appServer
	case subAgent(JSONValue)
	case unknown

	public init(from decoder: any Decoder) throws {
		let value = try JSONValue(from: decoder)
		switch value {
		case let .string(rawValue):
			switch rawValue {
			case "cli":
				self = .cli
			case "vscode":
				self = .vscode
			case "exec":
				self = .exec
			case "appServer":
				self = .appServer
			case "unknown":
				self = .unknown
			default:
				throw DecodingError.dataCorrupted(
					.init(codingPath: decoder.codingPath, debugDescription: "Unsupported SessionSource value: \(rawValue)")
				)
			}
		case let .object(object):
			if let subAgent = object["subAgent"] {
				self = .subAgent(subAgent)
			} else {
				throw DecodingError.dataCorrupted(
					.init(codingPath: decoder.codingPath, debugDescription: "Unsupported SessionSource object payload.")
				)
			}
		default:
			throw DecodingError.dataCorrupted(
				.init(codingPath: decoder.codingPath, debugDescription: "Unsupported SessionSource payload.")
			)
		}
	}

	public func encode(to encoder: any Encoder) throws {
		switch self {
		case .cli:
			try JSONValue.string("cli").encode(to: encoder)
		case .vscode:
			try JSONValue.string("vscode").encode(to: encoder)
		case .exec:
			try JSONValue.string("exec").encode(to: encoder)
		case .appServer:
			try JSONValue.string("appServer").encode(to: encoder)
		case let .subAgent(rawValue):
			try JSONValue.object(["subAgent": rawValue]).encode(to: encoder)
		case .unknown:
			try JSONValue.string("unknown").encode(to: encoder)
		}
	}
}

	// MARK: Base Type

public struct Thread: Sendable, Codable, Equatable {
	public var id: String
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
}

	// MARK: Params

public struct ThreadStartParams: Sendable, Codable {
	public var model: String?
	public var modelProvider: String?
	public var serviceTier: ServiceTier?
	public var cwd: String?
	public var approvalPolicy: AskForApproval?
	public var sandbox: SandboxMode?
	public var config: [String: JSONValue]?
	public var serviceName: String?
	public var baseInstructions: String?
	public var developerInstructions: String?
	public var personality: Personality?
	public var ephemeral: Bool?
	public var experimentalRawEvents: Bool
	public var persistExtendedHistory: Bool
}

public struct ThreadResumeParams: Sendable, Codable {
	public var threadId: String
	public var history: [JSONValue]?
	public var path: String?
	public var model: String?
	public var modelProvider: String?
	public var serviceTier: ServiceTier?
	public var cwd: String?
	public var approvalPolicy: AskForApproval?
	public var sandbox: SandboxMode?
	public var config: [String: JSONValue]?
	public var baseInstructions: String?
	public var developerInstructions: String?
	public var personality: Personality?
	public var persistExtendedHistory: Bool
}

public struct ThreadReadParams: Sendable, Codable {
	public var threadId: String
	public var includeTurns: Bool
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

public typealias ThreadResumeResponse = ThreadStartResponse

public struct ThreadReadResponse: Sendable, Codable {
	public var thread: Thread
}

	// MARK: Notifications

public struct ThreadStartedNotification: Sendable, Codable {
	public var thread: Thread
}

	// MARK: Errors
