//
//  CodexClient+CollaborationTypes.swift
//  Codax
//
//  Created by Codex on 3/10/26.
//

import Foundation

public enum ServiceTier: String, Sendable, Codable, Equatable, Hashable {
	case fast
	case flex
}

public enum ReasoningEffort: String, Sendable, Codable, Equatable, Hashable {
	case none
	case minimal
	case low
	case medium
	case high
	case xhigh
}

public enum Personality: String, Sendable, Codable, Equatable, Hashable {
	case none
	case friendly
	case pragmatic
}

public enum CollaborationModeKind: String, Sendable, Codable, Equatable, Hashable {
	case plan
	case `default`
}

public struct CollaborationModeSettings: Sendable, Codable, Equatable, Hashable {
	public var model: String
	public var reasoningEffort: ReasoningEffort?
	public var developerInstructions: String?

	private enum CodingKeys: String, CodingKey {
		case model
		case reasoningEffort = "reasoning_effort"
		case developerInstructions = "developer_instructions"
	}
}

public struct CollaborationMode: Sendable, Codable, Equatable, Hashable {
	public var mode: CollaborationModeKind
	public var settings: CollaborationModeSettings
}

public enum AskForApproval: Sendable, Codable, Equatable, Hashable {
	case untrusted
	case onFailure
	case onRequest
	case reject(AskForApprovalReject)
	case never

	private enum CodingKeys: String, CodingKey {
		case reject
	}

	public init(from decoder: any Decoder) throws {
		self = try CodexCoding.decodeStringOrObject(
			from: decoder,
			typeName: "AskForApproval",
			stringMapping: [
				"untrusted": .untrusted,
				"on-failure": .onFailure,
				"on-request": .onRequest,
				"never": .never,
			]
		) { (container: KeyedDecodingContainer<CodingKeys>) in
			.reject(try container.decode(AskForApprovalReject.self, forKey: .reject))
		}
	}

	public func encode(to encoder: any Encoder) throws {
		switch self {
		case .untrusted, .onFailure, .onRequest, .never:
			switch self {
			case .untrusted: try CodexCoding.encodeStringValue("untrusted", to: encoder)
			case .onFailure: try CodexCoding.encodeStringValue("on-failure", to: encoder)
			case .onRequest: try CodexCoding.encodeStringValue("on-request", to: encoder)
			case .never: try CodexCoding.encodeStringValue("never", to: encoder)
			case .reject: break
			}
		case let .reject(value):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(value, forKey: .reject)
		}
	}
}

public struct AskForApprovalReject: Sendable, Codable, Equatable, Hashable {
	public var sandboxApproval: Bool
	public var rules: Bool
	public var mcpElicitations: Bool

	private enum CodingKeys: String, CodingKey {
		case sandboxApproval = "sandbox_approval"
		case rules
		case mcpElicitations = "mcp_elicitations"
	}
}
