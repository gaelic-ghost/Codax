//
//  PendingServerRequestModel.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import Foundation
import SwiftData

// MARK: - Pending Server Request Payload

enum PendingServerRequestPayload: Codable, Equatable, Sendable {
	case itemCommandExecutionRequestApproval(CommandExecutionRequestApprovalParams)
	case itemFileChangeRequestApproval(FileChangeRequestApprovalParams)
	case itemToolRequestUserInput(ToolRequestUserInputParams)
	case mcpServerElicitationRequest(McpServerElicitationRequestParams)
	case itemPermissionsRequestApproval(PermissionsRequestApprovalParams)
	case itemToolCall(DynamicToolCallParams)
	case accountChatgptAuthTokensRefresh(ChatgptAuthTokensRefreshParams)
	case applyPatchApproval(ApplyPatchApprovalParams)
	case execCommandApproval(ExecCommandApprovalParams)

	private enum CodingKeys: String, CodingKey {
		case kind
		case commandExecutionRequestApproval
		case fileChangeRequestApproval
		case toolRequestUserInput
		case mcpServerElicitationRequest
		case permissionsRequestApproval
		case toolCall
		case chatgptAuthTokensRefresh
		case applyPatchApproval
		case execCommandApproval
	}

	private enum Kind: String, Codable {
		case itemCommandExecutionRequestApproval
		case itemFileChangeRequestApproval
		case itemToolRequestUserInput
		case mcpServerElicitationRequest
		case itemPermissionsRequestApproval
		case itemToolCall
		case accountChatgptAuthTokensRefresh
		case applyPatchApproval
		case execCommandApproval
	}

	init(envelope: ServerRequestEnvelope) {
		switch envelope {
		case let .itemCommandExecutionRequestApproval(params, _):
			self = .itemCommandExecutionRequestApproval(params)
		case let .itemFileChangeRequestApproval(params, _):
			self = .itemFileChangeRequestApproval(params)
		case let .itemToolRequestUserInput(params, _):
			self = .itemToolRequestUserInput(params)
		case let .mcpServerElicitationRequest(params, _):
			self = .mcpServerElicitationRequest(params)
		case let .itemPermissionsRequestApproval(params, _):
			self = .itemPermissionsRequestApproval(params)
		case let .itemToolCall(params, _):
			self = .itemToolCall(params)
		case let .accountChatgptAuthTokensRefresh(params, _):
			self = .accountChatgptAuthTokensRefresh(params)
		case let .applyPatchApproval(params, _):
			self = .applyPatchApproval(params)
		case let .execCommandApproval(params, _):
			self = .execCommandApproval(params)
		}
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind = try container.decode(Kind.self, forKey: .kind)
		switch kind {
		case .itemCommandExecutionRequestApproval:
			self = .itemCommandExecutionRequestApproval(try container.decode(CommandExecutionRequestApprovalParams.self, forKey: .commandExecutionRequestApproval))
		case .itemFileChangeRequestApproval:
			self = .itemFileChangeRequestApproval(try container.decode(FileChangeRequestApprovalParams.self, forKey: .fileChangeRequestApproval))
		case .itemToolRequestUserInput:
			self = .itemToolRequestUserInput(try container.decode(ToolRequestUserInputParams.self, forKey: .toolRequestUserInput))
		case .mcpServerElicitationRequest:
			self = .mcpServerElicitationRequest(try container.decode(McpServerElicitationRequestParams.self, forKey: .mcpServerElicitationRequest))
		case .itemPermissionsRequestApproval:
			self = .itemPermissionsRequestApproval(try container.decode(PermissionsRequestApprovalParams.self, forKey: .permissionsRequestApproval))
		case .itemToolCall:
			self = .itemToolCall(try container.decode(DynamicToolCallParams.self, forKey: .toolCall))
		case .accountChatgptAuthTokensRefresh:
			self = .accountChatgptAuthTokensRefresh(try container.decode(ChatgptAuthTokensRefreshParams.self, forKey: .chatgptAuthTokensRefresh))
		case .applyPatchApproval:
			self = .applyPatchApproval(try container.decode(ApplyPatchApprovalParams.self, forKey: .applyPatchApproval))
		case .execCommandApproval:
			self = .execCommandApproval(try container.decode(ExecCommandApprovalParams.self, forKey: .execCommandApproval))
		}
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .itemCommandExecutionRequestApproval(params):
			try container.encode(Kind.itemCommandExecutionRequestApproval, forKey: .kind)
			try container.encode(params, forKey: .commandExecutionRequestApproval)
		case let .itemFileChangeRequestApproval(params):
			try container.encode(Kind.itemFileChangeRequestApproval, forKey: .kind)
			try container.encode(params, forKey: .fileChangeRequestApproval)
		case let .itemToolRequestUserInput(params):
			try container.encode(Kind.itemToolRequestUserInput, forKey: .kind)
			try container.encode(params, forKey: .toolRequestUserInput)
		case let .mcpServerElicitationRequest(params):
			try container.encode(Kind.mcpServerElicitationRequest, forKey: .kind)
			try container.encode(params, forKey: .mcpServerElicitationRequest)
		case let .itemPermissionsRequestApproval(params):
			try container.encode(Kind.itemPermissionsRequestApproval, forKey: .kind)
			try container.encode(params, forKey: .permissionsRequestApproval)
		case let .itemToolCall(params):
			try container.encode(Kind.itemToolCall, forKey: .kind)
			try container.encode(params, forKey: .toolCall)
		case let .accountChatgptAuthTokensRefresh(params):
			try container.encode(Kind.accountChatgptAuthTokensRefresh, forKey: .kind)
			try container.encode(params, forKey: .chatgptAuthTokensRefresh)
		case let .applyPatchApproval(params):
			try container.encode(Kind.applyPatchApproval, forKey: .kind)
			try container.encode(params, forKey: .applyPatchApproval)
		case let .execCommandApproval(params):
			try container.encode(Kind.execCommandApproval, forKey: .kind)
			try container.encode(params, forKey: .execCommandApproval)
		}
	}

	var threadCodexId: String? {
		switch self {
		case let .itemCommandExecutionRequestApproval(params):
			return params.threadId
		case let .itemFileChangeRequestApproval(params):
			return params.threadId
		case let .itemToolRequestUserInput(params):
			return params.threadId
		case let .mcpServerElicitationRequest(params):
			switch params {
			case let .form(threadId, _, _, _, _, _):
				return threadId
			case let .url(threadId, _, _, _, _, _, _):
				return threadId
			}
		case let .itemPermissionsRequestApproval(params):
			return params.threadId
		case let .itemToolCall(params):
			return params.threadId
		case .accountChatgptAuthTokensRefresh:
			return nil
		case let .applyPatchApproval(params):
			return params.conversationId
		case let .execCommandApproval(params):
			return params.conversationId
		}
	}

	var title: String {
		switch self {
		case .itemCommandExecutionRequestApproval:
			return "Command approval"
		case .itemFileChangeRequestApproval:
			return "File change approval"
		case .itemToolRequestUserInput:
			return "Tool input request"
		case .mcpServerElicitationRequest:
			return "MCP elicitation request"
		case .itemPermissionsRequestApproval:
			return "Permissions approval"
		case .itemToolCall:
			return "Tool call"
		case .accountChatgptAuthTokensRefresh:
			return "Refresh ChatGPT tokens"
		case .applyPatchApproval:
			return "Patch approval"
		case .execCommandApproval:
			return "Exec command approval"
		}
	}

	var summary: String {
		switch self {
		case let .itemCommandExecutionRequestApproval(params):
			return params.reason ?? params.command ?? "Command execution requires review."
		case let .itemFileChangeRequestApproval(params):
			return params.reason ?? params.grantRoot ?? "File changes require review."
		case let .itemToolRequestUserInput(params):
			return params.questions.first?.question ?? "Tool requires user input."
		case let .mcpServerElicitationRequest(params):
			switch params {
			case let .form(_, _, serverName, _, message, _):
				return "\(serverName): \(message)"
			case let .url(_, _, serverName, _, message, url, _):
				return "\(serverName): \(message) (\(url))"
			}
		case let .itemPermissionsRequestApproval(params):
			return params.reason ?? "Additional permissions require approval."
		case let .itemToolCall(params):
			return "\(params.tool) requested \(params.callId)"
		case let .accountChatgptAuthTokensRefresh(params):
			return "Reason: \(params.reason.rawValue)"
		case let .applyPatchApproval(params):
			return params.reason ?? "Patch application requires review."
		case let .execCommandApproval(params):
			return params.reason ?? params.command.joined(separator: " ")
		}
	}
}

// MARK: - Pending Server Request Record

struct PendingServerRequestRecord: Codable, Equatable, Sendable {
	var id: UUID
	var requestId: JSONRPCID
	var threadCodexId: String?
	var payload: PendingServerRequestPayload
	var createdAt: Date
	var updatedAt: Date

	init(
		id: UUID = UUID(),
		requestId: JSONRPCID,
		threadCodexId: String?,
		payload: PendingServerRequestPayload,
		createdAt: Date = .now,
		updatedAt: Date = .now
	) {
		self.id = id
		self.requestId = requestId
		self.threadCodexId = threadCodexId
		self.payload = payload
		self.createdAt = createdAt
		self.updatedAt = updatedAt
	}

	init(envelope: ServerRequestEnvelope) {
		let payload = PendingServerRequestPayload(envelope: envelope)
		self.init(
			requestId: envelope.id,
			threadCodexId: payload.threadCodexId,
			payload: payload
		)
	}

	init?(model: PendingServerRequestModel) {
		guard let requestId = model.requestId, let payload = model.payload else {
			return nil
		}
		self.init(
			id: model.id,
			requestId: requestId,
			threadCodexId: model.threadCodexId,
			payload: payload,
			createdAt: model.createdAt,
			updatedAt: model.updatedAt
		)
	}
}

// MARK: - Pending Server Request Model

@Model
final class PendingServerRequestModel {
	var id: UUID
	var requestIdData: Data
	var threadCodexId: String?
	var payloadData: Data
	var createdAt: Date
	var updatedAt: Date

	init(
		id: UUID = UUID(),
		requestIdData: Data,
		threadCodexId: String? = nil,
		payloadData: Data,
		createdAt: Date = .now,
		updatedAt: Date = .now
	) {
		self.id = id
		self.requestIdData = requestIdData
		self.threadCodexId = threadCodexId
		self.payloadData = payloadData
		self.createdAt = createdAt
		self.updatedAt = updatedAt
	}

	convenience init(record: PendingServerRequestRecord) {
		self.init(
			id: record.id,
			requestIdData: Self.encode(record.requestId) ?? Data(),
			threadCodexId: record.threadCodexId,
			payloadData: Self.encode(record.payload) ?? Data(),
			createdAt: record.createdAt,
			updatedAt: record.updatedAt
		)
	}

	var record: PendingServerRequestRecord? {
		guard let requestId = requestId, let payload = payload else { return nil }
		return PendingServerRequestRecord(
			id: id,
			requestId: requestId,
			threadCodexId: threadCodexId,
			payload: payload,
			createdAt: createdAt,
			updatedAt: updatedAt
		)
	}

	var requestId: JSONRPCID? {
		Self.decode(JSONRPCID.self, from: requestIdData)
	}

	var payload: PendingServerRequestPayload? {
		Self.decode(PendingServerRequestPayload.self, from: payloadData)
	}

	var title: String {
		payload?.title ?? "Pending request"
	}

	var summary: String {
		payload?.summary ?? "A request is waiting for attention."
	}

	func apply(_ record: PendingServerRequestRecord) {
		requestIdData = Self.encode(record.requestId) ?? Data()
		threadCodexId = record.threadCodexId
		payloadData = Self.encode(record.payload) ?? Data()
		createdAt = record.createdAt
		updatedAt = record.updatedAt
	}

	private static func encode<T: Encodable>(_ value: T) -> Data? {
		try? JSONEncoder().encode(value)
	}

	private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
		guard let data, !data.isEmpty else { return nil }
		return try? JSONDecoder().decode(T.self, from: data)
	}
}
