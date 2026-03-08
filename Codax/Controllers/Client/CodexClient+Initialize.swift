//
//  CodexClient+Initialize.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: Initialization/Startup

public struct ClientInfo: Sendable, Codable {
	public var name: String
	public var title: String?
	public var version: String
}

public struct InitializeCapabilities: Sendable, Codable {
	public var experimentalApi: Bool
	public var optOutNotificationMethods: [String]?
}

public struct InitializeParams: Sendable, Codable {
	public var clientInfo: ClientInfo
	public var capabilities: InitializeCapabilities?
}

public struct InitializeResponse: Sendable, Codable {
	public var userAgent: String
}
