//
//  CodaxOrchestrator.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Observation

@Observable
final class CodaxOrchestrator {

	let appService = ApplicationService()
	let configAndTools = ConfigAndToolingService()
	let convoService = ConversationService()
	let serverNotifs = ServerNotificationService()
	let serverReqs = ServerRequestService()
	let runtime = CodexRuntimeCoordinator()

	init() {

	}

}
