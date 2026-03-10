import Foundation
import Testing
@testable import Codax

struct CodexClientModelsTests {
	@Test func threadDecodesWithTypedThreadStatusAndNestedTypes() throws {
		let thread = try decode(
			Thread.self,
			from: """
			{
			  "id": "thread-1",
			  "preview": "Hello",
			  "ephemeral": false,
			  "modelProvider": "openai",
			  "createdAt": 1,
			  "updatedAt": 2,
			  "status": { "type": "active", "activeFlags": ["waitingOnApproval"] },
			  "path": "/tmp/thread-1",
			  "cwd": "/tmp",
			  "cliVersion": "0.112.0",
			  "source": { "subAgent": { "other": "test" } },
			  "agentNickname": "agent",
			  "agentRole": "reviewer",
			  "gitInfo": { "sha": "abc123", "branch": "main", "originUrl": "https://example.com/repo.git" },
			  "name": "Thread 1",
			  "turns": []
			}
			"""
		)

		#expect(thread.status == .active(activeFlags: [.waitingOnApproval]))
		#expect(thread.codexId == "thread-1")
		#expect(thread.source == .subAgent(.other("test")))
		#expect(thread.gitInfo == GitInfo(sha: "abc123", branch: "main", originUrl: "https://example.com/repo.git"))
	}

	@Test(arguments: TurnStatus.allCases) func turnDecodesAllSupportedStatuses(status: TurnStatus) throws {
		let turn = try decode(
			Turn.self,
			from: """
			{
			  "id": "turn-1",
			  "items": [],
			  "status": "\(status.rawValue)",
			  "error": null
			}
			"""
		)

		#expect(turn.status == status)
		#expect(turn.codexId == "turn-1")
	}

	@Test func turnErrorDecodesNullableFields() throws {
		let error = try decode(
			TurnError.self,
			from: """
			{
			  "message": "Something went wrong",
			  "codexErrorInfo": null,
			  "additionalDetails": null
			}
			"""
		)

		#expect(error.message == "Something went wrong")
		#expect(error.codexErrorInfo == nil)
		#expect(error.additionalDetails == nil)
	}

	@Test func itemStartedDecodesAgentMessageVariant() throws {
		let notification = try decode(
			ItemStartedNotification.self,
			from: """
			{
			  "threadId": "thread-1",
			  "turnId": "turn-1",
			  "item": {
			    "type": "agentMessage",
			    "id": "item-1",
			    "text": "Hello from Codex",
			    "phase": "commentary"
			  }
			}
			"""
		)

		guard case let .agentMessage(item) = notification.item else {
			Issue.record("Expected agentMessage item.")
			return
		}
		#expect(notification.threadCodexId == "thread-1")
		#expect(notification.turnCodexId == "turn-1")
		#expect(item.codexId == "item-1")
		#expect(item.phase == .commentary)
		#expect(item.text == "Hello from Codex")
	}

	@Test func itemCompletedDecodesCommandExecutionVariant() throws {
		let notification = try decode(
			ItemCompletedNotification.self,
			from: """
			{
			  "threadId": "thread-1",
			  "turnId": "turn-1",
			  "item": {
			    "type": "commandExecution",
			    "id": "item-2",
			    "command": "swift test",
			    "cwd": "/tmp",
			    "processId": "123",
			    "status": "completed",
			    "commandActions": [],
			    "aggregatedOutput": "ok",
			    "exitCode": 0,
			    "durationMs": 200
			  }
			}
			"""
		)

		guard case let .commandExecution(item) = notification.item else {
			Issue.record("Expected commandExecution item.")
			return
		}
		#expect(notification.threadCodexId == "thread-1")
		#expect(notification.turnCodexId == "turn-1")
		#expect(item.codexId == "item-2")
		#expect(item.status == .completed)
		#expect(item.exitCode == 0)
	}

	@Test func itemCompletedDecodesFileChangeVariant() throws {
		let notification = try decode(
			ItemCompletedNotification.self,
			from: """
			{
			  "threadId": "thread-1",
			  "turnId": "turn-1",
			  "item": {
			    "type": "fileChange",
			    "id": "item-3",
			    "changes": [
			      {
			        "path": "ContentView.swift",
			        "kind": { "type": "update", "move_path": null },
			        "diff": "@@"
			      }
			    ],
			    "status": "completed"
			  }
			}
			"""
		)

		guard case let .fileChange(item) = notification.item else {
			Issue.record("Expected fileChange item.")
			return
		}
		#expect(notification.threadCodexId == "thread-1")
		#expect(notification.turnCodexId == "turn-1")
		#expect(item.codexId == "item-3")
		#expect(item.status == .completed)
		#expect(item.changes.first?.kind == .update(movePath: nil))
	}

	@Test func itemCompletedDecodesReasoningVariant() throws {
		let notification = try decode(
			ItemCompletedNotification.self,
			from: """
			{
			  "threadId": "thread-1",
			  "turnId": "turn-1",
			  "item": {
			    "type": "reasoning",
			    "id": "item-4",
			    "summary": ["First"],
			    "content": ["Second"]
			  }
			}
			"""
		)

		guard case let .reasoning(item) = notification.item else {
			Issue.record("Expected reasoning item.")
			return
		}
		#expect(notification.threadCodexId == "thread-1")
		#expect(notification.turnCodexId == "turn-1")
		#expect(item.codexId == "item-4")
		#expect(item.summary == ["First"])
		#expect(item.content == ["Second"])
	}

	@Test func itemCompletedDecodesContextCompactionVariant() throws {
		let notification = try decode(
			ItemCompletedNotification.self,
			from: """
			{
			  "threadId": "thread-1",
			  "turnId": "turn-1",
			  "item": {
			    "type": "contextCompaction",
			    "id": "item-5"
			  }
			}
			"""
		)

		guard case let .contextCompaction(item) = notification.item else {
			Issue.record("Expected contextCompaction item.")
			return
		}
		#expect(notification.threadCodexId == "thread-1")
		#expect(notification.turnCodexId == "turn-1")
		#expect(item.codexId == "item-5")
	}

	@Test func unknownThreadItemVariantFallsBackToRawPayload() throws {
		let item = try decode(
			ThreadItem.self,
			from: """
			{
			  "type": "futureThing",
			  "id": "item-6",
			  "extra": true
			}
			"""
		)

		guard case let .unknown(raw) = item else {
			Issue.record("Expected unknown fallback item.")
			return
		}
		#expect(raw == .object([
			"type": .string("futureThing"),
			"id": .string("item-6"),
			"extra": .bool(true),
		]))
	}
}

private extension TurnStatus {
	static let allCases: [TurnStatus] = [.inProgress, .completed, .interrupted, .failed]
}

private func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
	let data = Data(json.utf8)
	return try JSONDecoder().decode(T.self, from: data)
}
