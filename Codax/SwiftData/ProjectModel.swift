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

	func thread(codexId: String) -> ThreadModel? {
		threads.first(where: { $0.codexId == codexId })
	}
}
