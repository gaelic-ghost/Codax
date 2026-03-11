//
//  CodexClient+Item.swift
//  Codax
//
//  Created by Codex on 3/10/26.
//

import Foundation

// TODO: Organize this file

public enum MessagePhase: String, Sendable, Codable, Equatable, Hashable {
	case commentary
	case finalAnswer = "final_answer"
}

public enum CommandExecutionStatus: String, Sendable, Codable, Equatable, Hashable {
	case inProgress
	case completed
	case failed
	case declined
}

public enum PatchApplyStatus: String, Sendable, Codable, Equatable, Hashable {
	case inProgress
	case completed
	case failed
	case declined
}

public enum McpToolCallStatus: String, Sendable, Codable, Equatable, Hashable {
	case inProgress
	case completed
	case failed
}

public enum DynamicToolCallStatus: String, Sendable, Codable, Equatable, Hashable {
	case inProgress
	case completed
	case failed
}

public enum PatchChangeKind: Sendable, Codable, Equatable, Hashable {
	case add
	case delete
	case update(movePath: String?)

	private enum CodingKeys: String, CodingKey {
		case type
		case movePath = "move_path"
	}

	private enum Kind: String, Codable {
		case add
		case delete
		case update
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		switch try container.decode(Kind.self, forKey: .type) {
		case .add:
			self = .add
		case .delete:
			self = .delete
		case .update:
			self = .update(movePath: try container.decodeIfPresent(String.self, forKey: .movePath))
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case .add:
			try container.encode(Kind.add, forKey: .type)
		case .delete:
			try container.encode(Kind.delete, forKey: .type)
		case let .update(movePath):
			try container.encode(Kind.update, forKey: .type)
			try container.encode(movePath, forKey: .movePath)
		}
	}
}

public enum WebSearchAction: Sendable, Codable, Equatable, Hashable {
	case search(query: String?, queries: [String]?)
	case openPage(url: String?)
	case findInPage(url: String?, pattern: String?)
	case other

	private enum CodingKeys: String, CodingKey {
		case type
		case query
		case queries
		case url
		case pattern
	}

	private enum Kind: String, Codable {
		case search
		case openPage
		case findInPage
		case other
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		switch try container.decode(Kind.self, forKey: .type) {
		case .search:
			self = .search(
				query: try container.decodeIfPresent(String.self, forKey: .query),
				queries: try container.decodeIfPresent([String].self, forKey: .queries)
			)
		case .openPage:
			self = .openPage(url: try container.decodeIfPresent(String.self, forKey: .url))
		case .findInPage:
			self = .findInPage(
				url: try container.decodeIfPresent(String.self, forKey: .url),
				pattern: try container.decodeIfPresent(String.self, forKey: .pattern)
			)
		case .other:
			self = .other
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .search(query, queries):
			try container.encode(Kind.search, forKey: .type)
			try container.encode(query, forKey: .query)
			try container.encode(queries, forKey: .queries)
		case let .openPage(url):
			try container.encode(Kind.openPage, forKey: .type)
			try container.encode(url, forKey: .url)
		case let .findInPage(url, pattern):
			try container.encode(Kind.findInPage, forKey: .type)
			try container.encode(url, forKey: .url)
			try container.encode(pattern, forKey: .pattern)
		case .other:
			try container.encode(Kind.other, forKey: .type)
		}
	}
}

public enum CommandAction: Sendable, Codable, Equatable, Hashable {
	case read(command: String, name: String, path: String)
	case listFiles(command: String, path: String?)
	case search(command: String, query: String?, path: String?)
	case unknown(command: String)

	private enum CodingKeys: String, CodingKey {
		case type
		case command
		case name
		case path
		case query
	}

	private enum Kind: String, Codable {
		case read
		case listFiles
		case search
		case unknown
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		switch try container.decode(Kind.self, forKey: .type) {
		case .read:
			self = .read(
				command: try container.decode(String.self, forKey: .command),
				name: try container.decode(String.self, forKey: .name),
				path: try container.decode(String.self, forKey: .path)
			)
		case .listFiles:
			self = .listFiles(
				command: try container.decode(String.self, forKey: .command),
				path: try container.decodeIfPresent(String.self, forKey: .path)
			)
		case .search:
			self = .search(
				command: try container.decode(String.self, forKey: .command),
				query: try container.decodeIfPresent(String.self, forKey: .query),
				path: try container.decodeIfPresent(String.self, forKey: .path)
			)
		case .unknown:
			self = .unknown(command: try container.decode(String.self, forKey: .command))
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .read(command, name, path):
			try container.encode(Kind.read, forKey: .type)
			try container.encode(command, forKey: .command)
			try container.encode(name, forKey: .name)
			try container.encode(path, forKey: .path)
		case let .listFiles(command, path):
			try container.encode(Kind.listFiles, forKey: .type)
			try container.encode(command, forKey: .command)
			try container.encode(path, forKey: .path)
		case let .search(command, query, path):
			try container.encode(Kind.search, forKey: .type)
			try container.encode(command, forKey: .command)
			try container.encode(query, forKey: .query)
			try container.encode(path, forKey: .path)
		case let .unknown(command):
			try container.encode(Kind.unknown, forKey: .type)
			try container.encode(command, forKey: .command)
		}
	}
}

public enum CollabAgentStatus: String, Sendable, Codable, Equatable, Hashable {
	case pendingInit
	case running
	case completed
	case errored
	case shutdown
	case notFound
}

public struct CollabAgentState: Sendable, Codable, Equatable, Hashable {
	public var status: CollabAgentStatus
	public var message: String?
}

public enum CollabAgentTool: String, Sendable, Codable, Equatable, Hashable {
	case spawnAgent
	case sendInput
	case resumeAgent
	case wait
	case closeAgent
}

public enum CollabAgentToolCallStatus: String, Sendable, Codable, Equatable, Hashable {
	case inProgress
	case completed
	case failed
}

private protocol CodexItemIdentity {
	var codexId: String { get }
	var id: UUID { get set }
}

private extension CodexItemIdentity {
	mutating func assignIdentity(using makeID: (String) -> UUID) {
		id = makeID(codexId)
	}
}

public struct UserMessageItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexItemIdentity {
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

public struct AgentMessageItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexItemIdentity {
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

public struct PlanItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexItemIdentity {
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

public struct ReasoningItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexItemIdentity {
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

public struct CommandExecutionItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexItemIdentity {
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

public struct FileChangeItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexItemIdentity {
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

public struct McpToolCallItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexItemIdentity {
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

public struct DynamicToolCallItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexItemIdentity {
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

public struct CollabAgentToolCallItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexItemIdentity {
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

public struct WebSearchItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexItemIdentity {
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

public struct ImageViewItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexItemIdentity {
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

public struct ImageGenerationItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexItemIdentity {
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

public struct ReviewModeItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexItemIdentity {
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

public struct ContextCompactionItem: Identifiable, Sendable, Codable, Equatable, Hashable, CodexItemIdentity {
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

public enum ThreadItem: Sendable, Codable, Equatable, Hashable {
	case userMessage(UserMessageItem)
	case agentMessage(AgentMessageItem)
	case plan(PlanItem)
	case reasoning(ReasoningItem)
	case commandExecution(CommandExecutionItem)
	case fileChange(FileChangeItem)
	case mcpToolCall(McpToolCallItem)
	case dynamicToolCall(DynamicToolCallItem)
	case collabAgentToolCall(CollabAgentToolCallItem)
	case webSearch(WebSearchItem)
	case imageView(ImageViewItem)
	case imageGeneration(ImageGenerationItem)
	case enteredReviewMode(ReviewModeItem)
	case exitedReviewMode(ReviewModeItem)
	case contextCompaction(ContextCompactionItem)
	case unknown(raw: CodexValue)

	private enum CodingKeys: String, CodingKey {
		case type
	}

	private enum Kind: String, Codable {
		case userMessage
		case agentMessage
		case plan
		case reasoning
		case commandExecution
		case fileChange
		case mcpToolCall
		case dynamicToolCall
		case collabAgentToolCall
		case webSearch
		case imageView
		case imageGeneration
		case enteredReviewMode
		case exitedReviewMode
		case contextCompaction
	}

	public init(from decoder: any Decoder) throws {
		let fallback = try CodexValue(from: decoder)
		guard
			case let .object(object) = fallback,
			case let .string(type)? = object["type"],
			let kind = Kind(rawValue: type)
		else {
			self = .unknown(raw: fallback)
			return
		}

		switch kind {
		case .userMessage: self = .userMessage(try Self.decode(UserMessageItem.self, from: fallback))
		case .agentMessage: self = .agentMessage(try Self.decode(AgentMessageItem.self, from: fallback))
		case .plan: self = .plan(try Self.decode(PlanItem.self, from: fallback))
		case .reasoning: self = .reasoning(try Self.decode(ReasoningItem.self, from: fallback))
		case .commandExecution: self = .commandExecution(try Self.decode(CommandExecutionItem.self, from: fallback))
		case .fileChange: self = .fileChange(try Self.decode(FileChangeItem.self, from: fallback))
		case .mcpToolCall: self = .mcpToolCall(try Self.decode(McpToolCallItem.self, from: fallback))
		case .dynamicToolCall: self = .dynamicToolCall(try Self.decode(DynamicToolCallItem.self, from: fallback))
		case .collabAgentToolCall: self = .collabAgentToolCall(try Self.decode(CollabAgentToolCallItem.self, from: fallback))
		case .webSearch: self = .webSearch(try Self.decode(WebSearchItem.self, from: fallback))
		case .imageView: self = .imageView(try Self.decode(ImageViewItem.self, from: fallback))
		case .imageGeneration: self = .imageGeneration(try Self.decode(ImageGenerationItem.self, from: fallback))
		case .enteredReviewMode: self = .enteredReviewMode(try Self.decode(ReviewModeItem.self, from: fallback))
		case .exitedReviewMode: self = .exitedReviewMode(try Self.decode(ReviewModeItem.self, from: fallback))
		case .contextCompaction: self = .contextCompaction(try Self.decode(ContextCompactionItem.self, from: fallback))
		}
	}

	public func encode(to encoder: any Encoder) throws {
		switch self {
		case let .userMessage(item): try item.encode(to: encoder)
		case let .agentMessage(item): try item.encode(to: encoder)
		case let .plan(item): try item.encode(to: encoder)
		case let .reasoning(item): try item.encode(to: encoder)
		case let .commandExecution(item): try item.encode(to: encoder)
		case let .fileChange(item): try item.encode(to: encoder)
		case let .mcpToolCall(item): try item.encode(to: encoder)
		case let .dynamicToolCall(item): try item.encode(to: encoder)
		case let .collabAgentToolCall(item): try item.encode(to: encoder)
		case let .webSearch(item): try item.encode(to: encoder)
		case let .imageView(item): try item.encode(to: encoder)
		case let .imageGeneration(item): try item.encode(to: encoder)
		case let .enteredReviewMode(item): try item.encode(to: encoder)
		case let .exitedReviewMode(item): try item.encode(to: encoder)
		case let .contextCompaction(item): try item.encode(to: encoder)
		case let .unknown(raw): try raw.encode(to: encoder)
		}
	}

	private static func decode<T: Decodable>(_ type: T.Type, from value: CodexValue) throws -> T {
		let data = try JSONEncoder().encode(value)
		return try JSONDecoder().decode(T.self, from: data)
	}
}

public struct ItemStartedNotification: Sendable, Codable, Equatable {
	public var item: ThreadItem
	public var threadCodexId: String
	public var turnCodexId: String

	private enum CodingKeys: String, CodingKey {
		case item
		case threadCodexId = "threadId"
		case turnCodexId = "turnId"
	}
}

public struct ItemCompletedNotification: Sendable, Codable, Equatable {
	public var item: ThreadItem
	public var threadCodexId: String
	public var turnCodexId: String

	private enum CodingKeys: String, CodingKey {
		case item
		case threadCodexId = "threadId"
		case turnCodexId = "turnId"
	}
}
