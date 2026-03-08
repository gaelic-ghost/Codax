//
//  CodexClient+ServerRequestHandler.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

	// MARK: - Client Layer Server Request Handler

	// MARK: Protocol

public protocol CodexServerRequestHandler: Sendable {
	func handle(_ request: ServerRequestEnvelope) async -> ServerRequestResult
}

	// MARK: Concrete Implementation
