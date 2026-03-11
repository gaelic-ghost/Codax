import Foundation
import SwiftData
import Testing
@testable import Codax

@MainActor
struct CodaxPersistenceBridgeTests {
	@Test func persistThreadListStoresDurableSummaries() throws {
		let harness = try makeBridgeHarness()
		let first = makeThread(codexId: "thread-1", preview: "First", updatedAt: 10, turns: [])
		let second = makeThread(codexId: "thread-2", preview: "Second", updatedAt: 20, turns: [])

		try harness.bridge.persistThreadList([first, second])

		let threads = try fetchThreads(from: harness.modelContainer)
		#expect(threads.map(\.codexId) == ["thread-1", "thread-2"])
		#expect(threads.allSatisfy { $0.hydrationState == .summary })
	}

	@Test func persistThreadDetailHydratesTurnsAndMetadata() throws {
		let harness = try makeBridgeHarness()
		let thread = makeThread(
			codexId: "thread-1",
			preview: "Hydrated",
			updatedAt: 10,
			turns: [makeTurn(codexId: "turn-1", text: "Hello")]
		)

		try harness.bridge.persistThreadDetail(thread)

		let storedThread = try #require(try harness.bridge.fetchThread(codexId: "thread-1"))
		#expect(storedThread.hydrationState == .detail)
		#expect(storedThread.turns.count == 1)
		#expect(storedThread.turns.first?.codexId == "turn-1")
	}

	@Test func persistThreadDetailReconcilesRemovedTurns() throws {
		let harness = try makeBridgeHarness()
		let initial = makeThread(
			codexId: "thread-1",
			preview: "Initial",
			updatedAt: 10,
			turns: [
				makeTurn(codexId: "turn-1", text: "First"),
				makeTurn(codexId: "turn-2", text: "Second"),
			]
		)
		try harness.bridge.persistThreadDetail(initial)

		let updated = makeThread(
			codexId: "thread-1",
			preview: "Updated",
			updatedAt: 20,
			turns: [makeTurn(codexId: "turn-2", text: "Second updated")]
		)
		try harness.bridge.persistThreadDetail(updated)

		let storedThread = try #require(try harness.bridge.fetchThread(codexId: "thread-1"))
		#expect(storedThread.turns.count == 1)
		#expect(storedThread.turns.first?.codexId == "turn-2")
		#expect(storedThread.preview == "Updated")
	}

	@Test func staleHydrationPolicyRespectsLastHydratedAt() throws {
		let harness = try makeBridgeHarness()
		let thread = makeThread(codexId: "thread-1", preview: "Detail", updatedAt: 10, turns: [])
		try harness.bridge.persistThreadDetail(thread)

		#expect(try harness.bridge.shouldHydrateThreadDetail(codexId: "thread-1", maxAge: 60) == false)
		#expect(try harness.bridge.shouldHydrateThreadDetail(codexId: "thread-1", maxAge: -1) == true)
		#expect(try harness.bridge.shouldHydrateThreadDetail(codexId: "missing", maxAge: 60) == true)
	}
}

@MainActor
private func makeBridgeHarness() throws -> (bridge: CodaxPersistenceBridge, modelContainer: ModelContainer) {
	let modelContainer = try CodaxPersistenceBridge.makeModelContainer(inMemory: true)
	return (CodaxPersistenceBridge(modelContainer: modelContainer), modelContainer)
}

@MainActor
private func fetchThreads(from modelContainer: ModelContainer) throws -> [ThreadModel] {
	try modelContainer.mainContext.fetch(
		FetchDescriptor<ThreadModel>(sortBy: [SortDescriptor(\ThreadModel.codexId)])
	)
}

private func makeThread(
	codexId: String,
	preview: String,
	updatedAt: Int,
	turns: [Turn]
) -> Codax.Thread {
	try! decode(Codax.Thread.self, from: [
		"id": codexId,
		"preview": preview,
		"ephemeral": false,
		"modelProvider": "openai",
		"createdAt": 1,
		"updatedAt": updatedAt,
		"status": ["type": "idle"],
		"path": NSNull(),
		"cwd": "/tmp/codax",
		"cliVersion": "0.112.0",
		"source": "appServer",
		"agentNickname": NSNull(),
		"agentRole": NSNull(),
		"gitInfo": NSNull(),
		"name": "Thread \(codexId)",
		"turns": try! codexJSONObject(from: turns),
	])
}

private func makeTurn(codexId: String, text: String) -> Turn {
	try! decode(Turn.self, from: [
		"id": codexId,
		"items": [[
			"type": "agentMessage",
			"id": "item-\(codexId)",
			"text": text,
			"phase": "final_answer",
		]],
		"status": "completed",
		"error": NSNull(),
	])
}

private func decode<T: Decodable>(_ type: T.Type, from jsonObject: [String: Any]) throws -> T {
	let data = try JSONSerialization.data(withJSONObject: jsonObject)
	return try JSONDecoder().decode(T.self, from: data)
}

private func codexJSONObject<T: Encodable>(from value: T) throws -> Any {
	let data = try JSONEncoder().encode(value)
	return try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
}
