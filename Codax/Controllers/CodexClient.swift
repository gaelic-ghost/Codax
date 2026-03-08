//
//  CodexClient.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import Foundation

// MARK: - API Client

public actor CodexClient {
	public init(connection: CodexConnection) {

	}

	public func initialize(_ params: InitializeParams) async throws -> InitializeResponse {

	}

	public func sendInitialized() async throws -> () {

	}

	public func startThread(_ params: ThreadStartParams) async throws -> ThreadStartResponse {

	}

	public func resumeThread(_ params: ThreadResumeParams) async throws -> ThreadResumeResponse {

	}

	public func readThread(_ params: ThreadReadParams) async throws -> ThreadReadResponse {

	}

	public func startTurn(_ params: TurnStartParams) async throws -> TurnStartResponse {

	}

	public func interruptTurn(_ params: TurnInterruptParams) async throws -> TurnInterruptResponse {

	}

	public func readAccount(_ params: GetAccountParams) async throws -> GetAccountResponse {

	}

	public func startLogin(_ params: LoginAccountParams) async throws -> LoginAccountResponse {

	}

	public func cancelLogin(_ params: CancelLoginAccountParams) async throws -> CancelLoginAccountResponse {

	}
}
