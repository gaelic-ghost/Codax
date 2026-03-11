//
//  ProjectModel.swift
//  Codax
//
//  Created by Gale Williams on 3/10/26.
//

import Foundation
import SwiftData

@Model
final class Project {
	var id: UUID
	var createdAt: Date
	var updatedAt: Date
	var name: String
	var rootPath: String
	var isActive: Bool
	var selectedThreadCodexId: String?
	var lastError: String?
	var compatibilityDebugOutput: String?

	var threads: [ThreadModel]

	init(
		id: UUID = UUID(),
		createdAt: Date = .now,
		updatedAt: Date = .now,
		name: String = "",
		rootPath: String = "",
		isActive: Bool = false,
		selectedThreadCodexId: String? = nil,
		lastError: String? = nil,
		compatibilityDebugOutput: String? = nil,
		threads: [ThreadModel] = []
	) {
		self.id = id
		self.createdAt = createdAt
		self.updatedAt = updatedAt
		self.name = name
		self.rootPath = rootPath
		self.isActive = isActive
		self.selectedThreadCodexId = selectedThreadCodexId
		self.lastError = lastError
		self.compatibilityDebugOutput = compatibilityDebugOutput
		self.threads = threads
	}

	func thread(codexId: String) -> ThreadModel? {
		threads.first(where: { $0.codexId == codexId })
	}

	func selectThread(codexId: String?) {
		selectedThreadCodexId = codexId
		for thread in threads {
			thread.isSelected = thread.codexId == codexId
		}
		updatedAt = .now
	}

	@discardableResult
	func upsertThread(from thread: Thread) -> ThreadModel {
		if let existing = self.thread(codexId: thread.codexId) {
			existing.apply(thread: thread)
			updatedAt = .now
			return existing
		}

		let model = ThreadModel(thread: thread, project: self)
		model.isSelected = model.codexId == selectedThreadCodexId
		threads.append(model)
		updatedAt = .now
		return model
	}

	var orderedThreads: [ThreadModel] {
		threads.sorted {
			if $0.updatedAt != $1.updatedAt {
				return $0.updatedAt > $1.updatedAt
			}
			if $0.createdAt != $1.createdAt {
				return $0.createdAt > $1.createdAt
			}
			return $0.codexId > $1.codexId
		}
	}
}
