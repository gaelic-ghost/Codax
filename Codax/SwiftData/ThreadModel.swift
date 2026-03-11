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
	var ephemeral: Bool
	var modelProvider: String
	var statusRawValue: String
	var path: String?
	var cwd: String
	var cliVersion: String
	var name: String?
	var agentNickname: String?
	var agentRole: String?
	var isSelected: Bool
	var tokenUsageInput: Int?
	var tokenUsageOutput: Int?
	var tokenUsageTotal: Int?
	var turnDiff: String?
	var gitInfoData: Data?
	var sourceData: Data?
	var turnPlanData: Data?

	var project: Project?

	var turns: [TurnModel]

	init(
		id: UUID = UUID(),
		codexId: String,
		createdAt: Int,
		updatedAt: Int,
		preview: String,
		ephemeral: Bool,
		modelProvider: String,
		statusRawValue: String,
		path: String? = nil,
		cwd: String,
		cliVersion: String,
		name: String? = nil,
		agentNickname: String? = nil,
		agentRole: String? = nil,
		isSelected: Bool = false,
		tokenUsageInput: Int? = nil,
		tokenUsageOutput: Int? = nil,
		tokenUsageTotal: Int? = nil,
		turnDiff: String? = nil,
		gitInfoData: Data? = nil,
		sourceData: Data? = nil,
		turnPlanData: Data? = nil,
		project: Project? = nil,
		turns: [TurnModel] = []
	) {
		self.id = id
		self.codexId = codexId
		self.createdAt = createdAt
		self.updatedAt = updatedAt
		self.preview = preview
		self.ephemeral = ephemeral
		self.modelProvider = modelProvider
		self.statusRawValue = statusRawValue
		self.path = path
		self.cwd = cwd
		self.cliVersion = cliVersion
		self.name = name
		self.agentNickname = agentNickname
		self.agentRole = agentRole
		self.isSelected = isSelected
		self.tokenUsageInput = tokenUsageInput
		self.tokenUsageOutput = tokenUsageOutput
		self.tokenUsageTotal = tokenUsageTotal
		self.turnDiff = turnDiff
		self.gitInfoData = gitInfoData
		self.sourceData = sourceData
		self.turnPlanData = turnPlanData
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
			ephemeral: thread.ephemeral,
			modelProvider: thread.modelProvider,
			statusRawValue: Self.encodeRawValue(thread.status),
			path: thread.path,
			cwd: thread.cwd,
			cliVersion: thread.cliVersion,
			name: thread.name,
			agentNickname: thread.agentNickname,
			agentRole: thread.agentRole,
			gitInfoData: Self.encodeOptional(thread.gitInfo),
			sourceData: Self.encodeOptional(thread.source),
			turnPlanData: Self.encode([TurnPlanStep]()),
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
		ephemeral = thread.ephemeral
		modelProvider = thread.modelProvider
		statusRawValue = Self.encodeRawValue(thread.status)
		path = thread.path
		cwd = thread.cwd
		cliVersion = thread.cliVersion
		name = thread.name
		agentNickname = thread.agentNickname
		agentRole = thread.agentRole
		gitInfoData = Self.encodeOptional(thread.gitInfo)
		sourceData = Self.encodeOptional(thread.source)

		for turn in thread.turns {
			_ = upsertTurn(from: turn)
		}
	}

	func setTokenUsage(_ tokenUsage: ThreadTokenUsage?) {
		tokenUsageInput = tokenUsage?.total.inputTokens
		tokenUsageOutput = tokenUsage?.total.outputTokens
		tokenUsageTotal = tokenUsage?.total.totalTokens
	}

	func setTurnPlan(_ plan: [TurnPlanStep]) {
		turnPlanData = Self.encode(plan)
	}

	func clearPresentationState() {
		tokenUsageInput = nil
		tokenUsageOutput = nil
		tokenUsageTotal = nil
		turnDiff = nil
		turnPlanData = Self.encode([TurnPlanStep]())
	}

	@discardableResult
	func upsertTurn(from turn: Turn) -> TurnModel {
		if let existing = turns.first(where: { $0.codexId == turn.codexId }) {
			existing.apply(turn: turn)
			return existing
		}

		let model = TurnModel(turn: turn, thread: self)
		turns.append(model)
		return model
	}

	var status: ThreadStatus? {
		Self.decodeRawValue(statusRawValue, as: ThreadStatus.self)
	}

	var gitInfo: GitInfo? {
		Self.decodeOptional(GitInfo.self, from: gitInfoData)
	}

	var source: SessionSource? {
		Self.decodeOptional(SessionSource.self, from: sourceData)
	}

	var turnPlan: [TurnPlanStep] {
		Self.decode([TurnPlanStep].self, from: turnPlanData) ?? []
	}

	private static func encode<T: Encodable>(_ value: T) -> Data? {
		try? JSONEncoder().encode(value)
	}

	private static func encodeOptional<T: Encodable>(_ value: T?) -> Data? {
		guard let value else { return nil }
		return encode(value)
	}

	private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
		guard let data else { return nil }
		return try? JSONDecoder().decode(T.self, from: data)
	}

	private static func decodeOptional<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
		decode(T.self, from: data)
	}

	private static func encodeRawValue<T: Encodable>(_ value: T) -> String {
		guard let data = try? JSONEncoder().encode(value),
			let string = String(data: data, encoding: .utf8)
		else {
			return ""
		}
		return string
	}

	private static func decodeRawValue<T: Decodable>(_ value: String, as type: T.Type) -> T? {
		guard let data = value.data(using: .utf8) else { return nil }
		return try? JSONDecoder().decode(T.self, from: data)
	}
}
