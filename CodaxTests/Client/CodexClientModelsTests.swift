import Foundation
import Testing
@testable import Codax

struct CodexClientModelsTests {
	@Test func jsonValueRoundTripsArbitraryPayload() throws {
		let value = try decode(
			JSONValue.self,
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

		#expect(structured == .reject([
			"sandbox_approval": .bool(true),
			"rules": .bool(false),
			"mcp_elicitations": .bool(true),
		]))
	}

	@Test func modelSupportEnumsDecodeStructuredPayloads() throws {
		let automation = try decode(MacOsAutomationPermission.self, from: #"{"bundle_ids":["com.apple.Terminal"]}"#)
		#expect(automation == .bundleIds(["com.apple.Terminal"]))

		let error = try decode(CodexErrorInfo.self, from: #"{"httpConnectionFailed":{"httpStatusCode":429}}"#)
		#expect(error == .httpConnectionFailed([
			"httpStatusCode": .number(429),
		]))

		let source = try decode(
			SubAgentSource.self,
			from: #"{"thread_spawn":{"parent_thread_id":"thread-1","depth":2,"agent_nickname":"reviewer","agent_role":"critic"}}"#
		)
		#expect(source == .threadSpawn([
			"parent_thread_id": .string("thread-1"),
			"depth": .number(2),
			"agent_nickname": .string("reviewer"),
			"agent_role": .string("critic"),
		]))
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
		#expect(thread.id == "thread-1")
		#expect(thread.source == .subAgent(.other("test")))
		#expect(thread.gitInfo == GitInfo(sha: "abc123", branch: "main", originUrl: "https://example.com/repo.git"))
	}

	@Test func threadStatusRoundTripsTaggedEncoding() throws {
		let status = ThreadStatus.active(activeFlags: [.waitingOnApproval, .waitingOnUserInput])

		let encoded = try JSONEncoder().encode(status)
		let value = try JSONDecoder().decode(JSONValue.self, from: encoded)
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
		#expect(turn.id == "turn-1")
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

		guard case let .agentMessage(id, text, phase) = notification.item else {
			Issue.record("Expected agentMessage item.")
			return
		}
		#expect(notification.threadId == "thread-1")
		#expect(notification.turnId == "turn-1")
		#expect(id == "item-1")
		#expect(phase == .commentary)
		#expect(text == "Hello from Codex")
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

		guard case let .commandExecution(id, _, _, _, status, _, _, exitCode, _) = notification.item else {
			Issue.record("Expected commandExecution item.")
			return
		}
		#expect(notification.threadId == "thread-1")
		#expect(notification.turnId == "turn-1")
		#expect(id == "item-2")
		#expect(status == .completed)
		#expect(exitCode == 0)
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
			        "kind": { "type": "update", "move_path": "RenamedContentView.swift" },
			        "diff": "@@"
			      }
			    ],
			    "status": "completed"
			  }
			}
			"""
		)

		guard case let .fileChange(id, changes, status) = notification.item else {
			Issue.record("Expected fileChange item.")
			return
		}
		#expect(notification.threadId == "thread-1")
		#expect(notification.turnId == "turn-1")
		#expect(id == "item-3")
		#expect(status == .completed)
		#expect(changes.first?.kind == .update(movePath: "RenamedContentView.swift"))
	}

	@Test func unknownThreadItemVariantFailsDecoding() throws {
		#expect(throws: DecodingError.self) {
			_ = try decode(
				ThreadItem.self,
				from: """
				{
				  "type": "futureThing",
				  "id": "item-6",
				  "extra": true
				}
				"""
			)
		}
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
		let paramsValue = try JSONDecoder().decode(JSONValue.self, from: paramsData)
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
			authUrl: "https://example.com/auth"
		)
		let responseData = try JSONEncoder().encode(loginResponse)
		let responseValue = try JSONDecoder().decode(JSONValue.self, from: responseData)
		let decodedResponse = try JSONDecoder().decode(LoginAccountResponse.self, from: responseData)

		#expect(responseValue == .object([
			"type": .string("chatgpt"),
			"loginId": .string("login-1"),
			"authUrl": .string("https://example.com/auth"),
		]))
		guard case let .chatgpt(loginId, authUrl) = decodedResponse else {
			Issue.record("Expected chatgpt login response.")
			return
		}
		#expect(loginId == "login-1")
		#expect(authUrl == "https://example.com/auth")
	}

	@Test func accountRoundTripsTaggedEncoding() throws {
		let account = Account.chatgpt(email: "gale@example.com", planType: .plus)
		let data = try JSONEncoder().encode(account)
		let value = try JSONDecoder().decode(JSONValue.self, from: data)
		let decoded = try JSONDecoder().decode(Account.self, from: data)

		#expect(value == .object([
			"type": .string("chatgpt"),
			"email": .string("gale@example.com"),
			"planType": .string("plus"),
		]))

		guard case let .chatgpt(email, planType) = decoded else {
			Issue.record("Expected chatgpt account.")
			return
		}
		#expect(email == "gale@example.com")
		#expect(planType == .plus)
	}
}

private extension TurnStatus {
	static let allCases: [TurnStatus] = [.inProgress, .completed, .interrupted, .failed]
}

private func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
	let data = Data(json.utf8)
	return try JSONDecoder().decode(T.self, from: data)
}

private func assertThreadItemRoundTrip(_ json: String, expected: JSONValue) throws {
	let original = try decode(ThreadItem.self, from: json)
	let encoded = try JSONEncoder().encode(original)
	let value = try JSONDecoder().decode(JSONValue.self, from: encoded)
	let decoded = try JSONDecoder().decode(ThreadItem.self, from: encoded)

	#expect(value == expected)
	#expect(decoded == original)
}
