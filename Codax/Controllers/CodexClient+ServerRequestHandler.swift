//
//  CodexClient+ServerRequestHandler.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

public protocol CodexServerRequestHandler: Sendable {
	func handle(_ request: ServerRequestEnvelope) async -> ServerRequestResult
}
