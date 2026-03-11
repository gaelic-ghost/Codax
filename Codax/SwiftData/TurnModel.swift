//
//  TurnModel.swift
//  Codax
//
//  Created by Gale Williams on 3/10/26.
//

import Foundation
import SwiftData

@Model
final class TurnModel {
	var id: UUID
	var codexId: String
	var statusRawValue: String
	var errorMessage: String?
	var errorAdditionalDetails: String?
	var itemsData: Data
	var codexErrorInfoData: Data?

	var thread: ThreadModel?

	init(
		id: UUID = UUID(),
		codexId: String,
		statusRawValue: String,
		errorMessage: String? = nil,
		errorAdditionalDetails: String? = nil,
		itemsData: Data,
		codexErrorInfoData: Data? = nil,
		thread: ThreadModel? = nil
	) {
		self.id = id
		self.codexId = codexId
		self.statusRawValue = statusRawValue
		self.errorMessage = errorMessage
		self.errorAdditionalDetails = errorAdditionalDetails
		self.itemsData = itemsData
		self.codexErrorInfoData = codexErrorInfoData
		self.thread = thread
	}

	convenience init(turn: Turn, thread: ThreadModel? = nil) {
		self.init(
			id: turn.id,
			codexId: turn.codexId,
			statusRawValue: Self.encodeRawValue(turn.status),
			errorMessage: turn.error?.message,
			errorAdditionalDetails: turn.error?.additionalDetails,
			itemsData: Self.encode(turn.items) ?? Data("[]".utf8),
			codexErrorInfoData: Self.encodeOptional(turn.error?.codexErrorInfo),
			thread: thread
		)
	}

	func apply(turn: Turn) {
		id = turn.id
		codexId = turn.codexId
		statusRawValue = Self.encodeRawValue(turn.status)
		errorMessage = turn.error?.message
		errorAdditionalDetails = turn.error?.additionalDetails
		itemsData = Self.encode(turn.items) ?? Data("[]".utf8)
		codexErrorInfoData = Self.encodeOptional(turn.error?.codexErrorInfo)
	}

	var status: TurnStatus? {
		Self.decodeRawValue(statusRawValue, as: TurnStatus.self)
	}

	var error: TurnError? {
		guard errorMessage != nil || errorAdditionalDetails != nil || codexErrorInfoData != nil else { return nil }
		return TurnError(
			message: errorMessage ?? "",
			codexErrorInfo: Self.decodeOptional(CodexErrorInfo.self, from: codexErrorInfoData),
			additionalDetails: errorAdditionalDetails
		)
	}

	var items: [ThreadItem] {
		Self.decode([ThreadItem].self, from: itemsData) ?? []
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
