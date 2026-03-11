//
//  CodaxPersistenceBridge.swift
//  Codax
//
//  Created by Codex on 3/11/26.
//

import Foundation
import SwiftData

// MARK: - Persistence Bridge

@MainActor
final class CodaxPersistenceBridge {
	private let modelContainer: ModelContainer
	private let modelContext: ModelContext

	init(modelContainer: ModelContainer) {
		self.modelContainer = modelContainer
		self.modelContext = modelContainer.mainContext
	}

	static func makeModelContainer(inMemory: Bool = false) throws -> ModelContainer {
		let schema = Schema([
			Project.self,
			ThreadModel.self,
			TurnModel.self,
			ItemModel.self,
		])
		let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
		return try ModelContainer(for: schema, configurations: configuration)
	}

	func fetchThread(codexId: String) throws -> ThreadModel? {
		let descriptor = FetchDescriptor<ThreadModel>(
			predicate: #Predicate<ThreadModel> { $0.codexId == codexId }
		)
		return try modelContext.fetch(descriptor).first
	}

	func persistThreadList(_ threads: [Thread]) throws {
		for thread in threads {
			let project = ensureProject(rootPath: thread.cwd)
			let model = try fetchThread(codexId: thread.id) ?? ThreadModel(
				thread: thread,
				project: project,
				hydrationState: .summary
			)
			model.project = project
			model.applySummary(thread: thread)
			if model.modelContext == nil {
				modelContext.insert(model)
			}
		}
		try saveIfNeeded()
	}

	func persistThreadDetail(_ thread: Thread) throws {
		let project = ensureProject(rootPath: thread.cwd)
			let model = try fetchThread(codexId: thread.id) ?? ThreadModel(
			thread: thread,
			project: project,
			hydrationState: .detail
		)
		model.project = project
		model.applyDetail(thread: thread)
		reconcileTurns(thread.turns, on: model)
		if model.modelContext == nil {
			modelContext.insert(model)
		}
		try saveIfNeeded()
	}

	func persistTurn(_ turn: Turn, threadCodexId: String) throws {
		guard let thread = try fetchThread(codexId: threadCodexId) else { return }
		if let existing = thread.turns.first(where: { $0.codexId == turn.id }) {
			existing.apply(turn: turn)
		} else {
			let model = TurnModel(turn: turn, thread: thread)
			thread.turns.append(model)
			if model.modelContext == nil {
				modelContext.insert(model)
			}
		}
		thread.lastHydratedAt = .now
		thread.hydrationState = .detail
		try saveIfNeeded()
	}

	func persistThreadStatus(_ status: ThreadStatus, for threadCodexId: String) throws {
		guard let thread = try fetchThread(codexId: threadCodexId) else { return }
		thread.setStatus(status)
		try saveIfNeeded()
	}

	func persistThreadName(_ name: String?, for threadCodexId: String) throws {
		guard let thread = try fetchThread(codexId: threadCodexId) else { return }
		thread.name = name
		try saveIfNeeded()
	}

	func persistThreadTokenUsage(_ tokenUsage: ThreadTokenUsage?, for threadCodexId: String) throws {
		guard let thread = try fetchThread(codexId: threadCodexId) else { return }
		thread.setTokenUsage(tokenUsage)
		try saveIfNeeded()
	}

	func persistThreadArchived(_ isArchived: Bool, for threadCodexId: String) throws {
		guard let thread = try fetchThread(codexId: threadCodexId) else { return }
		thread.setArchived(isArchived)
		try saveIfNeeded()
	}

	func persistThreadClosed(for threadCodexId: String) throws {
		guard let thread = try fetchThread(codexId: threadCodexId) else { return }
		thread.setClosed(true)
		try saveIfNeeded()
	}

	func shouldHydrateThreadDetail(codexId: String, maxAge: TimeInterval) throws -> Bool {
		guard let thread = try fetchThread(codexId: codexId) else { return true }
		guard thread.hydrationState == .detail else { return true }
		guard let lastHydratedAt = thread.lastHydratedAt else { return true }
		return Date().timeIntervalSince(lastHydratedAt) > maxAge
	}

	func recentThreadCodexIDs(limit: Int, excluding excludedCodexId: String?) throws -> [String] {
		var descriptor = FetchDescriptor<ThreadModel>(
			sortBy: [SortDescriptor(\ThreadModel.updatedAt, order: .reverse)]
		)
		descriptor.fetchLimit = max(limit + (excludedCodexId == nil ? 0 : 1), limit)
		return try modelContext.fetch(descriptor)
			.filter { thread in
				!thread.isArchived && !thread.isClosed && thread.codexId != excludedCodexId
			}
			.prefix(limit)
			.map(\.codexId)
	}
}

// MARK: - Private Helpers

private extension CodaxPersistenceBridge {
	func ensureProject(rootPath: String) -> Project {
		let descriptor = FetchDescriptor<Project>(
			predicate: #Predicate<Project> { $0.rootPath == rootPath }
		)
		if let project = try? modelContext.fetch(descriptor).first {
			project.updatedAt = .now
			project.isActive = true
			return project
		}

		let name = URL(fileURLWithPath: rootPath).lastPathComponent
		let project = Project(
			name: name.isEmpty ? rootPath : name,
			rootPath: rootPath,
			isActive: true
		)
		modelContext.insert(project)
		return project
	}

	func reconcileTurns(_ turns: [Turn], on thread: ThreadModel) {
		let incomingTurnIDs = Set(turns.map(\.id))
		for turn in turns {
			if let existing = thread.turns.first(where: { $0.codexId == turn.id }) {
				existing.apply(turn: turn)
			} else {
				let model = TurnModel(turn: turn, thread: thread)
				thread.turns.append(model)
				if model.modelContext == nil {
					modelContext.insert(model)
				}
			}
		}

		for storedTurn in thread.turns where !incomingTurnIDs.contains(storedTurn.codexId) {
			modelContext.delete(storedTurn)
		}
	}

	func saveIfNeeded() throws {
		guard modelContext.hasChanges else { return }
		try modelContext.save()
	}
}
