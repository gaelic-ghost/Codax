//
//  ThreadGitDiffModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import SwiftData

// MARK: - Thread Git Diff Record

struct ThreadGitDiffRecord: Codable, Equatable, Sendable {
	var threadCodexId: String
	var response: GitDiffToRemoteResponse?
	var errorMessage: String?
	var refreshedAt: Date

	init(
		threadCodexId: String,
		response: GitDiffToRemoteResponse?,
		errorMessage: String?,
		refreshedAt: Date = .now
	) {
		self.threadCodexId = threadCodexId
		self.response = response
		self.errorMessage = errorMessage
		self.refreshedAt = refreshedAt
	}

	init(model: ThreadGitDiffModel) {
		self.init(
			threadCodexId: model.threadCodexId,
			response: model.response,
			errorMessage: model.errorMessage,
			refreshedAt: model.refreshedAt
		)
	}
}

// MARK: - Thread Git Diff Model

@Model
final class ThreadGitDiffModel {
	var id: UUID
	var threadCodexId: String
	var responseData: Data?
	var errorMessage: String?
	var refreshedAt: Date

	var thread: ThreadModel?

	init(
		id: UUID = UUID(),
		threadCodexId: String,
		responseData: Data? = nil,
		errorMessage: String? = nil,
		refreshedAt: Date = .now,
		thread: ThreadModel? = nil
	) {
		self.id = id
		self.threadCodexId = threadCodexId
		self.responseData = responseData
		self.errorMessage = errorMessage
		self.refreshedAt = refreshedAt
		self.thread = thread
	}

	convenience init(record: ThreadGitDiffRecord, thread: ThreadModel? = nil) {
		self.init(
			threadCodexId: record.threadCodexId,
			responseData: Self.encodeOptional(record.response),
			errorMessage: record.errorMessage,
			refreshedAt: record.refreshedAt,
			thread: thread
		)
	}

	var record: ThreadGitDiffRecord {
		ThreadGitDiffRecord(model: self)
	}

	var response: GitDiffToRemoteResponse? {
		Self.decode(GitDiffToRemoteResponse.self, from: responseData)
	}

	func apply(_ record: ThreadGitDiffRecord) {
		threadCodexId = record.threadCodexId
		responseData = Self.encodeOptional(record.response)
		errorMessage = record.errorMessage
		refreshedAt = record.refreshedAt
	}

	private static func encodeOptional<T: Encodable>(_ value: T?) -> Data? {
		guard let value else { return nil }
		return try? JSONEncoder().encode(value)
	}

	private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
		guard let data, !data.isEmpty else { return nil }
		return try? JSONDecoder().decode(T.self, from: data)
	}
}
