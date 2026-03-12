//
//  ProjectModel.swift
//  Codax
//
//  Created by Gale Williams on 3/10/26.
//

import Foundation
import SwiftData

// MARK: - Project Record

struct ProjectRecord: Codable, Equatable, Sendable {
	var id: UUID
	var createdAt: Date
	var updatedAt: Date
	var name: String
	var rootPath: String
	var isActive: Bool

	init(
		id: UUID = UUID(),
		createdAt: Date = .now,
		updatedAt: Date = .now,
		name: String = "",
		rootPath: String = "",
		isActive: Bool = false
	) {
		self.id = id
		self.createdAt = createdAt
		self.updatedAt = updatedAt
		self.name = name
		self.rootPath = rootPath
		self.isActive = isActive
	}

	init(model: Project) {
		self.init(
			id: model.id,
			createdAt: model.createdAt,
			updatedAt: model.updatedAt,
			name: model.name,
			rootPath: model.rootPath,
			isActive: model.isActive
		)
	}
}

// MARK: - Project Model

@Model
final class Project {
	var id: UUID
	var createdAt: Date
	var updatedAt: Date
	var name: String
	var rootPath: String
	var isActive: Bool

	var threads: [ThreadModel]

	init(
		id: UUID = UUID(),
		createdAt: Date = .now,
		updatedAt: Date = .now,
		name: String = "",
		rootPath: String = "",
		isActive: Bool = false,
		threads: [ThreadModel] = []
	) {
		self.id = id
		self.createdAt = createdAt
		self.updatedAt = updatedAt
		self.name = name
		self.rootPath = rootPath
		self.isActive = isActive
		self.threads = threads
	}

	convenience init(record: ProjectRecord, threads: [ThreadModel] = []) {
		self.init(
			id: record.id,
			createdAt: record.createdAt,
			updatedAt: record.updatedAt,
			name: record.name,
			rootPath: record.rootPath,
			isActive: record.isActive,
			threads: threads
		)
	}

	var record: ProjectRecord {
		ProjectRecord(model: self)
	}

	func apply(_ record: ProjectRecord) {
		id = record.id
		createdAt = record.createdAt
		updatedAt = record.updatedAt
		name = record.name
		rootPath = record.rootPath
		isActive = record.isActive
	}

	func activate() {
		updatedAt = .now
		isActive = true
	}

	func thread(codexId: String) -> ThreadModel? {
		threads.first(where: { $0.codexId == codexId })
	}
}
