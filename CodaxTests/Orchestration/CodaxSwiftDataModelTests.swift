import Foundation
import Testing
@testable import Codax

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
			preview: "Thread",
			ephemeral: false,
			statusData: encode(ThreadStatus.idle)
		)
		let project = Project(name: "Codax", rootPath: "/tmp/codax", threads: [thread])

		#expect(project.thread(codexId: "thread-1") === thread)
		#expect(project.thread(codexId: "missing") == nil)
	}

	@Test func threadModelApplyUpdatesRetainedFieldsOnly() {
		let thread = makeThread(codexId: "thread-1", preview: "Before", updatedAt: 10)
		let model = ThreadModel(thread: thread)
		let updated = makeThread(codexId: "thread-1", preview: "After", updatedAt: 20, name: "Renamed")

		model.apply(thread: updated)

		#expect(model.preview == "After")
		#expect(model.updatedAt == 20)
		#expect(model.name == "Renamed")
		#expect(model.ephemeral == updated.ephemeral)
		#expect(model.status == updated.status)
	}

	@Test func threadStatusRoundTripsThroughStatusData() {
		let thread = makeThread(
			codexId: "thread-1",
			preview: "Thread",
			updatedAt: 10,
			status: .active(activeFlags: [.waitingOnApproval])
		)
		let model = ThreadModel(thread: thread)

		#expect(model.status == thread.status)
	}

	@Test func turnModelApplyUpdatesStatusItemsAndError() {
		let original = makeTurn(codexId: "turn-1", text: "Before", status: .inProgress, error: nil)
		let model = TurnModel(turn: original)
		let updated = makeTurn(
			codexId: "turn-1",
			text: "After",
			status: .failed,
			error: TurnError(message: "Boom", codexErrorInfo: .badRequest, additionalDetails: "details")
		)

		model.apply(turn: updated)

		#expect(model.status == .failed)
		#expect(model.items == updated.items)
		#expect(model.error == updated.error)
	}

	@Test func turnModelSerializedFieldsRoundTrip() {
		let error = TurnError(
			message: "Rate limited",
			codexErrorInfo: .responseTooManyFailedAttempts(httpStatusCode: 429),
			additionalDetails: "retry later"
		)
		let turn = makeTurn(codexId: "turn-1", text: "Hello", status: .completed, error: error)
		let model = TurnModel(turn: turn)

		#expect(model.status == .completed)
		#expect(model.items == turn.items)
		#expect(model.error == error)
	}

	@Test func invalidStoredEnumDataReturnsNil() {
		let thread = ThreadModel(
			codexId: "thread-1",
			createdAt: 1,
			updatedAt: 1,
			preview: "Thread",
			ephemeral: false,
			statusData: Data("not-json".utf8)
		)
		let turn = TurnModel(
			codexId: "turn-1",
			statusData: Data("not-json".utf8),
			itemsData: Data("[]".utf8)
		)

		#expect(thread.status == nil)
		#expect(turn.status == nil)
	}
}

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
		"source": NSNull(),
		"agentNickname": NSNull(),
		"agentRole": NSNull(),
		"gitInfo": NSNull(),
		"name": name as Any,
		"turns": [],
	])
}

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
