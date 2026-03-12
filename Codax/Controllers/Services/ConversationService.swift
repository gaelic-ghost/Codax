import Foundation

/*
 `ConversationService` includes the conversation-summary request/response surface for the Codex app-server. Semantically, this section represents a read-only summary boundary: it asks the server for a typed summary of conversation state and stores the most recent answer verbatim, without synthesizing additional presentation state.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `getConversationSummaryResponse`: Holds the most recent `GetConversationSummaryResponse` returned by `getConversationSummary`. Semantically, this is the latest typed server summary of the requested conversation context.

 Functions:
 - `getConversationSummary(using:params:)`: Sends the generated `getConversationSummary` request with `GetConversationSummaryParams`, awaits the typed `GetConversationSummaryResponse`, and stores it in `getConversationSummaryResponse`. Semantically, this fetches a server-produced summary projection instead of the full underlying conversation payload.
 */

/*
 `ConversationService` includes the thread-management request/response surface for the Codex app-server plus the colocated feedback upload request. Per the app-server protocol and README, a thread is the top-level conversation primitive that contains turns and items; this surface creates threads, resumes or forks them, reads stored history, lists persisted or loaded threads, mutates archive and metadata state, compacts or rolls back history, and unsubscribes the current connection from thread events. Semantically, each property in this section stores the latest typed result for a single thread-related request so the UI can react to exact protocol outputs without inventing a second domain model.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

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
 - `threadStart(using:params:)`: Sends the generated `thread/start` request with `ThreadStartParams`, awaits the typed `ThreadStartResponse`, and stores it in `threadStartResponse`. Semantically, this opens a brand-new thread and begins the lifecycle of a fresh Codex conversation.
 - `threadResume(using:params:)`: Sends the generated `thread/resume` request with `ThreadResumeParams`, awaits the typed `ThreadResumeResponse`, and stores it in `threadResumeResponse`. Semantically, this reattaches the connection to an existing thread so subsequent turn requests continue that conversation.
 - `threadFork(using:params:)`: Sends the generated `thread/fork` request with `ThreadForkParams`, awaits the typed `ThreadForkResponse`, and stores it in `threadForkResponse`. Semantically, this branches an existing conversation into a new one that starts from copied history.
 - `threadArchive(using:params:)`: Sends the generated `thread/archive` request with `ThreadArchiveParams`, awaits the typed `ThreadArchiveResponse`, and stores it in `threadArchiveResponse`. Semantically, this archives a thread's persisted rollout.
 - `threadUnsubscribe(using:params:)`: Sends the generated `thread/unsubscribe` request with `ThreadUnsubscribeParams`, awaits the typed `ThreadUnsubscribeResponse`, and stores it in `threadUnsubscribeResponse`. Semantically, this removes the current connection's live-event subscription for a loaded thread.
 - `threadNameSet(using:params:)`: Sends the generated `thread/name/set` request with `ThreadSetNameParams`, awaits the typed `ThreadSetNameResponse`, and stores it in `threadSetNameResponse`. Semantically, this writes or updates the human-facing name associated with a thread.
 - `threadMetadataUpdate(using:params:)`: Sends the generated `thread/metadata/update` request with `ThreadMetadataUpdateParams`, awaits the typed `ThreadMetadataUpdateResponse`, and stores it in `threadMetadataUpdateResponse`. Semantically, this patches persisted metadata fields for a thread without fully resuming it.
 - `threadUnarchive(using:params:)`: Sends the generated `thread/unarchive` request with `ThreadUnarchiveParams`, awaits the typed `ThreadUnarchiveResponse`, and stores it in `threadUnarchiveResponse`. Semantically, this restores an archived conversation back into the active thread set.
 - `threadCompactStart(using:params:)`: Sends the generated `thread/compact/start` request with `ThreadCompactStartParams`, awaits the typed `ThreadCompactStartResponse`, and stores it in `threadCompactStartResponse`. Semantically, this requests history compaction while expecting detailed progress to arrive later through streamed notifications.
 - `threadRollback(using:params:)`: Sends the generated `thread/rollback` request with `ThreadRollbackParams`, awaits the typed `ThreadRollbackResponse`, and stores it in `threadRollbackResponse`. Semantically, this prunes a trailing portion of conversation history and returns the resulting updated thread state.
 - `threadList(using:params:)`: Sends the generated `thread/list` request with `ThreadListParams`, awaits the typed `ThreadListResponse`, and stores it in `threadListResponse`. Semantically, this paginates through persisted thread history using filters and sort options.
 - `threadLoadedList(using:params:)`: Sends the generated `thread/loaded/list` request with `ThreadLoadedListParams`, awaits the typed `ThreadLoadedListResponse`, and stores it in `threadLoadedListResponse`. Semantically, this reads the server's current in-memory loaded-thread set.
 - `threadRead(using:params:)`: Sends the generated `thread/read` request with `ThreadReadParams`, awaits the typed `ThreadReadResponse`, and stores it in `threadReadResponse`. Semantically, this fetches a stored thread snapshot, optionally including full turns, without changing whether the thread is loaded.
 - `feedbackUpload(using:params:)`: Sends the generated `feedback/upload` request with `FeedbackUploadParams`, awaits the typed `FeedbackUploadResponse`, and stores it in `feedbackUploadResponse`. Semantically, this submits a feedback report about Codex behavior and preserves the tracking response.
 */

/*
 `ConversationService` includes the turn-control request/response surface for the Codex app-server. Per the app-server protocol and README, a turn is one conversational unit inside a thread: it begins with user input, streams item-level execution and model output, and finishes with a final turn status. This section only caches the initial typed responses for turn control requests; the richer live execution details continue to arrive over notifications outside this class.

 References:
 - OpenAI Codex app-server docs: https://developers.openai.com/codex/app-server/#api-overview
 - OpenAI Codex CLI config reference: https://developers.openai.com/codex/config-reference/
 - Codex app-server README: https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md

 Properties:
 - `turnStartResponse`: Holds the most recent `TurnStartResponse` returned by `turn/start`. Semantically, this is the initial accepted turn payload for a new user message inside a thread.
 - `turnSteerResponse`: Holds the most recent `TurnSteerResponse` returned by `turn/steer`. Semantically, this is the acknowledgement that additional user input was attached to an already active in-flight turn.
 - `turnInterruptResponse`: Holds the most recent `TurnInterruptResponse` returned by `turn/interrupt`. Semantically, this is the acknowledgement that cancellation was requested for a running turn.

 Functions:
 - `turnStart(using:params:)`: Sends the generated `turn/start` request with `TurnStartParams`, awaits the typed `TurnStartResponse`, and stores it in `turnStartResponse`. Semantically, this begins a new turn inside an existing thread and triggers the streamed turn/item lifecycle.
 - `turnSteer(using:params:)`: Sends the generated `turn/steer` request with `TurnSteerParams`, awaits the typed `TurnSteerResponse`, and stores it in `turnSteerResponse`. Semantically, this injects additional guidance into the currently active turn instead of starting a separate turn.
 - `turnInterrupt(using:params:)`: Sends the generated `turn/interrupt` request with `TurnInterruptParams`, awaits the typed `TurnInterruptResponse`, and stores it in `turnInterruptResponse`. Semantically, this requests early termination of the active turn so it can finish in an interrupted state.
 */

final class ConversationService {
	
	// MARK: - Conversation Summary

	var getConversationSummaryResponse: GetConversationSummaryResponse?


	// MARK: - Threads

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
	var feedbackUploadResponse: FeedbackUploadResponse?

		// MARK: - Turns

	var turnStartResponse: TurnStartResponse?
	var turnSteerResponse: TurnSteerResponse?
	var turnInterruptResponse: TurnInterruptResponse?


}

	// MARK: INTERNAL METHODS

extension ConversationService {

		// MARK: - Conversation Summary

	func getConversationSummary(using connection: CodexConnection, params: GetConversationSummaryParams) async throws -> GetConversationSummaryResponse {
		let response = try await connection.getConversationSummary(params)
		getConversationSummaryResponse = response
		return response
	}

		// MARK: - Threads

	func threadStart(using connection: CodexConnection, params: ThreadStartParams) async throws -> ThreadStartResponse {
		let response = try await connection.threadStart(params)
		threadStartResponse = response
		return response
	}

	func threadResume(using connection: CodexConnection, params: ThreadResumeParams) async throws -> ThreadResumeResponse {
		let response = try await connection.threadResume(params)
		threadResumeResponse = response
		return response
	}

	func threadFork(using connection: CodexConnection, params: ThreadForkParams) async throws -> ThreadForkResponse {
		let response = try await connection.threadFork(params)
		threadForkResponse = response
		return response
	}

	func threadArchive(using connection: CodexConnection, params: ThreadArchiveParams) async throws -> ThreadArchiveResponse {
		let response = try await connection.threadArchive(params)
		threadArchiveResponse = response
		return response
	}

	func threadUnsubscribe(using connection: CodexConnection, params: ThreadUnsubscribeParams) async throws -> ThreadUnsubscribeResponse {
		let response = try await connection.threadUnsubscribe(params)
		threadUnsubscribeResponse = response
		return response
	}

	func threadNameSet(using connection: CodexConnection, params: ThreadSetNameParams) async throws -> ThreadSetNameResponse {
		let response = try await connection.threadNameSet(params)
		threadSetNameResponse = response
		return response
	}

	func threadMetadataUpdate(using connection: CodexConnection, params: ThreadMetadataUpdateParams) async throws -> ThreadMetadataUpdateResponse {
		let response = try await connection.threadMetadataUpdate(params)
		threadMetadataUpdateResponse = response
		return response
	}

	func threadUnarchive(using connection: CodexConnection, params: ThreadUnarchiveParams) async throws -> ThreadUnarchiveResponse {
		let response = try await connection.threadUnarchive(params)
		threadUnarchiveResponse = response
		return response
	}

	func threadCompactStart(using connection: CodexConnection, params: ThreadCompactStartParams) async throws -> ThreadCompactStartResponse {
		let response = try await connection.threadCompactStart(params)
		threadCompactStartResponse = response
		return response
	}

	func threadRollback(using connection: CodexConnection, params: ThreadRollbackParams) async throws -> ThreadRollbackResponse {
		let response = try await connection.threadRollback(params)
		threadRollbackResponse = response
		return response
	}

	func threadList(using connection: CodexConnection, params: ThreadListParams) async throws -> ThreadListResponse {
		let response = try await connection.threadList(params)
		threadListResponse = response
		return response
	}

	func threadLoadedList(using connection: CodexConnection, params: ThreadLoadedListParams) async throws -> ThreadLoadedListResponse {
		let response = try await connection.threadLoadedList(params)
		threadLoadedListResponse = response
		return response
	}

	func threadRead(using connection: CodexConnection, params: ThreadReadParams) async throws -> ThreadReadResponse {
		let response = try await connection.threadRead(params)
		threadReadResponse = response
		return response
	}

	func feedbackUpload(using connection: CodexConnection, params: FeedbackUploadParams) async throws -> FeedbackUploadResponse {
		let response = try await connection.feedbackUpload(params)
		feedbackUploadResponse = response
		return response
	}

		// MARK: - Turns

	func turnStart(using connection: CodexConnection, params: TurnStartParams) async throws -> TurnStartResponse {
		let response = try await connection.turnStart(params)
		turnStartResponse = response
		return response
	}

	func turnSteer(using connection: CodexConnection, params: TurnSteerParams) async throws -> TurnSteerResponse {
		let response = try await connection.turnSteer(params)
		turnSteerResponse = response
		return response
	}

	func turnInterrupt(using connection: CodexConnection, params: TurnInterruptParams) async throws -> TurnInterruptResponse {
		let response = try await connection.turnInterrupt(params)
		turnInterruptResponse = response
		return response
	}

}

