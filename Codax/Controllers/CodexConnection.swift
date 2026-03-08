//
//  CodexConnection.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import Foundation

public actor CodexConnection {

	let trans: CodexTransport
	let reqHandler: CodexServerRequestHandler?

	public init(
		transport tr: any CodexTransport,
		requestHandler rH: (any CodexServerRequestHandler)? = nil
	) {
		self.trans = tr
		self.reqHandler = rH
	}

	public func start() async -> () {

	}
	public func stop() async -> () {

	}

	public func request<Params: Encodable, Result: Decodable>(
		method: String,
		params: Params,
		as resultType: Result.Type
	) async throws -> Result {

	}

	public func notify<Params: Encodable>(
		method: String,
		params: Params
	) async throws -> () {

	}

	public func notifications() -> AsyncStream<ServerNotificationEnvelope> {

	}
}

