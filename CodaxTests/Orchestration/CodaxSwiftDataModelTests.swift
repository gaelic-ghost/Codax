import Foundation
import Testing
@testable import Codax

struct CodaxSwiftDataModelTests {
	@Test func projectInitializerPersistsDefaults() {
		let project = Project(name: "Codax", rootPath: "/tmp/codax")

		#expect(project.name == "Codax")
		#expect(project.rootPath == "/tmp/codax")
		#expect(project.isActive == false)
		#expect(project.selectedThreadCodexId == nil)
		#expect(project.threads.isEmpty)
	}

	@Test func projectUpsertThreadInsertsAndUpdatesByCodexId() {
		let project = Project(name: "Codax", rootPath: "/tmp/codax")
		let original = makeThread(codexId: "thread-1", preview: "Original", updatedAt: 10)
		let updated = makeThread(codexId: "thread-1", preview: "Updated", updatedAt: 20)

		let inserted = project.upsertThread(from: original)
		let replaced = project.upsertThread(from: updated)

		#expect(project.threads.count == 1)
		#expect(inserted === replaced)
		#expect(replaced.preview == "Updated")
		#expect(replaced.updatedAt == 20)
	}

	@Test func projectSelectionTracksSelectedThreadAndFlags() {
		let project = Project(name: "Codax", rootPath: "/tmp/codax")
		_ = project.upsertThread(from: makeThread(codexId: "thread-1", preview: "One", updatedAt: 10))
		_ = project.upsertThread(from: makeThread(codexId: "thread-2", preview: "Two", updatedAt: 20))

		project.selectThread(codexId: "thread-2")

		#expect(project.selectedThreadCodexId == "thread-2")
		#expect(project.thread(codexId: "thread-1")?.isSelected == false)
		#expect(project.thread(codexId: "thread-2")?.isSelected == true)
	}

	@Test func orderedThreadsUsesUpdatedAtThenCreatedAtThenCodexId() {
		let project = Project(name: "Codax", rootPath: "/tmp/codax")
		_ = project.upsertThread(from: makeThread(codexId: "thread-a", preview: "A", createdAt: 1, updatedAt: 100))
		_ = project.upsertThread(from: makeThread(codexId: "thread-b", preview: "B", createdAt: 2, updatedAt: 100))
		_ = project.upsertThread(from: makeThread(codexId: "thread-c", preview: "C", createdAt: 3, updatedAt: 90))

		#expect(project.orderedThreads.map(\.codexId) == ["thread-b", "thread-a", "thread-c"])
	}

	@Test func threadModelApplyUpdatesMirroredFieldsAndPreservesPresentationState() {
		let thread = makeThread(codexId: "thread-1", preview: "Before", updatedAt: 10)
		let model = ThreadModel(thread: thread)
		model.turnDiff = "pending diff"
		model.setTurnPlan([TurnPlanStep(step: "Ship", status: .inProgress)])
		model.setTokenUsage(makeTokenUsage(total: 42))

		let updated = makeThread(codexId: "thread-1", preview: "After", updatedAt: 20, name: "Renamed")
		model.apply(thread: updated)

		#expect(model.preview == "After")
		#expect(model.updatedAt == 20)
		#expect(model.name == "Renamed")
		#expect(model.turnDiff == "pending diff")
		#expect(model.turnPlan.count == 1)
		#expect(model.tokenUsageTotal == 42)
	}

	@Test func threadModelSerializedFieldsRoundTrip() {
		let thread = makeThread(
			codexId: "thread-1",
			preview: "Thread",
			updatedAt: 10,
			source: .subAgent(.threadSpawn(parentThreadCodexId: "parent-1", depth: 2, agentNickname: "Scout", agentRole: "Reviewer"))
		)
		let model = ThreadModel(thread: thread)
		let plan = [TurnPlanStep(step: "Step A", status: .pending)]
		model.setTurnPlan(plan)

		#expect(model.gitInfo == thread.gitInfo)
		#expect(model.source == thread.source)
		#expect(model.turnPlan.count == 1)
		#expect(model.turnPlan.first?.step == "Step A")
		#expect(model.turnPlan.first?.status == .pending)
	}

	@Test func threadPresentationHelpersBehaveCorrectly() {
		let model = ThreadModel(thread: makeThread(codexId: "thread-1", preview: "Thread", updatedAt: 10))
		let usage = makeTokenUsage(total: 99)
		let plan = [TurnPlanStep(step: "Step A", status: .pending)]

		model.setTokenUsage(usage)
		model.setTurnPlan(plan)
		model.turnDiff = "M File.swift"

		#expect(model.tokenUsageInput == usage.total.inputTokens)
		#expect(model.tokenUsageOutput == usage.total.outputTokens)
		#expect(model.tokenUsageTotal == usage.total.totalTokens)
		#expect(model.turnPlan.count == 1)
		#expect(model.turnPlan.first?.step == "Step A")
		#expect(model.turnPlan.first?.status == .pending)

		model.clearPresentationState()

		#expect(model.tokenUsageInput == nil)
		#expect(model.tokenUsageOutput == nil)
		#expect(model.tokenUsageTotal == nil)
		#expect(model.turnDiff == nil)
		#expect(model.turnPlan.isEmpty)
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

		#expect(model.items == turn.items)
		#expect(model.error == error)
	}

	@Test func rawValueComputedAccessorsFailSafelyForInvalidStatusStrings() {
		let thread = ThreadModel(
			codexId: "thread-1",
			createdAt: 1,
			updatedAt: 1,
			preview: "Thread",
			ephemeral: false,
			modelProvider: "openai",
			statusRawValue: "not-json",
			cwd: "/tmp",
			cliVersion: "0.111.0"
		)
		let turn = TurnModel(codexId: "turn-1", statusRawValue: "not-json", itemsData: Data("[]".utf8))

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
	source: SessionSource? = .cli
) -> Codax.Thread {
	try! decode(Codax.Thread.self, from: [
		"id": codexId,
		"preview": preview,
		"ephemeral": false,
		"modelProvider": "openai",
		"createdAt": createdAt,
		"updatedAt": updatedAt,
		"status": ["type": "idle"],
		"path": "/tmp/\(codexId)",
		"cwd": "/tmp",
		"cliVersion": "0.111.0",
		"source": try! codexJSONObject(from: source ?? .cli),
		"agentNickname": "Agent",
		"agentRole": "Reviewer",
		"gitInfo": [
			"sha": "abc123",
			"branch": "main",
			"originUrl": "https://example.com/repo.git",
		],
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

private func makeTokenUsage(total: Int) -> ThreadTokenUsage {
	ThreadTokenUsage(
		total: TokenUsageBreakdown(
			totalTokens: total,
			inputTokens: total / 3,
			cachedInputTokens: 0,
			outputTokens: total / 3,
			reasoningOutputTokens: total - ((total / 3) * 2)
		),
		last: TokenUsageBreakdown(
			totalTokens: total,
			inputTokens: total / 3,
			cachedInputTokens: 0,
			outputTokens: total / 3,
			reasoningOutputTokens: total - ((total / 3) * 2)
		),
		modelContextWindow: 200_000
	)
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
