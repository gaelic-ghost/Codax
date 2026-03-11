//
//  CodexClient+ItemPayloads.swift
//  Codax
//
//  Created by Codex on 3/10/26.
//

import Foundation

public struct UserMessageItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexClientIdentifiable {
	public var id: UUID
	public var codexId: String
	public var content: [UserInput]

	private enum CodingKeys: String, CodingKey {
		case codexId = "id"
		case content
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		codexId = try container.decode(String.self, forKey: .codexId)
		id = ClientIdentity.userMessageItem(codexId)
		content = try container.decode([UserInput].self, forKey: .content)
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(codexId, forKey: .codexId)
		try container.encode(content, forKey: .content)
	}
}

public struct AgentMessageItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexClientIdentifiable {
	public var id: UUID
	public var codexId: String
	public var text: String
	public var phase: MessagePhase?

	private enum CodingKeys: String, CodingKey {
		case codexId = "id"
		case text
		case phase
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		codexId = try container.decode(String.self, forKey: .codexId)
		id = ClientIdentity.agentMessageItem(codexId)
		text = try container.decode(String.self, forKey: .text)
		phase = try container.decodeIfPresent(MessagePhase.self, forKey: .phase)
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(codexId, forKey: .codexId)
		try container.encode(text, forKey: .text)
		try container.encode(phase, forKey: .phase)
	}
}

public struct PlanItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexClientIdentifiable {
	public var id: UUID
	public var codexId: String
	public var text: String

	private enum CodingKeys: String, CodingKey {
		case codexId = "id"
		case text
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		codexId = try container.decode(String.self, forKey: .codexId)
		id = ClientIdentity.planItem(codexId)
		text = try container.decode(String.self, forKey: .text)
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(codexId, forKey: .codexId)
		try container.encode(text, forKey: .text)
	}
}

public struct ReasoningItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexClientIdentifiable {
	public var id: UUID
	public var codexId: String
	public var summary: [String]
	public var content: [String]

	private enum CodingKeys: String, CodingKey {
		case codexId = "id"
		case summary
		case content
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		codexId = try container.decode(String.self, forKey: .codexId)
		id = ClientIdentity.reasoningItem(codexId)
		summary = try container.decode([String].self, forKey: .summary)
		content = try container.decode([String].self, forKey: .content)
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(codexId, forKey: .codexId)
		try container.encode(summary, forKey: .summary)
		try container.encode(content, forKey: .content)
	}
}

public struct CommandExecutionItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexClientIdentifiable {
	public var id: UUID
	public var codexId: String
	public var command: String
	public var cwd: String
	public var processId: String?
	public var status: CommandExecutionStatus
	public var commandActions: [CommandAction]
	public var aggregatedOutput: String?
	public var exitCode: Int?
	public var durationMs: Int?

	private enum CodingKeys: String, CodingKey {
		case codexId = "id"
		case command
		case cwd
		case processId
		case status
		case commandActions
		case aggregatedOutput
		case exitCode
		case durationMs
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		codexId = try container.decode(String.self, forKey: .codexId)
		id = ClientIdentity.commandExecutionItem(codexId)
		command = try container.decode(String.self, forKey: .command)
		cwd = try container.decode(String.self, forKey: .cwd)
		processId = try container.decodeIfPresent(String.self, forKey: .processId)
		status = try container.decode(CommandExecutionStatus.self, forKey: .status)
		commandActions = try container.decode([CommandAction].self, forKey: .commandActions)
		aggregatedOutput = try container.decodeIfPresent(String.self, forKey: .aggregatedOutput)
		exitCode = try container.decodeIfPresent(Int.self, forKey: .exitCode)
		durationMs = try container.decodeIfPresent(Int.self, forKey: .durationMs)
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(codexId, forKey: .codexId)
		try container.encode(command, forKey: .command)
		try container.encode(cwd, forKey: .cwd)
		try container.encode(processId, forKey: .processId)
		try container.encode(status, forKey: .status)
		try container.encode(commandActions, forKey: .commandActions)
		try container.encode(aggregatedOutput, forKey: .aggregatedOutput)
		try container.encode(exitCode, forKey: .exitCode)
		try container.encode(durationMs, forKey: .durationMs)
	}
}

public struct FileUpdateChange: Sendable, Codable, Equatable, Hashable {
	public var path: String
	public var kind: PatchChangeKind
	public var diff: String
}

public struct FileChangeItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexClientIdentifiable {
	public var id: UUID
	public var codexId: String
	public var changes: [FileUpdateChange]
	public var status: PatchApplyStatus

	private enum CodingKeys: String, CodingKey {
		case codexId = "id"
		case changes
		case status
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		codexId = try container.decode(String.self, forKey: .codexId)
		id = ClientIdentity.fileChangeItem(codexId)
		changes = try container.decode([FileUpdateChange].self, forKey: .changes)
		status = try container.decode(PatchApplyStatus.self, forKey: .status)
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(codexId, forKey: .codexId)
		try container.encode(changes, forKey: .changes)
		try container.encode(status, forKey: .status)
	}
}

public struct McpToolCallResult: Sendable, Codable, Equatable, Hashable {
	public var content: [CodexValue]
	public var structuredContent: CodexValue?
}

public struct McpToolCallError: Sendable, Codable, Equatable, Hashable {
	public var message: String
}

public struct McpToolCallItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexClientIdentifiable {
	public var id: UUID
	public var codexId: String
	public var server: String
	public var tool: String
	public var status: McpToolCallStatus
	public var arguments: CodexValue
	public var result: McpToolCallResult?
	public var error: McpToolCallError?
	public var durationMs: Int?

	private enum CodingKeys: String, CodingKey {
		case codexId = "id"
		case server
		case tool
		case status
		case arguments
		case result
		case error
		case durationMs
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		codexId = try container.decode(String.self, forKey: .codexId)
		id = ClientIdentity.mcpToolCallItem(codexId)
		server = try container.decode(String.self, forKey: .server)
		tool = try container.decode(String.self, forKey: .tool)
		status = try container.decode(McpToolCallStatus.self, forKey: .status)
		arguments = try container.decode(CodexValue.self, forKey: .arguments)
		result = try container.decodeIfPresent(McpToolCallResult.self, forKey: .result)
		error = try container.decodeIfPresent(McpToolCallError.self, forKey: .error)
		durationMs = try container.decodeIfPresent(Int.self, forKey: .durationMs)
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(codexId, forKey: .codexId)
		try container.encode(server, forKey: .server)
		try container.encode(tool, forKey: .tool)
		try container.encode(status, forKey: .status)
		try container.encode(arguments, forKey: .arguments)
		try container.encode(result, forKey: .result)
		try container.encode(error, forKey: .error)
		try container.encode(durationMs, forKey: .durationMs)
	}
}

public struct DynamicToolCallItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexClientIdentifiable {
	public var id: UUID
	public var codexId: String
	public var tool: String
	public var arguments: CodexValue
	public var status: DynamicToolCallStatus
	public var contentItems: [DynamicToolCallOutputContentItem]?
	public var success: Bool?
	public var durationMs: Int?

	private enum CodingKeys: String, CodingKey {
		case codexId = "id"
		case tool
		case arguments
		case status
		case contentItems
		case success
		case durationMs
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		codexId = try container.decode(String.self, forKey: .codexId)
		id = ClientIdentity.dynamicToolCallItem(codexId)
		tool = try container.decode(String.self, forKey: .tool)
		arguments = try container.decode(CodexValue.self, forKey: .arguments)
		status = try container.decode(DynamicToolCallStatus.self, forKey: .status)
		contentItems = try container.decodeIfPresent([DynamicToolCallOutputContentItem].self, forKey: .contentItems)
		success = try container.decodeIfPresent(Bool.self, forKey: .success)
		durationMs = try container.decodeIfPresent(Int.self, forKey: .durationMs)
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(codexId, forKey: .codexId)
		try container.encode(tool, forKey: .tool)
		try container.encode(arguments, forKey: .arguments)
		try container.encode(status, forKey: .status)
		try container.encode(contentItems, forKey: .contentItems)
		try container.encode(success, forKey: .success)
		try container.encode(durationMs, forKey: .durationMs)
	}
}

public struct CollabAgentToolCallItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexClientIdentifiable {
	public var id: UUID
	public var codexId: String
	public var tool: CollabAgentTool
	public var status: CollabAgentToolCallStatus
	public var senderThreadCodexId: String
	public var receiverThreadCodexIds: [String]
	public var prompt: String?
	public var agentStates: [String: CollabAgentState]

	private enum CodingKeys: String, CodingKey {
		case codexId = "id"
		case tool
		case status
		case senderThreadCodexId = "senderThreadId"
		case receiverThreadCodexIds = "receiverThreadIds"
		case prompt
		case agentStates = "agentsStates"
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		codexId = try container.decode(String.self, forKey: .codexId)
		id = ClientIdentity.collabAgentToolCallItem(codexId)
		tool = try container.decode(CollabAgentTool.self, forKey: .tool)
		status = try container.decode(CollabAgentToolCallStatus.self, forKey: .status)
		senderThreadCodexId = try container.decode(String.self, forKey: .senderThreadCodexId)
		receiverThreadCodexIds = try container.decode([String].self, forKey: .receiverThreadCodexIds)
		prompt = try container.decodeIfPresent(String.self, forKey: .prompt)
		agentStates = try container.decode([String: CollabAgentState].self, forKey: .agentStates)
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(codexId, forKey: .codexId)
		try container.encode(tool, forKey: .tool)
		try container.encode(status, forKey: .status)
		try container.encode(senderThreadCodexId, forKey: .senderThreadCodexId)
		try container.encode(receiverThreadCodexIds, forKey: .receiverThreadCodexIds)
		try container.encode(prompt, forKey: .prompt)
		try container.encode(agentStates, forKey: .agentStates)
	}
}

public struct WebSearchItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexClientIdentifiable {
	public var id: UUID
	public var codexId: String
	public var query: String
	public var action: WebSearchAction?

	private enum CodingKeys: String, CodingKey {
		case codexId = "id"
		case query
		case action
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		codexId = try container.decode(String.self, forKey: .codexId)
		id = ClientIdentity.webSearchItem(codexId)
		query = try container.decode(String.self, forKey: .query)
		action = try container.decodeIfPresent(WebSearchAction.self, forKey: .action)
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(codexId, forKey: .codexId)
		try container.encode(query, forKey: .query)
		try container.encode(action, forKey: .action)
	}
}

public struct ImageViewItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexClientIdentifiable {
	public var id: UUID
	public var codexId: String
	public var path: String

	private enum CodingKeys: String, CodingKey {
		case codexId = "id"
		case path
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		codexId = try container.decode(String.self, forKey: .codexId)
		id = ClientIdentity.imageViewItem(codexId)
		path = try container.decode(String.self, forKey: .path)
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(codexId, forKey: .codexId)
		try container.encode(path, forKey: .path)
	}
}

public struct ImageGenerationItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexClientIdentifiable {
	public var id: UUID
	public var codexId: String
	public var status: String
	public var revisedPrompt: String?
	public var result: String

	private enum CodingKeys: String, CodingKey {
		case codexId = "id"
		case status
		case revisedPrompt
		case result
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		codexId = try container.decode(String.self, forKey: .codexId)
		id = ClientIdentity.imageGenerationItem(codexId)
		status = try container.decode(String.self, forKey: .status)
		revisedPrompt = try container.decodeIfPresent(String.self, forKey: .revisedPrompt)
		result = try container.decode(String.self, forKey: .result)
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(codexId, forKey: .codexId)
		try container.encode(status, forKey: .status)
		try container.encode(revisedPrompt, forKey: .revisedPrompt)
		try container.encode(result, forKey: .result)
	}
}

public struct ReviewModeItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexClientIdentifiable {
	public var id: UUID
	public var codexId: String
	public var review: String

	private enum CodingKeys: String, CodingKey {
		case codexId = "id"
		case review
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		codexId = try container.decode(String.self, forKey: .codexId)
		id = ClientIdentity.reviewModeItem(codexId)
		review = try container.decode(String.self, forKey: .review)
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(codexId, forKey: .codexId)
		try container.encode(review, forKey: .review)
	}
}

public struct ContextCompactionItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexClientIdentifiable {
	public var id: UUID
	public var codexId: String

	private enum CodingKeys: String, CodingKey {
		case codexId = "id"
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		codexId = try container.decode(String.self, forKey: .codexId)
		id = ClientIdentity.contextCompactionItem(codexId)
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(codexId, forKey: .codexId)
	}
}
