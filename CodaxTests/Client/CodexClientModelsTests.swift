import Foundation
import Testing
@testable import Codax

struct CodexClientModelsTests {
	@Test func codexValueRoundTripsArbitraryPayload() throws {
		let value = try decode(
			CodexValue.self,
			from: """
			{
			  "name": "Codax",
			  "enabled": true,
			  "items": [1, null, { "nested": "value" }]
			}
			"""
		)

		#expect(value == .object([
			"name": .string("Codax"),
			"enabled": .bool(true),
			"items": .array([
				.number(1),
				.null,
				.object(["nested": .string("value")]),
			]),
		]))
	}

	@Test func askForApprovalRoundTripsStringAndStructuredCases() throws {
		let stringValue = try decode(AskForApproval.self, from: #""on-request""#)
		#expect(stringValue == .onRequest)

		let structured = try decode(
			AskForApproval.self,
			from: """
			{
			  "reject": {
			    "sandbox_approval": true,
			    "rules": false,
			    "mcp_elicitations": true
			  }
			}
			"""
		)

		#expect(structured == .reject(.init(sandboxApproval: true, rules: false, mcpElicitations: true)))
	}

	@Test func modelSupportEnumsDecodeStructuredPayloads() throws {
		let automation = try decode(MacOsAutomationPermission.self, from: #"{"bundle_ids":["com.apple.Terminal"]}"#)
		#expect(automation == .bundleIDs(["com.apple.Terminal"]))

		let error = try decode(CodexErrorInfo.self, from: #"{"httpConnectionFailed":{"httpStatusCode":429}}"#)
		#expect(error == .httpConnectionFailed(httpStatusCode: 429))

		let source = try decode(
			SubAgentSource.self,
			from: #"{"thread_spawn":{"parent_thread_id":"thread-1","depth":2,"agent_nickname":"reviewer","agent_role":"critic"}}"#
		)
		#expect(source == .threadSpawn(parentThreadCodexId: "thread-1", depth: 2, agentNickname: "reviewer", agentRole: "critic"))
	}

	@Test func taggedModelSupportEnumsRoundTrip() throws {
		let outputItem = try decode(
			DynamicToolCallOutputContentItem.self,
			from: #"{"type":"inputImage","imageUrl":"https://example.com/image.png"}"#
		)
		#expect(outputItem == .inputImage(imageUrl: "https://example.com/image.png"))

		let parsedCommand = try decode(
			ParsedCommand.self,
			from: #"{"type":"list_files","cmd":"ls","path":"/tmp"}"#
		)
		#expect(parsedCommand == .listFiles(cmd: "ls", path: "/tmp"))

		let fileChange = try decode(
			FileChange.self,
			from: #"{"type":"update","unified_diff":"@@ -1 +1 @@","move_path":"New.swift"}"#
		)
		#expect(fileChange == .update(unifiedDiff: "@@ -1 +1 @@", movePath: "New.swift"))
	}

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

	@Test func threadStatusRoundTripsTaggedEncoding() throws {
		let status = ThreadStatus.active(activeFlags: [.waitingOnApproval, .waitingOnUserInput])

		let encoded = try JSONEncoder().encode(status)
		let value = try JSONDecoder().decode(CodexValue.self, from: encoded)
		let decoded = try JSONDecoder().decode(ThreadStatus.self, from: encoded)

		#expect(value == .object([
			"type": .string("active"),
			"activeFlags": .array([
				.string("waitingOnApproval"),
				.string("waitingOnUserInput"),
			]),
		]))
		#expect(decoded == status)
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

	@Test func knownThreadItemsRoundTripWithTypeDiscriminator() throws {
		try assertThreadItemRoundTrip(
			"""
			{
			  "type": "agentMessage",
			  "id": "item-7",
			  "text": "Hello",
			  "phase": "final_answer"
			}
			""",
			expected: .object([
				"type": .string("agentMessage"),
				"id": .string("item-7"),
				"text": .string("Hello"),
				"phase": .string("final_answer"),
			])
		)
		try assertThreadItemRoundTrip(
			"""
			{
			  "type": "commandExecution",
			  "id": "item-8",
			  "command": "swift test",
			  "cwd": "/tmp",
			  "processId": "123",
			  "status": "completed",
			  "commandActions": [],
			  "aggregatedOutput": "ok",
			  "exitCode": 0,
			  "durationMs": 200
			}
			""",
			expected: .object([
				"type": .string("commandExecution"),
				"id": .string("item-8"),
				"command": .string("swift test"),
				"cwd": .string("/tmp"),
				"processId": .string("123"),
				"status": .string("completed"),
				"commandActions": .array([]),
				"aggregatedOutput": .string("ok"),
				"exitCode": .number(0),
				"durationMs": .number(200),
			])
		)
		try assertThreadItemRoundTrip(
			"""
			{
			  "type": "fileChange",
			  "id": "item-9",
			  "changes": [
			    {
			      "path": "ContentView.swift",
			      "kind": { "type": "update", "move_path": null },
			      "diff": "@@"
			    }
			  ],
			  "status": "completed"
			}
			""",
			expected: .object([
				"type": .string("fileChange"),
				"id": .string("item-9"),
				"changes": .array([
					.object([
						"path": .string("ContentView.swift"),
						"kind": .object([
							"type": .string("update"),
							"move_path": .null,
						]),
						"diff": .string("@@"),
					]),
				]),
				"status": .string("completed"),
			])
		)
		try assertThreadItemRoundTrip(
			"""
			{
			  "type": "contextCompaction",
			  "id": "item-10"
			}
			""",
			expected: .object([
				"type": .string("contextCompaction"),
				"id": .string("item-10"),
			])
		)
	}

	@Test func accountTaggedEnumsRoundTripWithUnchangedWireKeys() throws {
		let loginParams = LoginAccountParams.chatgptAuthTokens(
			accessToken: "token-1",
			chatgptAccountId: "acct-1",
			chatgptPlanType: "plus"
		)
		let paramsData = try JSONEncoder().encode(loginParams)
		let paramsValue = try JSONDecoder().decode(CodexValue.self, from: paramsData)
		let decodedParams = try JSONDecoder().decode(LoginAccountParams.self, from: paramsData)

		#expect(paramsValue == .object([
			"type": .string("chatgptAuthTokens"),
			"accessToken": .string("token-1"),
			"chatgptAccountId": .string("acct-1"),
			"chatgptPlanType": .string("plus"),
		]))
		guard case let .chatgptAuthTokens(accessToken, accountId, planType) = decodedParams else {
			Issue.record("Expected chatgptAuthTokens login params.")
			return
		}
		#expect(accessToken == "token-1")
		#expect(accountId == "acct-1")
		#expect(planType == "plus")

		let loginResponse = LoginAccountResponse.chatgpt(
			loginId: "login-1",
			authURL: URL(string: "https://example.com/auth")!
		)
		let responseData = try JSONEncoder().encode(loginResponse)
		let responseValue = try JSONDecoder().decode(CodexValue.self, from: responseData)
		let decodedResponse = try JSONDecoder().decode(LoginAccountResponse.self, from: responseData)

		#expect(responseValue == .object([
			"type": .string("chatgpt"),
			"loginId": .string("login-1"),
			"authUrl": .string("https://example.com/auth"),
		]))
		guard case let .chatgpt(loginId, authURL) = decodedResponse else {
			Issue.record("Expected chatgpt login response.")
			return
		}
		#expect(loginId == "login-1")
		#expect(authURL == URL(string: "https://example.com/auth")!)
	}
}

private extension TurnStatus {
	static let allCases: [TurnStatus] = [.inProgress, .completed, .interrupted, .failed]
}

private func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
	let data = Data(json.utf8)
	return try JSONDecoder().decode(T.self, from: data)
}

private func assertThreadItemRoundTrip(_ json: String, expected: CodexValue) throws {
	let original = try decode(ThreadItem.self, from: json)
	let encoded = try JSONEncoder().encode(original)
	let value = try JSONDecoder().decode(CodexValue.self, from: encoded)
	let decoded = try JSONDecoder().decode(ThreadItem.self, from: encoded)

	#expect(value == expected)
	#expect(decoded == original)
}
