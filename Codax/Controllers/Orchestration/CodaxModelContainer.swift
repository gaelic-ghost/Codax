//
//  CodaxModelContainer.swift
//  Codax
//
//  Created by Codex on 3/12/26.
//

import SwiftData

// MARK: - Model Container

func makeCodaxModelContainer(inMemory: Bool? = nil) throws -> ModelContainer {
	let shouldUseInMemory: Bool
	if let inMemory {
		shouldUseInMemory = inMemory
	} else {
		#if DEBUG
		shouldUseInMemory = true
		#else
		shouldUseInMemory = false
		#endif
	}

	let schema = Schema([
		Project.self,
		ThreadModel.self,
		ThreadSessionModel.self,
		ThreadGitDiffModel.self,
		PendingServerRequestModel.self,
		TurnModel.self,
		TurnPlanModel.self,
		TurnDiffModel.self,
		ItemModel.self,
	])
	let configuration = ModelConfiguration(isStoredInMemoryOnly: shouldUseInMemory)
	return try ModelContainer(for: schema, configurations: configuration)
}
