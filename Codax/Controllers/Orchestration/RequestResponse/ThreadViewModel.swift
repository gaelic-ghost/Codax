//
//  ThreadViewModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import Observation

@Observable
final class ThreadViewModel {
	// MARK: - State

	var threadStartResponse: ThreadStartResponse?
	var threadResumeResponse: ThreadResumeResponse?
	var threadForkResponse: ThreadForkResponse?
	var threadArchiveResponse: ThreadArchiveResponse?
	var threadUnsubscribeResponse: ThreadUnsubscribeResponse?
	var threadSetNameResponse: ThreadSetNameResponse?
	var threadMetadataUpdateResponse: ThreadMetadataUpdateResponse?
	var threadUnarchiveResponse: ThreadUnarchiveResponse?
	var threadCompactStartResponse: ThreadCompactStartResponse?
	var threadRollbackResponse: ThreadRollbackResponse?
	var threadListResponse: ThreadListResponse?
	var threadLoadedListResponse: ThreadLoadedListResponse?
	var threadReadResponse: ThreadReadResponse?

	// MARK: Other Related

	var feedbackUploadResponse: FeedbackUploadResponse?

	// MARK: - Requests

	func threadStart(using connection: CodexConnection, params: ThreadStartParams) async throws {
		let response = try await connection.threadStart(params)
		threadStartResponse = response
	}

	func threadResume(using connection: CodexConnection, params: ThreadResumeParams) async throws {
		let response = try await connection.threadResume(params)
		threadResumeResponse = response
	}

	func threadFork(using connection: CodexConnection, params: ThreadForkParams) async throws {
		let response = try await connection.threadFork(params)
		threadForkResponse = response
	}

	func threadArchive(using connection: CodexConnection, params: ThreadArchiveParams) async throws {
		let response = try await connection.threadArchive(params)
		threadArchiveResponse = response
	}

	func threadUnsubscribe(using connection: CodexConnection, params: ThreadUnsubscribeParams) async throws {
		let response = try await connection.threadUnsubscribe(params)
		threadUnsubscribeResponse = response
	}

	func threadNameSet(using connection: CodexConnection, params: ThreadSetNameParams) async throws {
		let response = try await connection.threadNameSet(params)
		threadSetNameResponse = response
	}

	func threadMetadataUpdate(using connection: CodexConnection, params: ThreadMetadataUpdateParams) async throws {
		let response = try await connection.threadMetadataUpdate(params)
		threadMetadataUpdateResponse = response
	}

	func threadUnarchive(using connection: CodexConnection, params: ThreadUnarchiveParams) async throws {
		let response = try await connection.threadUnarchive(params)
		threadUnarchiveResponse = response
	}

	func threadCompactStart(using connection: CodexConnection, params: ThreadCompactStartParams) async throws {
		let response = try await connection.threadCompactStart(params)
		threadCompactStartResponse = response
	}

	func threadRollback(using connection: CodexConnection, params: ThreadRollbackParams) async throws {
		let response = try await connection.threadRollback(params)
		threadRollbackResponse = response
	}

	func threadList(using connection: CodexConnection, params: ThreadListParams) async throws {
		let response = try await connection.threadList(params)
		threadListResponse = response
	}

	func threadLoadedList(using connection: CodexConnection, params: ThreadLoadedListParams) async throws {
		let response = try await connection.threadLoadedList(params)
		threadLoadedListResponse = response
	}

	func threadRead(using connection: CodexConnection, params: ThreadReadParams) async throws {
		let response = try await connection.threadRead(params)
		threadReadResponse = response
	}

	func feedbackUpload(using connection: CodexConnection, params: FeedbackUploadParams) async throws {
		let response = try await connection.feedbackUpload(params)
		feedbackUploadResponse = response
	}
}
