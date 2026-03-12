import Foundation
import SwiftData
import Testing
@testable import Codax

// MARK: - SwiftData Model Tests

struct CodaxSwiftDataModelTests {
	@Test func projectInitializerPersistsDefaults() {
		let project = Project(name: "Codax", rootPath: "/tmp/codax")

		#expect(project.name == "Codax")
		#expect(project.rootPath == "/tmp/codax")
		#expect(project.isActive == false)
		#expect(project.threads.isEmpty)
	}

	@Test func projectThreadLookupFindsMatchingCodexId() {
		let thread = ThreadModel(
			codexId: "thread-1",
			createdAt: 1,
			updatedAt: 2,
			hydrationState: .summary,
			preview: "Thread",
			ephemeral: false,
				modelProvider: "openai",
				cwd: "/tmp/codax",
				cliVersion: "0.114.0",
				statusData: encode(ThreadStatus.idle),
				sourceData: encode(SessionSource.appServer)
			)
		let project = Project(name: "Codax", rootPath: "/tmp/codax", threads: [thread])

		#expect(project.thread(codexId: "thread-1") === thread)
		#expect(project.thread(codexId: "missing") == nil)
	}

	@Test func threadModelApplyUpdatesRetainedFieldsOnly() {
		let thread = makeThread(codexId: "thread-1", preview: "Before", updatedAt: 10)
		let model = ThreadModel(thread: thread, hydrationState: .summary)
		let updated = makeThread(codexId: "thread-1", preview: "After", updatedAt: 20, name: "Renamed")

		model.applySummary(thread: updated)

		#expect(model.preview == "After")
		#expect(model.updatedAt == 20)
		#expect(model.name == "Renamed")
		#expect(model.ephemeral == updated.ephemeral)
		#expect(model.status == updated.status)
		#expect(model.modelProvider == updated.modelProvider)
		#expect(model.cwd == updated.cwd)
	}

	@Test func threadStatusRoundTripsThroughStatusData() {
		let thread = makeThread(
			codexId: "thread-1",
			preview: "Thread",
			updatedAt: 10,
			status: .active(activeFlags: [.waitingOnApproval])
		)
			let model = ThreadModel(thread: thread, hydrationState: .summary)
			#expect(model.status == thread.status)
	}

	@Test func turnModelApplyUpdatesStatusItemsAndError() {
		let original = makeTurn(codexId: "turn-1", text: "Before", status: .inProgress, error: nil)
		let model = TurnModel(turn: original, sequenceIndex: 0)
		let updated = makeTurn(
			codexId: "turn-1",
			text: "After",
			status: TurnStatus.failed,
			error: TurnError(message: "Boom", codexErrorInfo: .badRequest, additionalDetails: "details")
		)

		model.apply(turn: updated, sequenceIndex: 0)

		#expect(model.status == TurnStatus.failed)
		#expect(model.threadItems == updated.items)
		#expect(model.error == updated.error)
	}

	@Test func turnModelSerializedFieldsRoundTrip() {
		let error = TurnError(
			message: "Rate limited",
			codexErrorInfo: .responseTooManyFailedAttempts(["httpStatusCode": .number(429)]),
			additionalDetails: "retry later"
		)
		let turn = makeTurn(codexId: "turn-1", text: "Hello", status: .completed, error: error)
		let model = TurnModel(turn: turn, sequenceIndex: 0)

		#expect(model.status == TurnStatus.completed)
		#expect(model.threadItems == turn.items)
		#expect(model.error == error)
	}

	@Test func invalidStoredEnumDataReturnsNil() {
		let thread = ThreadModel(
			codexId: "thread-1",
			createdAt: 1,
			updatedAt: 1,
			hydrationState: .summary,
			preview: "Thread",
			ephemeral: false,
				modelProvider: "openai",
				cwd: "/tmp/codax",
				cliVersion: "0.114.0",
				statusData: Data("not-json".utf8),
				sourceData: encode(SessionSource.appServer)
			)
		let turn = TurnModel(
			codexId: "turn-1",
			sequenceIndex: 0,
			statusData: Data("not-json".utf8),
			thread: nil,
			items: []
		)

		#expect(thread.status == nil)
		#expect(turn.status == nil)
	}

	@Test func threadHydrationStateAndTokenUsageRoundTrip() {
		let thread = makeThread(codexId: "thread-1", preview: "Thread", updatedAt: 10)
		let model = ThreadModel(thread: thread, hydrationState: .detail)
		let tokenUsage = makeThreadTokenUsage()

		model.setTokenUsage(tokenUsage)
		model.setArchived(true)
		model.setClosed(true)

		#expect(model.hydrationState == .detail)
		#expect(model.tokenUsage == tokenUsage)
		#expect(model.isArchived)
		#expect(model.isClosed)
	}
}

// MARK: - Thread Fixtures

private func makeThread(
	codexId: String,
	preview: String,
	createdAt: Int = 1,
	updatedAt: Int,
	name: String? = nil,
	status: ThreadStatus = .idle
) -> Codax.Thread {
	try! decode(Codax.Thread.self, from: [
		"id": codexId,
		"preview": preview,
		"ephemeral": false,
		"modelProvider": "openai",
		"createdAt": createdAt,
		"updatedAt": updatedAt,
		"status": try! codexJSONObject(from: status),
		"path": NSNull(),
		"cwd": "/tmp",
		"cliVersion": "0.111.0",
		"source": "appServer",
		"agentNickname": NSNull(),
		"agentRole": NSNull(),
		"gitInfo": NSNull(),
		"name": name as Any,
		"turns": [],
	])
}

// MARK: - Token Usage Fixtures

private func makeThreadTokenUsage() -> ThreadTokenUsage {
	try! decode(ThreadTokenUsage.self, from: [
		"total": [
			"inputTokens": 10,
			"cachedInputTokens": 0,
			"outputTokens": 5,
			"reasoningOutputTokens": 0,
			"totalTokens": 15,
		],
		"last": [
			"inputTokens": 10,
			"cachedInputTokens": 0,
			"outputTokens": 5,
			"reasoningOutputTokens": 0,
			"totalTokens": 15,
		],
		"modelContextWindow": 128000,
	])
}

// MARK: - Turn Fixtures

private func makeTurn(
	codexId: String,
	text: String,
	status: TurnStatus,
	error: TurnError?
) -> Turn {
	try! decode(Turn.self, from: [
		"id": codexId,
		"items": [
			[
				"type": "agentMessage",
				"id": "item-\(codexId)",
				"text": text,
				"phase": "final_answer",
			],
		],
		"status": try! codexJSONObject(from: status),
		"error": try! codexJSONObject(from: error) as Any,
	])
}

// MARK: - Encoding Helpers

private func encode<T: Encodable>(_ value: T) -> Data {
	try! JSONEncoder().encode(value)
}

private func decode<T: Decodable>(_ type: T.Type, from jsonObject: [String: Any]) throws -> T {
	let data = try JSONSerialization.data(withJSONObject: jsonObject)
	return try JSONDecoder().decode(T.self, from: data)
}

private func codexJSONObject<T: Encodable>(from value: T?) throws -> Any {
	guard let value else { return NSNull() }
	let data = try JSONEncoder().encode(value)
	return try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
}
