//
//  TurnModel.swift
//  Codax
//
//  Created by Gale Williams on 3/10/26.
//

import Foundation
import SwiftData

// MARK: - Turn Record

struct TurnRecord: Codable, Equatable, Sendable {
	var id: UUID
	var codexId: String
	var sequenceIndex: Int
	var status: TurnStatus?
	var error: TurnError?

	init(
		id: UUID = UUID(),
		codexId: String,
		sequenceIndex: Int,
		status: TurnStatus?,
		error: TurnError?
	) {
		self.id = id
		self.codexId = codexId
		self.sequenceIndex = sequenceIndex
		self.status = status
		self.error = error
	}

	init(turn: Turn, sequenceIndex: Int) {
		self.init(
			codexId: turn.id,
			sequenceIndex: sequenceIndex,
			status: turn.status,
			error: turn.error
		)
	}

	init(model: TurnModel) {
		self.init(
			id: model.id,
			codexId: model.codexId,
			sequenceIndex: model.sequenceIndex,
			status: model.status,
			error: model.error
		)
	}
}

// MARK: - Turn Model

@Model
final class TurnModel {
	var id: UUID
	var codexId: String
	var sequenceIndex: Int = 0
	var statusData: Data
	var errorMessage: String?
	var errorAdditionalDetails: String?
	var codexErrorInfoData: Data?

	var thread: ThreadModel?
	var items: [ItemModel]
	var plan: TurnPlanModel?
	var diff: TurnDiffModel?

	init(
		id: UUID = UUID(),
		codexId: String,
		sequenceIndex: Int = 0,
		statusData: Data,
		errorMessage: String? = nil,
		errorAdditionalDetails: String? = nil,
		codexErrorInfoData: Data? = nil,
		thread: ThreadModel? = nil,
		items: [ItemModel] = [],
		plan: TurnPlanModel? = nil,
		diff: TurnDiffModel? = nil
	) {
		self.id = id
		self.codexId = codexId
		self.sequenceIndex = sequenceIndex
		self.statusData = statusData
		self.errorMessage = errorMessage
		self.errorAdditionalDetails = errorAdditionalDetails
		self.codexErrorInfoData = codexErrorInfoData
		self.thread = thread
		self.items = items
		self.plan = plan
		self.diff = diff
	}

	convenience init(turn: Turn, sequenceIndex: Int, thread: ThreadModel? = nil) {
		self.init(
			record: TurnRecord(turn: turn, sequenceIndex: sequenceIndex),
			thread: thread,
			items: turn.items.enumerated().map { ItemModel(item: $0.element, position: $0.offset) }
		)
	}

	convenience init(
		record: TurnRecord,
		thread: ThreadModel? = nil,
		items: [ItemModel] = [],
		plan: TurnPlanModel? = nil,
		diff: TurnDiffModel? = nil
	) {
		self.init(
			id: record.id,
			codexId: record.codexId,
			sequenceIndex: record.sequenceIndex,
			statusData: Self.encode(record.status) ?? Data(),
			errorMessage: record.error?.message,
			errorAdditionalDetails: record.error?.additionalDetails,
			codexErrorInfoData: Self.encodeOptional(record.error?.codexErrorInfo),
			thread: thread,
			items: items,
			plan: plan,
			diff: diff
		)
	}

	var record: TurnRecord {
		TurnRecord(model: self)
	}

	var status: TurnStatus? {
		Self.decode(TurnStatus.self, from: statusData)
	}

	var error: TurnError? {
		guard errorMessage != nil || errorAdditionalDetails != nil || codexErrorInfoData != nil else { return nil }
		return TurnError(
			message: errorMessage ?? "",
			codexErrorInfo: Self.decode(CodexErrorInfo.self, from: codexErrorInfoData),
			additionalDetails: errorAdditionalDetails
		)
	}

	var sortedItems: [ItemModel] {
		items.sorted { $0.position < $1.position }
	}

	var threadItems: [ThreadItem] {
		sortedItems.compactMap(\.item)
	}

	func apply(_ record: TurnRecord) {
		id = record.id
		codexId = record.codexId
		sequenceIndex = record.sequenceIndex
		statusData = Self.encode(record.status) ?? Data()
		errorMessage = record.error?.message
		errorAdditionalDetails = record.error?.additionalDetails
		codexErrorInfoData = Self.encodeOptional(record.error?.codexErrorInfo)
	}

	func apply(turn: Turn, sequenceIndex: Int) {
		apply(TurnRecord(turn: turn, sequenceIndex: sequenceIndex))
		items = turn.items.enumerated().map { index, item in
			if let existing = items.first(where: { $0.position == index }) {
				existing.apply(ItemRecord(position: index, item: item))
				existing.turn = self
				return existing
			}
			return ItemModel(item: item, position: index, turn: self)
		}
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
