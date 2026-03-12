//
//  TurnDiffModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import SwiftData

// MARK: - Turn Diff Record

struct TurnDiffRecord: Codable, Equatable, Sendable {
	var turnCodexId: String
	var diff: String

	init(turnCodexId: String, diff: String) {
		self.turnCodexId = turnCodexId
		self.diff = diff
	}

	init(notification: TurnDiffUpdatedNotification) {
		self.init(turnCodexId: notification.turnId, diff: notification.diff)
	}

	init(model: TurnDiffModel) {
		self.init(turnCodexId: model.turnCodexId, diff: model.diff)
	}
}

// MARK: - Turn Diff Model

@Model
final class TurnDiffModel {
	var id: UUID
	var turnCodexId: String
	var diff: String

	var turn: TurnModel?

	init(
		id: UUID = UUID(),
		turnCodexId: String,
		diff: String,
		turn: TurnModel? = nil
	) {
		self.id = id
		self.turnCodexId = turnCodexId
		self.diff = diff
		self.turn = turn
	}

	convenience init(record: TurnDiffRecord, turn: TurnModel? = nil) {
		self.init(
			turnCodexId: record.turnCodexId,
			diff: record.diff,
			turn: turn
		)
	}

	var record: TurnDiffRecord {
		TurnDiffRecord(model: self)
	}

	func apply(_ record: TurnDiffRecord) {
		turnCodexId = record.turnCodexId
		diff = record.diff
	}
}
