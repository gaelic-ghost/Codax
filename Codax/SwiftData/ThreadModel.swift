//
//  ThreadModel.swift
//  Codax
//
//  Created by Gale Williams on 3/10/26.
//

import Foundation
import SwiftData

// MARK: - Thread Hydration State

enum ThreadHydrationState: String, Codable, Sendable {
	case summary
	case detail
}

// MARK: - Thread Model

@Model
final class ThreadModel {
	var id: UUID
	var codexId: String
	var createdAt: Int
	var updatedAt: Int
	var lastListedAt: Date
	var lastHydratedAt: Date?
	var hydrationStateRawValue: String
	var preview: String
	var name: String?
	var ephemeral: Bool
	var isArchived: Bool
	var isClosed: Bool
	var modelProvider: String
	var path: String?
	var cwd: String
	var cliVersion: String
	var statusData: Data
	var sourceData: Data
	var tokenUsageData: Data?

	var project: Project?

	var turns: [TurnModel]

	init(
		id: UUID = UUID(),
		codexId: String,
		createdAt: Int,
		updatedAt: Int,
		lastListedAt: Date = .now,
		lastHydratedAt: Date? = nil,
		hydrationState: ThreadHydrationState,
		preview: String,
		name: String? = nil,
		ephemeral: Bool,
		isArchived: Bool = false,
		isClosed: Bool = false,
		modelProvider: String,
		path: String? = nil,
		cwd: String,
		cliVersion: String,
		statusData: Data,
		sourceData: Data,
		tokenUsageData: Data? = nil,
		project: Project? = nil,
		turns: [TurnModel] = []
	) {
		self.id = id
		self.codexId = codexId
		self.createdAt = createdAt
		self.updatedAt = updatedAt
		self.lastListedAt = lastListedAt
		self.lastHydratedAt = lastHydratedAt
		self.hydrationStateRawValue = hydrationState.rawValue
		self.preview = preview
		self.name = name
		self.ephemeral = ephemeral
		self.isArchived = isArchived
		self.isClosed = isClosed
		self.modelProvider = modelProvider
		self.path = path
		self.cwd = cwd
		self.cliVersion = cliVersion
		self.statusData = statusData
		self.sourceData = sourceData
		self.tokenUsageData = tokenUsageData
		self.project = project
		self.turns = turns
	}

	convenience init(
		thread: Thread,
		project: Project? = nil,
		hydrationState: ThreadHydrationState
	) {
		self.init(
			codexId: thread.id,
			createdAt: thread.createdAt,
			updatedAt: thread.updatedAt,
			lastListedAt: .now,
			lastHydratedAt: hydrationState == .detail ? .now : nil,
			hydrationState: hydrationState,
			preview: thread.preview,
			name: thread.name,
			ephemeral: thread.ephemeral,
			isArchived: false,
			isClosed: false,
			modelProvider: thread.modelProvider,
			path: thread.path,
			cwd: thread.cwd,
			cliVersion: thread.cliVersion,
			statusData: Self.encode(thread.status) ?? Data(),
			sourceData: Self.encode(thread.source) ?? Data(),
			project: project,
			turns: thread.turns.map { TurnModel(turn: $0) }
		)
	}

	var hydrationState: ThreadHydrationState {
		get { ThreadHydrationState(rawValue: hydrationStateRawValue) ?? .summary }
		set { hydrationStateRawValue = newValue.rawValue }
	}

	var status: ThreadStatus? {
		Self.decode(ThreadStatus.self, from: statusData)
	}

	var source: SessionSource? {
		Self.decode(SessionSource.self, from: sourceData)
	}

	var tokenUsage: ThreadTokenUsage? {
		Self.decode(ThreadTokenUsage.self, from: tokenUsageData)
	}

	var displayTitle: String {
		if let name, !name.isEmpty {
			return name
		}
		return preview
	}

	func applySummary(thread: Thread) {
		applyMetadata(thread: thread)
		lastListedAt = .now
		hydrationState = .summary
	}

	func applyDetail(thread: Thread) {
		applyMetadata(thread: thread)
		lastListedAt = .now
		lastHydratedAt = .now
		hydrationState = .detail
	}

	func setTokenUsage(_ tokenUsage: ThreadTokenUsage?) {
		tokenUsageData = Self.encodeOptional(tokenUsage)
	}

	func setStatus(_ status: ThreadStatus) {
		statusData = Self.encode(status) ?? Data()
	}

	func setArchived(_ isArchived: Bool) {
		self.isArchived = isArchived
	}

	func setClosed(_ isClosed: Bool) {
		self.isClosed = isClosed
	}

// MARK: Private Helpers

	private func applyMetadata(thread: Thread) {
		codexId = thread.id
		createdAt = thread.createdAt
		updatedAt = thread.updatedAt
		preview = thread.preview
		name = thread.name
		ephemeral = thread.ephemeral
		modelProvider = thread.modelProvider
		path = thread.path
		cwd = thread.cwd
		cliVersion = thread.cliVersion
		statusData = Self.encode(thread.status) ?? Data()
		sourceData = Self.encode(thread.source) ?? Data()
	}

	private static func encode<T: Encodable>(_ value: T) -> Data? {
		try? JSONEncoder().encode(value)
	}

	private static func encodeOptional<T: Encodable>(_ value: T?) -> Data? {
		guard let value else { return nil }
		return encode(value)
	}

	private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
		guard let data, !data.isEmpty else { return nil }
		return try? JSONDecoder().decode(T.self, from: data)
	}
}
