//
//  CodexClient+AccountTypes.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: - Client Layer Account/Auth Types

	// MARK: Get Account

public struct GetAccountResponse: Sendable, Codable {
	public var account: Account?
	public var requiresOpenaiAuth: Bool
}

public struct GetAccountParams: Sendable, Codable {
	public var refreshToken: Bool

	public init(refreshToken: Bool) {
		self.refreshToken = refreshToken
	}
}

	// MARK: Cancel Login

public enum CancelLoginAccountStatus: String, Sendable, Codable {
	case canceled
	case notFound
}

public struct CancelLoginAccountResponse: Sendable, Codable {
	public var status: CancelLoginAccountStatus
}

public struct CancelLoginAccountParams: Sendable, Codable {
	public var loginId: String

	public init(loginId: String) {
		self.loginId = loginId
	}
}

	// MARK: Login

public enum LoginAccountParams: Sendable, Codable {
	case apiKey(apiKey: String)
	case chatgpt
	case chatgptAuthTokens(accessToken: String, chatgptAccountId: String, chatgptPlanType: String?)

	private enum CodingKeys: String, CodingKey {
		case type
		case apiKey
		case accessToken
		case chatgptAccountId
		case chatgptPlanType
	}

	private enum Kind: String, Codable {
		case apiKey
		case chatgpt
		case chatgptAuthTokens
	}

	public init(from decoder: any Decoder) throws {
		let (kind, container) = try CodexCoding.decodeTaggedKind(
			from: decoder,
			codingKeys: CodingKeys.self,
			typeKey: .type,
			kindType: Kind.self,
			typeName: "LoginAccountParams"
		)
		switch kind {
				case .apiKey:
					self = .apiKey(apiKey: try container.decode(String.self, forKey: .apiKey))
				case .chatgpt:
				self = .chatgpt
			case .chatgptAuthTokens:
				self = .chatgptAuthTokens(
					accessToken: try container.decode(String.self, forKey: .accessToken),
					chatgptAccountId: try container.decode(String.self, forKey: .chatgptAccountId),
					chatgptPlanType: try container.decodeIfPresent(String.self, forKey: .chatgptPlanType)
				)
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
			case let .apiKey(apiKey):
				try container.encode(Kind.apiKey, forKey: .type)
				try container.encode(apiKey, forKey: .apiKey)
			case .chatgpt:
				try container.encode(Kind.chatgpt, forKey: .type)
			case let .chatgptAuthTokens(accessToken, chatgptAccountId, chatgptPlanType):
				try container.encode(Kind.chatgptAuthTokens, forKey: .type)
				try container.encode(accessToken, forKey: .accessToken)
				try container.encode(chatgptAccountId, forKey: .chatgptAccountId)
				try container.encodeIfPresent(chatgptPlanType, forKey: .chatgptPlanType)
		}
	}
}

public enum LoginAccountResponse: Sendable, Codable {
	case apiKey
	case chatgpt(loginId: String, authURL: URL)
	case chatgptAuthTokens

	private enum CodingKeys: String, CodingKey {
		case type
		case loginId
		case authUrl
	}

	private enum Kind: String, Codable {
		case apiKey
		case chatgpt
		case chatgptAuthTokens
	}

	public init(from decoder: any Decoder) throws {
		let (kind, container) = try CodexCoding.decodeTaggedKind(
			from: decoder,
			codingKeys: CodingKeys.self,
			typeKey: .type,
			kindType: Kind.self,
			typeName: "LoginAccountResponse"
		)
		switch kind {
				case .apiKey:
					self = .apiKey
				case .chatgpt:
				self = .chatgpt(
					loginId: try container.decode(String.self, forKey: .loginId),
					authURL: try container.decode(URL.self, forKey: .authUrl)
				)
			case .chatgptAuthTokens:
				self = .chatgptAuthTokens
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
			case .apiKey:
				try container.encode(Kind.apiKey, forKey: .type)
			case let .chatgpt(loginId, authURL):
				try container.encode(Kind.chatgpt, forKey: .type)
				try container.encode(loginId, forKey: .loginId)
				try container.encode(authURL, forKey: .authUrl)
			case .chatgptAuthTokens:
				try container.encode(Kind.chatgptAuthTokens, forKey: .type)
		}
	}
}
