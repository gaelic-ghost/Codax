import Foundation
import Testing
@testable import Codax

struct CodexClientServerRequestTypesTests {
	@Test func fileChangeApprovalParamsDecodeWithCodexIdentifiers() throws {
		let params = try decode(
			FileChangeRequestApprovalParams.self,
			from: """
			{
			  "threadId": "thread-1",
			  "turnId": "turn-1",
			  "itemId": "item-1",
			  "reason": "Need write access",
			  "grantRoot": "/tmp"
			}
			"""
		)

		#expect(params.threadCodexId == "thread-1")
		#expect(params.turnCodexId == "turn-1")
		#expect(params.itemCodexId == "item-1")
		#expect(params.reason == "Need write access")
		#expect(params.grantRoot == "/tmp")
	}

	@Test func commandExecutionApprovalParamsDecodeTypedPayloads() throws {
		let params = try decode(
			CommandExecutionRequestApprovalParams.self,
			from: """
			{
			  "threadId": "thread-1",
			  "turnId": "turn-1",
			  "itemId": "item-1",
			  "approvalId": "approval-1",
			  "reason": "Need network",
			  "command": "curl https://example.com",
			  "cwd": "/tmp",
			  "commandActions": [
			    { "type": "read", "command": "cat README.md", "name": "README.md", "path": "/tmp/README.md" }
			  ],
			  "additionalPermissions": {
			    "network": { "enabled": true },
			    "fileSystem": { "read": ["/tmp"], "write": ["/tmp/out"] },
			    "macos": {
			      "preferences": "read_only",
			      "automations": "none",
			      "accessibility": false,
			      "calendar": false
			    }
			  },
			  "proposedExecpolicyAmendment": ["curl", "https://example.com"],
			  "proposedNetworkPolicyAmendments": [
			    { "host": "example.com", "action": "allow" }
			  ],
			  "availableDecisions": [
			    "accept",
			    { "acceptWithExecpolicyAmendment": { "execpolicy_amendment": ["curl"] } },
			    { "applyNetworkPolicyAmendment": { "network_policy_amendment": { "host": "example.com", "action": "allow" } } }
			  ]
			}
			"""
		)

		#expect(params.threadCodexId == "thread-1")
		#expect(params.turnCodexId == "turn-1")
		#expect(params.itemCodexId == "item-1")
		#expect(params.commandActions?.count == 1)
		#expect(params.additionalPermissions?.network?.enabled == true)
		#expect(params.proposedExecPolicyAmendment == ExecPolicyAmendment(["curl", "https://example.com"]))
		#expect(params.proposedNetworkPolicyAmendments == [NetworkPolicyAmendment(host: "example.com", action: .allow)])
		#expect(params.availableDecisions?.count == 3)
	}

	@Test func execCommandApprovalParamsRoundTripPreservesWireKeys() throws {
		let params = ExecCommandApprovalParams(
			conversationCodexId: "thread-1",
			callId: "call-1",
			approvalId: "approval-1",
			command: ["echo", "hi"],
			cwd: "/tmp",
			reason: "Need approval",
			parsedCommand: [.read(cmd: "cat README.md", name: "README.md", path: "/tmp/README.md")]
		)

		let data = try JSONEncoder().encode(params)
		let object = try jsonObject(from: data)

		#expect(object["conversationId"] as? String == "thread-1")
		#expect(object["callId"] as? String == "call-1")
		#expect(object["parsedCmd"] is [Any])
		#expect(object["conversationCodexId"] == nil)
	}

	@Test func reviewDecisionEncodesStructuredAmendments() throws {
		let decision = ReviewDecision.networkPolicyAmendment(
			NetworkPolicyAmendment(host: "example.com", action: .allow)
		)

		let data = try JSONEncoder().encode(decision)
		let object = try jsonObject(from: data)
		let payload = object["network_policy_amendment"] as? [String: Any]
		let nested = payload?["network_policy_amendment"] as? [String: Any]

		#expect(nested?["host"] as? String == "example.com")
		#expect(nested?["action"] as? String == "allow")
	}

	@Test func commandExecutionApprovalDecisionRoundTripsStructuredCases() throws {
		let decision = try decode(
			CommandExecutionApprovalDecision.self,
			from: """
			{
			  "acceptWithExecpolicyAmendment": {
			    "execpolicy_amendment": ["rg", "TODO"]
			  }
			}
			"""
		)

		#expect(decision == .acceptWithExecPolicyAmendment(ExecPolicyAmendment(["rg", "TODO"])))

		let encoded = try JSONEncoder().encode(decision)
		let object = try jsonObject(from: encoded)
		let payload = object["acceptWithExecpolicyAmendment"] as? [String: Any]
		#expect(payload?["execpolicy_amendment"] is [Any])
	}

	@Test func serverRequestEnvelopeDecodesFullTypedExecApprovalPayload() throws {
		let payload = Data(
			"""
			{
			  "conversationId": "thread-1",
			  "callId": "call-1",
			  "approvalId": null,
			  "command": ["echo", "hi"],
			  "cwd": "/tmp",
			  "reason": null,
			  "parsedCmd": [
			    { "type": "unknown", "cmd": "echo hi" }
			  ]
			}
			""".utf8
		)

		let envelope = try ServerRequestEnvelope.decode(
			method: "execCommandApproval",
			id: .int(42),
			params: payload,
			decoder: JSONDecoder()
		)

		guard case let .execCommandApproval(params, id) = envelope else {
			Issue.record("Expected execCommandApproval envelope.")
			return
		}

		#expect(id == .int(42))
		#expect(params.conversationCodexId == "thread-1")
		#expect(params.parsedCommand == [.unknown(cmd: "echo hi")])
	}
}

private func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
	let data = Data(json.utf8)
	return try JSONDecoder().decode(T.self, from: data)
}

private func jsonObject(from data: Data) throws -> [String: Any] {
	guard let object = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) as? [String: Any] else {
		throw TestFailure(message: "Expected JSON object payload.")
	}
	return object
}
