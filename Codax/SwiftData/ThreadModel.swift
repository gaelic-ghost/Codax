//
//  ThreadModel.swift
//  Codax
//
//  Created by Gale Williams on 3/10/26.
//

import Foundation
import SwiftData

@Model
final class ThreadModel {
	var id: UUID
	var codexId: String
	var createdAt: Int
	var updatedAt: Int
	var preview: String
	var name: String?
	var ephemeral: Bool
	var statusData: Data

	var project: Project?

	var turns: [TurnModel]

	init(
		id: UUID = UUID(),
		codexId: String,
		createdAt: Int,
		updatedAt: Int,
		preview: String,
		name: String? = nil,
		ephemeral: Bool,
		statusData: Data,
		project: Project? = nil,
		turns: [TurnModel] = []
	) {
		self.id = id
		self.codexId = codexId
		self.createdAt = createdAt
		self.updatedAt = updatedAt
		self.preview = preview
		self.name = name
		self.ephemeral = ephemeral
		self.statusData = statusData
		self.project = project
		self.turns = turns
	}

	convenience init(thread: Thread, project: Project? = nil) {
		self.init(
			id: thread.id,
			codexId: thread.codexId,
			createdAt: thread.createdAt,
			updatedAt: thread.updatedAt,
			preview: thread.preview,
			name: thread.name,
			ephemeral: thread.ephemeral,
			statusData: Self.encode(thread.status) ?? Data(),
			project: project,
			turns: thread.turns.map { TurnModel(turn: $0) }
		)
	}

	func apply(thread: Thread) {
		id = thread.id
		codexId = thread.codexId
		createdAt = thread.createdAt
		updatedAt = thread.updatedAt
		preview = thread.preview
		name = thread.name
		ephemeral = thread.ephemeral
		statusData = Self.encode(thread.status) ?? Data()
	}

	var status: ThreadStatus? {
		Self.decode(ThreadStatus.self, from: statusData)
	}

	private static func encode<T: Encodable>(_ value: T) -> Data? {
		try? JSONEncoder().encode(value)
	}

	private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
		guard let data, !data.isEmpty else { return nil }
		return try? JSONDecoder().decode(T.self, from: data)
	}
}
