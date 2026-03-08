//
//  CodaxOrchestrator.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import Observation

// App Session Management and UI Drive

@Observable
final class CodaxOrchestrator {

	var account: Account?
	var authMode: AuthMode?
	var threads: [ThreadSummary] = []
	var activeThread: Thread?
	var connectionState: ConnectionState = .disconnected
	var loginState: LoginState = .signedOut

	private let client: CodexClient?

	init() {
		self.client = nil
	}

	func connect() async -> () {

	}

	func loginWithChatGPT() async -> () {

	}

	func loadThreads() async -> () {

	}

	func startThread() async -> () {

	}

	func startTurn() async -> () {

	}

	func handle(_ notification: ServerNotificationEnvelope) -> () {

	}

}
