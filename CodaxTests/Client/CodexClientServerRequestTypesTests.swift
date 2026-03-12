import Foundation
import Testing
@testable import Codax

struct ConnectionServerRequestSchemaTests {
	@Test func fileChangeApprovalParamsDecodeWithTypedIdentifiers() throws {
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

		#expect(params.threadId == "thread-1")
		#expect(params.turnId == "turn-1")
		#expect(params.itemId == "item-1")
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

		#expect(params.threadId == "thread-1")
		#expect(params.turnId == "turn-1")
		#expect(params.itemId == "item-1")
		#expect(params.commandActions?.count == 1)
		#expect(params.additionalPermissions?.network?.enabled == true)
		#expect(params.proposedExecpolicyAmendment == ExecPolicyAmendment(["curl", "https://example.com"]))
		#expect(params.proposedNetworkPolicyAmendments == [NetworkPolicyAmendment(host: "example.com", action: .allow)])
		#expect(params.availableDecisions?.count == 3)
	}

	@Test func execCommandApprovalParamsRoundTripPreservesWireKeys() throws {
		let params = ExecCommandApprovalParams(
			conversationId: "thread-1",
			callId: "call-1",
			approvalId: "approval-1",
			command: ["echo", "hi"],
			cwd: "/tmp",
			reason: "Need approval",
			parsedCmd: [.read(cmd: "cat README.md", name: "README.md", path: "/tmp/README.md")]
		)

		let data = try JSONEncoder().encode(params)
		let object = try jsonObject(from: data)

		#expect(object["conversationId"] as? String == "thread-1")
		#expect(object["callId"] as? String == "call-1")
		#expect(object["parsedCmd"] is [Any])
	}

	@Test func reviewDecisionEncodesStructuredAmendments() throws {
		let decision = ReviewDecision.networkPolicyAmendment([
			"host": .string("example.com"),
			"action": .string("allow"),
		])

		let data = try JSONEncoder().encode(decision)
		let object = try jsonObject(from: data)
		let payload = object["network_policy_amendment"] as? [String: Any]

		#expect(payload?["host"] as? String == "example.com")
		#expect(payload?["action"] as? String == "allow")
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

		#expect(
			decision == .acceptWithExecpolicyAmendment([
				"execpolicy_amendment": .array([.string("rg"), .string("TODO")]),
			])
		)

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
		#expect(params.conversationId == "thread-1")
		#expect(params.parsedCmd == [.unknown(cmd: "echo hi")])
	}

	@Test func mcpElicitationSchemaDecodesDollarSchemaField() throws {
		let schema = try decode(
			McpElicitationSchema.self,
			from: """
			{
			  "$schema": "https://example.com/elicitation.schema.json",
			  "type": "object",
			  "properties": {
			    "project": {
			      "type": "string",
			      "title": "Project",
			      "default": "Codax"
			    }
			  },
			  "required": ["project"]
			}
			"""
		)

		#expect(schema.schema == "https://example.com/elicitation.schema.json")
		#expect(schema.required == ["project"])
	}

	@Test func permissionsApprovalTypesDecodeAndRoundTrip() throws {
		let params = try decode(
			PermissionsRequestApprovalParams.self,
			from: """
			{
			  "threadId": "thread-1",
			  "turnId": "turn-1",
			  "itemId": "item-1",
			  "reason": "Need automation",
			  "permissions": {
			    "macos": {
			      "preferences": "read_only",
			      "automations": { "bundle_ids": ["com.apple.Terminal"] },
			      "accessibility": false,
			      "calendar": false
			    }
			  }
			}
			"""
		)

		#expect(params.reason == "Need automation")
		#expect(params.permissions.macos?.automations == .bundleIds(["com.apple.Terminal"]))

		let response = try decode(
			PermissionsRequestApprovalResponse.self,
			from: """
			{
			  "permissions": {
			    "macos": {
			      "automations": { "bundle_ids": ["com.apple.Terminal"] },
			      "accessibility": true
			    }
			  },
			  "scope": "session"
			}
			"""
		)

		#expect(response.permissions.macos?.automations == .bundleIds(["com.apple.Terminal"]))
		#expect(response.permissions.macos?.accessibility == true)
		#expect(response.scope == .session)
	}

	@Test func pluginAndCommandExecStreamingTypesDecode() throws {
		let pluginList = try decode(
			PluginListResponse.self,
			from: """
			{
			  "marketplaces": [
			    {
			      "name": "Official",
			      "path": "/tmp/marketplace",
			      "plugins": [
			        {
			          "id": "plugin-1",
			          "name": "Plugin One",
			          "installed": true,
			          "enabled": true,
			          "interface": {
			            "displayName": "Plugin One",
			            "shortDescription": "Short",
			            "longDescription": "Long",
			            "developerName": "OpenAI",
			            "category": "utilities",
			            "capabilities": ["tools"],
			            "websiteUrl": null,
			            "privacyPolicyUrl": null,
			            "termsOfServiceUrl": null,
			            "defaultPrompt": null,
			            "brandColor": null,
			            "composerIcon": null,
			            "logo": null,
			            "screenshots": []
			          },
			          "source": {
			            "type": "local",
			            "path": "/tmp/marketplace/plugin-one"
			          }
			        }
			      ]
			    }
			  ]
			}
			"""
		)
		#expect(pluginList.marketplaces.count == 1)
		#expect(pluginList.marketplaces.first?.plugins.first?.name == "Plugin One")

		let uninstall = try decode(
			PluginUninstallResponse.self,
			from: "{}"
		)
		_ = uninstall

		let writeResponse = try decode(CommandExecWriteResponse.self, from: "{}")
		let terminateResponse = try decode(CommandExecTerminateResponse.self, from: "{}")
		let resizeResponse = try decode(CommandExecResizeResponse.self, from: "{}")
		_ = writeResponse
		_ = terminateResponse
		_ = resizeResponse

		let outputDelta = try decode(
			CommandExecOutputDeltaNotification.self,
			from: """
			{
			  "processId": "process-1",
			  "stream": "stdout",
			  "deltaBase64": "aGVsbG8=",
			  "capReached": false
			}
			"""
		)
		#expect(outputDelta.processId == "process-1")
		#expect(outputDelta.stream == .stdout)
		#expect(outputDelta.capReached == false)
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
