//
//  ItemModel.swift
//  Codax
//
//  Created by Gale Williams on 3/11/26.
//

import Foundation
import SwiftData

// MARK: - Item Record

struct ItemRecord: Codable, Equatable, Sendable {
	var id: UUID
	var position: Int
	var item: ThreadItem

	init(
		id: UUID = UUID(),
		position: Int,
		item: ThreadItem
	) {
		self.id = id
		self.position = position
		self.item = item
	}

	init(model: ItemModel) throws {
		guard let item = model.item else {
			throw CocoaError(.coderInvalidValue)
		}
		self.init(
			id: model.id,
			position: model.position,
			item: item
		)
	}
}

// MARK: - Item Model

@Model
final class ItemModel {
	var id: UUID
	var position: Int
	var itemType: String
	var itemData: Data

	var turn: TurnModel?

	init(
		id: UUID = UUID(),
		position: Int,
		itemType: String,
		itemData: Data,
		turn: TurnModel? = nil
	) {
		self.id = id
		self.position = position
		self.itemType = itemType
		self.itemData = itemData
		self.turn = turn
	}

	convenience init(record: ItemRecord, turn: TurnModel? = nil) {
		self.init(
			id: record.id,
			position: record.position,
			itemType: Self.typeName(for: record.item),
			itemData: Self.encode(record.item) ?? Data(),
			turn: turn
		)
	}

	convenience init(item: ThreadItem, position: Int, turn: TurnModel? = nil) {
		self.init(
			record: ItemRecord(position: position, item: item),
			turn: turn
		)
	}

	var record: ItemRecord? {
		guard let item else { return nil }
		return ItemRecord(id: id, position: position, item: item)
	}

	var item: ThreadItem? {
		Self.decode(ThreadItem.self, from: itemData)
	}

	func apply(_ record: ItemRecord) {
		id = record.id
		position = record.position
		itemType = Self.typeName(for: record.item)
		itemData = Self.encode(record.item) ?? Data()
	}

	private static func encode<T: Encodable>(_ value: T) -> Data? {
		try? JSONEncoder().encode(value)
	}

	private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
		guard let data, !data.isEmpty else { return nil }
		return try? JSONDecoder().decode(T.self, from: data)
	}

	private static func typeName(for item: ThreadItem) -> String {
		switch item {
		case .userMessage:
			return "userMessage"
		case .agentMessage:
			return "agentMessage"
		case .plan:
			return "plan"
		case .reasoning:
			return "reasoning"
		case .commandExecution:
			return "commandExecution"
		case .fileChange:
			return "fileChange"
		case .mcpToolCall:
			return "mcpToolCall"
		case .dynamicToolCall:
			return "dynamicToolCall"
		case .collabAgentToolCall:
			return "collabAgentToolCall"
		case .webSearch:
			return "webSearch"
		case .imageView:
			return "imageView"
		case .imageGeneration:
			return "imageGeneration"
		case .enteredReviewMode:
			return "enteredReviewMode"
		case .exitedReviewMode:
			return "exitedReviewMode"
		case .contextCompaction:
			return "contextCompaction"
		}
	}
}
