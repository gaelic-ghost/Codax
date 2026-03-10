//
//  CodaxOrchestrator.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import Observation

// MARK: - App Session Management and UI Drive

// MARK: Concrete Implementation

@MainActor
@Observable
final class CodaxOrchestrator {

	var account: Account?
	var authMode: AuthMode?
	var threads: [ThreadSummary] = []
	var activeThread: Thread?
	var connectionState: ConnectionState = .disconnected
	var loginState: LoginState = .signedOut
	var compatibility: CodaxCompatibilityState = .unknown

	private let client: CodexClient?
	private let compatibilityProbe: CodexCLIProbe
	private let sessionStarter: (@Sendable () async throws -> Void)?

	init() {
		self.client = nil
		self.compatibilityProbe = CodexCLIProbe()
		self.sessionStarter = nil
	}

	internal init(
		client: CodexClient? = nil,
		compatibilityProbe: CodexCLIProbe,
		sessionStarter: (@Sendable () async throws -> Void)? = nil
	) {
		self.client = client
		self.compatibilityProbe = compatibilityProbe
		self.sessionStarter = sessionStarter
	}

	func connect() async -> () {
		await refreshCompatibility()
		guard case .supported = compatibility else {
			connectionState = .disconnected
			return
		}
		guard let sessionStarter else { return }

		connectionState = .connecting
		do {
			try await sessionStarter()
			connectionState = .connected
		} catch {
			connectionState = .disconnected
		}
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

	func refreshCompatibility() async -> () {
		compatibility = .checking
		compatibility = CodaxCompatibilityState(await compatibilityProbe.probeCompatibility())
	}

}
