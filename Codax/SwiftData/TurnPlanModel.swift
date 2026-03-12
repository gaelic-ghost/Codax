//
//  TurnPlanModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import SwiftData

// MARK: - Turn Plan Record

struct TurnPlanRecord: Codable, Equatable, Sendable {
	var turnCodexId: String
	var explanation: String?
	var steps: [TurnPlanStep]

	init(turnCodexId: String, explanation: String?, steps: [TurnPlanStep]) {
		self.turnCodexId = turnCodexId
		self.explanation = explanation
		self.steps = steps
	}

	init(notification: TurnPlanUpdatedNotification) {
		self.init(
			turnCodexId: notification.turnId,
			explanation: notification.explanation,
			steps: notification.plan
		)
	}

	init(model: TurnPlanModel) {
		self.init(
			turnCodexId: model.turnCodexId,
			explanation: model.explanation,
			steps: model.steps
		)
	}
}

// MARK: - Turn Plan Model

@Model
final class TurnPlanModel {
	var id: UUID
	var turnCodexId: String
	var explanation: String?
	var stepsData: Data

	var turn: TurnModel?

	init(
		id: UUID = UUID(),
		turnCodexId: String,
		explanation: String? = nil,
		stepsData: Data,
		turn: TurnModel? = nil
	) {
		self.id = id
		self.turnCodexId = turnCodexId
		self.explanation = explanation
		self.stepsData = stepsData
		self.turn = turn
	}

	convenience init(record: TurnPlanRecord, turn: TurnModel? = nil) {
		self.init(
			turnCodexId: record.turnCodexId,
			explanation: record.explanation,
			stepsData: Self.encode(record.steps) ?? Data("[]".utf8),
			turn: turn
		)
	}

	var record: TurnPlanRecord {
		TurnPlanRecord(model: self)
	}

	var steps: [TurnPlanStep] {
		Self.decode([TurnPlanStep].self, from: stepsData) ?? []
	}

	func apply(_ record: TurnPlanRecord) {
		turnCodexId = record.turnCodexId
		explanation = record.explanation
		stepsData = Self.encode(record.steps) ?? Data("[]".utf8)
	}

	private static func encode<T: Encodable>(_ value: T) -> Data? {
		try? JSONEncoder().encode(value)
	}

	private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
		guard let data, !data.isEmpty else { return nil }
		return try? JSONDecoder().decode(T.self, from: data)
	}
}
