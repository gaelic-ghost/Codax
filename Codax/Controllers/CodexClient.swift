//
//  CodexClient.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import Foundation

// MARK: - API Client

public actor CodexClient {
	private let connection: CodexConnection

	public init(connection: CodexConnection) {
		self.connection = connection
	}

	public func initialize(_ params: InitializeParams) async throws -> InitializeResponse {
		try await connection.request(method: "initialize", params: params, as: InitializeResponse.self)
	}

	public func sendInitialized() async throws -> () {
		try await connection.notify(method: "initialized")
	}

	public func startThread(_ params: ThreadStartParams) async throws -> ThreadStartResponse {
		try await connection.request(method: "thread/start", params: params, as: ThreadStartResponse.self)
	}

	public func resumeThread(_ params: ThreadResumeParams) async throws -> ThreadResumeResponse {
		try await connection.request(method: "thread/resume", params: params, as: ThreadResumeResponse.self)
	}

	public func readThread(_ params: ThreadReadParams) async throws -> ThreadReadResponse {
		try await connection.request(method: "thread/read", params: params, as: ThreadReadResponse.self)
	}

	public func startTurn(_ params: TurnStartParams) async throws -> TurnStartResponse {
		try await connection.request(method: "turn/start", params: params, as: TurnStartResponse.self)
	}

	public func interruptTurn(_ params: TurnInterruptParams) async throws -> TurnInterruptResponse {
		try await connection.request(method: "turn/interrupt", params: params, as: TurnInterruptResponse.self)
	}

	public func readAccount(_ params: GetAccountParams) async throws -> GetAccountResponse {
		try await connection.request(method: "account/read", params: params, as: GetAccountResponse.self)
	}

	public func startLogin(_ params: LoginAccountParams) async throws -> LoginAccountResponse {
		try await connection.request(method: "account/login/start", params: params, as: LoginAccountResponse.self)
	}

	public func cancelLogin(_ params: CancelLoginAccountParams) async throws -> CancelLoginAccountResponse {
		try await connection.request(method: "account/login/cancel", params: params, as: CancelLoginAccountResponse.self)
	}
}
