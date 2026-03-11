//
//  TurnModel.swift
//  Codax
//
//  Created by Gale Williams on 3/10/26.
//

import Foundation
import SwiftData

// MARK: - Turn Model

@Model
final class TurnModel {
	var id: UUID
	var codexId: String
	var statusData: Data
	var errorMessage: String?
	var errorAdditionalDetails: String?
	var itemsData: Data
	var codexErrorInfoData: Data?

	var thread: ThreadModel?

// MARK: Lifecycle

	init(
		id: UUID = UUID(),
		codexId: String,
		statusData: Data,
		errorMessage: String? = nil,
		errorAdditionalDetails: String? = nil,
		itemsData: Data,
		codexErrorInfoData: Data? = nil,
		thread: ThreadModel? = nil
	) {
		self.id = id
		self.codexId = codexId
		self.statusData = statusData
		self.errorMessage = errorMessage
		self.errorAdditionalDetails = errorAdditionalDetails
		self.itemsData = itemsData
		self.codexErrorInfoData = codexErrorInfoData
		self.thread = thread
	}

	convenience init(turn: Turn, thread: ThreadModel? = nil) {
		self.init(
			codexId: turn.id,
			statusData: Self.encode(turn.status) ?? Data(),
			errorMessage: turn.error?.message,
			errorAdditionalDetails: turn.error?.additionalDetails,
			itemsData: Self.encode(turn.items) ?? Data("[]".utf8),
			codexErrorInfoData: Self.encodeOptional(turn.error?.codexErrorInfo),
			thread: thread
		)
	}

	func apply(turn: Turn) {
		codexId = turn.id
		statusData = Self.encode(turn.status) ?? Data()
		errorMessage = turn.error?.message
		errorAdditionalDetails = turn.error?.additionalDetails
		itemsData = Self.encode(turn.items) ?? Data("[]".utf8)
		codexErrorInfoData = Self.encodeOptional(turn.error?.codexErrorInfo)
	}

// MARK: Derived Data

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

	var items: [ThreadItem] {
		Self.decode([ThreadItem].self, from: itemsData) ?? []
	}

// MARK: Codable Helpers

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
