//
//  AuthCoordinator+Types.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: - Auth Layer Types

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
		let container = try decoder.container(keyedBy: CodingKeys.self)
		switch try container.decode(Kind.self, forKey: .type) {
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

public struct GetAccountParams: Sendable, Codable {
	public var refreshToken: Bool

	public init(refreshToken: Bool) {
		self.refreshToken = refreshToken
	}
}

public struct GetAccountResponse: Sendable, Codable {
	public var account: Account?
	public var requiresOpenaiAuth: Bool
}

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
		let container = try decoder.container(keyedBy: CodingKeys.self)
		switch try container.decode(Kind.self, forKey: .type) {
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
		let container = try decoder.container(keyedBy: CodingKeys.self)
		switch try container.decode(Kind.self, forKey: .type) {
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

public struct CancelLoginAccountParams: Sendable, Codable {
	public var loginId: String

	public init(loginId: String) {
		self.loginId = loginId
	}
}

public enum CancelLoginAccountStatus: String, Sendable, Codable {
	case canceled
	case notFound
}

public struct CancelLoginAccountResponse: Sendable, Codable {
	public var status: CancelLoginAccountStatus
}

public struct ChatgptAuthTokensRefreshParams: Sendable, Codable {
	public var reason: String
	public var previousAccountId: String?
}

public struct ChatgptAuthTokensRefreshResponse: Sendable, Codable {
	public var accessToken: String
	public var chatgptAccountId: String
	public var chatgptPlanType: String?
}
