//
//  CodexOrchestrator+Conversation.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation

/*
 `CodaxOrchestrator+Conversation` includes the conversation-summary request/response surface for the Codex app-server. Semantically, this section represents a read-only summary boundary: it asks the server for a typed summary of conversation state and stores the most recent answer verbatim, without synthesizing additional presentation state.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `getConversationSummaryResponse`: Holds the most recent `GetConversationSummaryResponse` returned by `getConversationSummary`. Semantically, this is the latest typed server summary of the requested conversation context.

 Functions:
 - `getConversationSummary(params:)`: Sends the generated `getConversationSummary` request with `GetConversationSummaryParams` through the orchestrator-owned runtime, awaits the typed `GetConversationSummaryResponse`, and stores it in `getConversationSummaryResponse`. Semantically, this fetches a server-produced summary projection instead of the full underlying conversation payload.
 */

/*

 Properties:
 - `threadStartResponse`: Holds the most recent `ThreadStartResponse` returned by `thread/start`. Semantically, this is the acceptance payload for creating a fresh conversation thread, including the newly opened thread object.
 - `threadResumeResponse`: Holds the most recent `ThreadResumeResponse` returned by `thread/resume`. Semantically, this is the acceptance payload for reopening an existing stored thread so later turns append to it.
 - `threadForkResponse`: Holds the most recent `ThreadForkResponse` returned by `thread/fork`. Semantically, this is the result of branching an existing thread into a new thread identity with copied history.
 - `threadArchiveResponse`: Holds the most recent `ThreadArchiveResponse` returned by `thread/archive`. Semantically, this is the acknowledgement that a thread's rollout was moved into the archived set.
 - `threadUnsubscribeResponse`: Holds the most recent `ThreadUnsubscribeResponse` returned by `thread/unsubscribe`. Semantically, this captures whether the current connection was unsubscribed, already unsubscribed, or targeting a thread that was not loaded.
 - `threadSetNameResponse`: Holds the most recent `ThreadSetNameResponse` returned by `thread/name/set`. Semantically, this is the acknowledgement that a user-facing thread name mutation was accepted.
 - `threadMetadataUpdateResponse`: Holds the most recent `ThreadMetadataUpdateResponse` returned by `thread/metadata/update`. Semantically, this is the refreshed thread payload after persisted metadata such as git information was patched.
 - `threadUnarchiveResponse`: Holds the most recent `ThreadUnarchiveResponse` returned by `thread/unarchive`. Semantically, this is the restored thread payload after moving an archived rollout back into the active sessions area.
 - `threadCompactStartResponse`: Holds the most recent `ThreadCompactStartResponse` returned by `thread/compact/start`. Semantically, this is the immediate acknowledgement that conversation compaction work was accepted and will continue through streamed events.
 - `threadRollbackResponse`: Holds the most recent `ThreadRollbackResponse` returned by `thread/rollback`. Semantically, this is the updated thread payload after pruning the most recent turns from the in-memory and persisted conversation history.
 - `threadListResponse`: Holds the most recent `ThreadListResponse` returned by `thread/list`. Semantically, this is the latest paginated stored-thread catalog for the requested filters.
 - `threadLoadedListResponse`: Holds the most recent `ThreadLoadedListResponse` returned by `thread/loaded/list`. Semantically, this is the current list of thread identifiers that are loaded in server memory.
 - `threadReadResponse`: Holds the most recent `ThreadReadResponse` returned by `thread/read`. Semantically, this is the latest stored thread snapshot fetched without resuming the thread.
 - `feedbackUploadResponse`: Holds the most recent `FeedbackUploadResponse` returned by `feedback/upload`. Semantically, this is the server acknowledgement and tracking payload for a feedback report submitted from the app.

 Functions:
 - `threadStart(params:)`: Sends the generated `thread/start` request with `ThreadStartParams` through the orchestrator-owned runtime, awaits the typed `ThreadStartResponse`, and stores it in `threadStartResponse`. Semantically, this opens a brand-new thread and begins the lifecycle of a fresh Codex conversation.
 - `threadResume(params:)`: Sends the generated `thread/resume` request with `ThreadResumeParams` through the orchestrator-owned runtime, awaits the typed `ThreadResumeResponse`, and stores it in `threadResumeResponse`. Semantically, this reattaches to an existing thread so subsequent turn requests continue that conversation.
 - `threadFork(params:)`: Sends the generated `thread/fork` request with `ThreadForkParams` through the orchestrator-owned runtime, awaits the typed `ThreadForkResponse`, and stores it in `threadForkResponse`. Semantically, this branches an existing conversation into a new one that starts from copied history.
 - `threadArchive(params:)`: Sends the generated `thread/archive` request with `ThreadArchiveParams` through the orchestrator-owned runtime, awaits the typed `ThreadArchiveResponse`, and stores it in `threadArchiveResponse`. Semantically, this archives a thread's persisted rollout.
 - `threadUnsubscribe(params:)`: Sends the generated `thread/unsubscribe` request with `ThreadUnsubscribeParams` through the orchestrator-owned runtime, awaits the typed `ThreadUnsubscribeResponse`, and stores it in `threadUnsubscribeResponse`. Semantically, this removes the active live-event subscription for a loaded thread.
 - `threadNameSet(params:)`: Sends the generated `thread/name/set` request with `ThreadSetNameParams` through the orchestrator-owned runtime, awaits the typed `ThreadSetNameResponse`, and stores it in `threadSetNameResponse`. Semantically, this writes or updates the human-facing name associated with a thread.
 - `threadMetadataUpdate(params:)`: Sends the generated `thread/metadata/update` request with `ThreadMetadataUpdateParams` through the orchestrator-owned runtime, awaits the typed `ThreadMetadataUpdateResponse`, and stores it in `threadMetadataUpdateResponse`. Semantically, this patches persisted metadata fields for a thread without fully resuming it.
 - `threadUnarchive(params:)`: Sends the generated `thread/unarchive` request with `ThreadUnarchiveParams` through the orchestrator-owned runtime, awaits the typed `ThreadUnarchiveResponse`, and stores it in `threadUnarchiveResponse`. Semantically, this restores an archived conversation back into the active thread set.
 - `threadCompactStart(params:)`: Sends the generated `thread/compact/start` request with `ThreadCompactStartParams` through the orchestrator-owned runtime, awaits the typed `ThreadCompactStartResponse`, and stores it in `threadCompactStartResponse`. Semantically, this requests history compaction while expecting detailed progress to arrive later through streamed notifications.
 - `threadRollback(params:)`: Sends the generated `thread/rollback` request with `ThreadRollbackParams` through the orchestrator-owned runtime, awaits the typed `ThreadRollbackResponse`, and stores it in `threadRollbackResponse`. Semantically, this prunes a trailing portion of conversation history and returns the resulting updated thread state.
 - `threadList(params:)`: Sends the generated `thread/list` request with `ThreadListParams` through the orchestrator-owned runtime, awaits the typed `ThreadListResponse`, and stores it in `threadListResponse`. Semantically, this paginates through persisted thread history using filters and sort options.
 - `threadLoadedList(params:)`: Sends the generated `thread/loaded/list` request with `ThreadLoadedListParams` through the orchestrator-owned runtime, awaits the typed `ThreadLoadedListResponse`, and stores it in `threadLoadedListResponse`. Semantically, this reads the server's current in-memory loaded-thread set.
 - `threadRead(params:)`: Sends the generated `thread/read` request with `ThreadReadParams` through the orchestrator-owned runtime, awaits the typed `ThreadReadResponse`, and stores it in `threadReadResponse`. Semantically, this fetches a stored thread snapshot, optionally including full turns, without changing whether the thread is loaded.
 - `feedbackUpload(params:)`: Sends the generated `feedback/upload` request with `FeedbackUploadParams` through the orchestrator-owned runtime, awaits the typed `FeedbackUploadResponse`, and stores it in `feedbackUploadResponse`. Semantically, this submits a feedback report about Codex behavior and preserves the tracking response.
 */

/*

 Properties:
 - `turnStartResponse`: Holds the most recent `TurnStartResponse` returned by `turn/start`. Semantically, this is the initial accepted turn payload for a new user message inside a thread.
 - `turnSteerResponse`: Holds the most recent `TurnSteerResponse` returned by `turn/steer`. Semantically, this is the acknowledgement that additional user input was attached to an already active in-flight turn.
 - `turnInterruptResponse`: Holds the most recent `TurnInterruptResponse` returned by `turn/interrupt`. Semantically, this is the acknowledgement that cancellation was requested for a running turn.

 Functions:
 - `turnStart(params:)`: Sends the generated `turn/start` request with `TurnStartParams` through the orchestrator-owned runtime, awaits the typed `TurnStartResponse`, and stores it in `turnStartResponse`. Semantically, this begins a new turn inside an existing thread and triggers the streamed turn/item lifecycle.
 - `turnSteer(params:)`: Sends the generated `turn/steer` request with `TurnSteerParams` through the orchestrator-owned runtime, awaits the typed `TurnSteerResponse`, and stores it in `turnSteerResponse`. Semantically, this injects additional guidance into the currently active turn instead of starting a separate turn.
 - `turnInterrupt(params:)`: Sends the generated `turn/interrupt` request with `TurnInterruptParams` through the orchestrator-owned runtime, awaits the typed `TurnInterruptResponse`, and stores it in `turnInterruptResponse`. Semantically, this requests early termination of the active turn so it can finish in an interrupted state.
 */

extension CodaxOrchestrator {

		// MARK: - Conversation Summary

	func getConversationSummary(params: GetConversationSummaryParams) async throws -> GetConversationSummaryResponse {
		let response = try await runtime.getConversationSummary(params)
		getConversationSummaryResponse = response
		return response
	}

		// MARK: - Threads

	func threadStart(params: ThreadStartParams) async throws -> ThreadStartResponse {
		let response = try await runtime.threadStart(params)
		threadStartResponse = response
		return response
	}

	func threadResume(params: ThreadResumeParams) async throws -> ThreadResumeResponse {
		let response = try await runtime.threadResume(params)
		threadResumeResponse = response
		return response
	}

	func threadFork(params: ThreadForkParams) async throws -> ThreadForkResponse {
		let response = try await runtime.threadFork(params)
		threadForkResponse = response
		return response
	}

	func threadArchive(params: ThreadArchiveParams) async throws -> ThreadArchiveResponse {
		let response = try await runtime.threadArchive(params)
		threadArchiveResponse = response
		return response
	}

	func threadUnsubscribe(params: ThreadUnsubscribeParams) async throws -> ThreadUnsubscribeResponse {
		let response = try await runtime.threadUnsubscribe(params)
		threadUnsubscribeResponse = response
		return response
	}

	func threadNameSet(params: ThreadSetNameParams) async throws -> ThreadSetNameResponse {
		let response = try await runtime.threadNameSet(params)
		threadSetNameResponse = response
		return response
	}

	func threadMetadataUpdate(params: ThreadMetadataUpdateParams) async throws -> ThreadMetadataUpdateResponse {
		let response = try await runtime.threadMetadataUpdate(params)
		threadMetadataUpdateResponse = response
		return response
	}

	func threadUnarchive(params: ThreadUnarchiveParams) async throws -> ThreadUnarchiveResponse {
		let response = try await runtime.threadUnarchive(params)
		threadUnarchiveResponse = response
		return response
	}

	func threadCompactStart(params: ThreadCompactStartParams) async throws -> ThreadCompactStartResponse {
		let response = try await runtime.threadCompactStart(params)
		threadCompactStartResponse = response
		return response
	}

	func threadRollback(params: ThreadRollbackParams) async throws -> ThreadRollbackResponse {
		let response = try await runtime.threadRollback(params)
		threadRollbackResponse = response
		return response
	}

	func threadList(params: ThreadListParams) async throws -> ThreadListResponse {
		let response = try await runtime.threadList(params)
		threadListResponse = response
		return response
	}

	func threadLoadedList(params: ThreadLoadedListParams) async throws -> ThreadLoadedListResponse {
		let response = try await runtime.threadLoadedList(params)
		threadLoadedListResponse = response
		return response
	}

	func threadRead(params: ThreadReadParams) async throws -> ThreadReadResponse {
		let response = try await runtime.threadRead(params)
		threadReadResponse = response
		return response
	}

	func feedbackUpload(params: FeedbackUploadParams) async throws -> FeedbackUploadResponse {
		let response = try await runtime.feedbackUpload(params)
		feedbackUploadResponse = response
		return response
	}

		// MARK: - Turns

	func turnStart(params: TurnStartParams) async throws -> TurnStartResponse {
		let response = try await runtime.turnStart(params)
		turnStartResponse = response
		return response
	}

	func turnSteer(params: TurnSteerParams) async throws -> TurnSteerResponse {
		let response = try await runtime.turnSteer(params)
		turnSteerResponse = response
		return response
	}

	func turnInterrupt(params: TurnInterruptParams) async throws -> TurnInterruptResponse {
		let response = try await runtime.turnInterrupt(params)
		turnInterruptResponse = response
		return response
	}

}
