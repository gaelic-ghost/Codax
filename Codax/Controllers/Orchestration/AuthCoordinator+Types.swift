//
//  AuthCoordinator+Types.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: - Orchestration Layer Auth Types

public enum AuthMode: String, Sendable, Codable {
	case apikey
	case chatgpt
	case chatgptAuthTokens
}

public enum PlanType: String, Sendable, Codable {
	case free
	case go
	case plus
	case pro
	case team
	case business
	case enterprise
	case edu
	case unknown
}

public enum LoginState: Sendable {
	case signedOut
	case authorizing
	case signedIn
	case failed(String)
}

public enum Account: Sendable, Codable {
	case apiKey
	case chatgpt(email: String, planType: PlanType)

	private enum CodingKeys: String, CodingKey {
		case type
		case email
		case planType
	}

	private enum Kind: String, Codable {
		case apiKey
		case chatgpt
	}

	public init(from decoder: any Decoder) throws {
		let (kind, container) = try CodexCoding.decodeTaggedKind(
			from: decoder,
			codingKeys: CodingKeys.self,
			typeKey: .type,
			kindType: Kind.self,
			typeName: "Account"
		)
		switch kind {
		case .apiKey:
			self = .apiKey
		case .chatgpt:
			self = .chatgpt(
				email: try container.decode(String.self, forKey: .email),
				planType: try container.decode(PlanType.self, forKey: .planType)
			)
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
			case .apiKey:
				try container.encode(Kind.apiKey, forKey: .type)
			case let .chatgpt(email, planType):
				try container.encode(Kind.chatgpt, forKey: .type)
				try container.encode(email, forKey: .email)
				try container.encode(planType, forKey: .planType)
		}
	}
}
