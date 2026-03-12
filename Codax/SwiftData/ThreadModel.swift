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

// MARK: - Thread Record

struct ThreadRecord: Codable, Equatable, Sendable {
	var id: UUID
	var codexId: String
	var createdAt: Int
	var updatedAt: Int
	var lastListedAt: Date
	var lastHydratedAt: Date?
	var hydrationState: ThreadHydrationState
	var preview: String
	var name: String?
	var ephemeral: Bool
	var isArchived: Bool
	var isClosed: Bool
	var modelProvider: String
	var path: String?
	var cwd: String
	var cliVersion: String
	var status: ThreadStatus?
	var source: SessionSource?
	var gitInfo: GitInfo?
	var tokenUsage: ThreadTokenUsage?

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
		status: ThreadStatus?,
		source: SessionSource?,
		gitInfo: GitInfo? = nil,
		tokenUsage: ThreadTokenUsage? = nil
	) {
		self.id = id
		self.codexId = codexId
		self.createdAt = createdAt
		self.updatedAt = updatedAt
		self.lastListedAt = lastListedAt
		self.lastHydratedAt = lastHydratedAt
		self.hydrationState = hydrationState
		self.preview = preview
		self.name = name
		self.ephemeral = ephemeral
		self.isArchived = isArchived
		self.isClosed = isClosed
		self.modelProvider = modelProvider
		self.path = path
		self.cwd = cwd
		self.cliVersion = cliVersion
		self.status = status
		self.source = source
		self.gitInfo = gitInfo
		self.tokenUsage = tokenUsage
	}

	init(thread: Thread, hydrationState: ThreadHydrationState) {
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
			modelProvider: thread.modelProvider,
			path: thread.path,
			cwd: thread.cwd,
			cliVersion: thread.cliVersion,
			status: thread.status,
			source: thread.source,
			gitInfo: thread.gitInfo
		)
	}

	init(model: ThreadModel) {
		self.init(
			id: model.id,
			codexId: model.codexId,
			createdAt: model.createdAt,
			updatedAt: model.updatedAt,
			lastListedAt: model.lastListedAt,
			lastHydratedAt: model.lastHydratedAt,
			hydrationState: model.hydrationState,
			preview: model.preview,
			name: model.name,
			ephemeral: model.ephemeral,
			isArchived: model.isArchived,
			isClosed: model.isClosed,
			modelProvider: model.modelProvider,
			path: model.path,
			cwd: model.cwd,
			cliVersion: model.cliVersion,
			status: model.status,
			source: model.source,
			gitInfo: model.gitInfo,
			tokenUsage: model.tokenUsage
		)
	}
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
	var gitInfoData: Data?
	var tokenUsageData: Data?

	var project: Project?
	var session: ThreadSessionModel?
	var gitDiff: ThreadGitDiffModel?
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
		gitInfoData: Data? = nil,
		tokenUsageData: Data? = nil,
		project: Project? = nil,
		session: ThreadSessionModel? = nil,
		gitDiff: ThreadGitDiffModel? = nil,
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
		self.gitInfoData = gitInfoData
		self.tokenUsageData = tokenUsageData
		self.project = project
		self.session = session
		self.gitDiff = gitDiff
		self.turns = turns
	}

	convenience init(
		record: ThreadRecord,
		project: Project? = nil,
		session: ThreadSessionModel? = nil,
		gitDiff: ThreadGitDiffModel? = nil,
		turns: [TurnModel] = []
	) {
		self.init(
			id: record.id,
			codexId: record.codexId,
			createdAt: record.createdAt,
			updatedAt: record.updatedAt,
			lastListedAt: record.lastListedAt,
			lastHydratedAt: record.lastHydratedAt,
			hydrationState: record.hydrationState,
			preview: record.preview,
			name: record.name,
			ephemeral: record.ephemeral,
			isArchived: record.isArchived,
			isClosed: record.isClosed,
			modelProvider: record.modelProvider,
			path: record.path,
			cwd: record.cwd,
			cliVersion: record.cliVersion,
			statusData: Self.encodeOptional(record.status) ?? Data(),
			sourceData: Self.encodeOptional(record.source) ?? Data(),
			gitInfoData: Self.encodeOptional(record.gitInfo),
			tokenUsageData: Self.encodeOptional(record.tokenUsage),
			project: project,
			session: session,
			gitDiff: gitDiff,
			turns: turns
		)
	}

	convenience init(
		thread: Thread,
		project: Project? = nil,
		hydrationState: ThreadHydrationState
	) {
		self.init(record: ThreadRecord(thread: thread, hydrationState: hydrationState), project: project)
	}

	var record: ThreadRecord {
		ThreadRecord(model: self)
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

	var gitInfo: GitInfo? {
		Self.decode(GitInfo.self, from: gitInfoData)
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

	var sortedTurns: [TurnModel] {
		turns.sorted { $0.sequenceIndex < $1.sequenceIndex }
	}

	var latestTurn: TurnModel? {
		sortedTurns.last
	}

	func applySummary(thread: Thread) {
		apply(ThreadRecord(thread: thread, hydrationState: .summary))
	}

	func applyDetail(thread: Thread) {
		var record = ThreadRecord(thread: thread, hydrationState: .detail)
		record.id = id
		record.lastListedAt = .now
		record.lastHydratedAt = .now
		record.isArchived = isArchived
		record.isClosed = isClosed
		if let tokenUsage = tokenUsage {
			record.tokenUsage = tokenUsage
		}
		apply(record)
	}

	func apply(_ record: ThreadRecord) {
		id = record.id
		codexId = record.codexId
		createdAt = record.createdAt
		updatedAt = record.updatedAt
		lastListedAt = record.lastListedAt
		lastHydratedAt = record.lastHydratedAt
		hydrationState = record.hydrationState
		preview = record.preview
		name = record.name
		ephemeral = record.ephemeral
		isArchived = record.isArchived
		isClosed = record.isClosed
		modelProvider = record.modelProvider
		path = record.path
		cwd = record.cwd
		cliVersion = record.cliVersion
		statusData = Self.encodeOptional(record.status) ?? Data()
		sourceData = Self.encodeOptional(record.source) ?? Data()
		gitInfoData = Self.encodeOptional(record.gitInfo)
		tokenUsageData = Self.encodeOptional(record.tokenUsage)
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
