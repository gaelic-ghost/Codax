//
//  CodexClient+ModelSupport.swift
//  Codax
//
//  Created by Codex on 3/10/26.
//

import Foundation

public indirect enum CodexValue: Sendable, Codable, Equatable, Hashable {
	case null
	case bool(Bool)
	case number(Double)
	case string(String)
	case array([CodexValue])
	case object([String: CodexValue])

	public init(from decoder: any Decoder) throws {
		let container = try decoder.singleValueContainer()
		if container.decodeNil() {
			self = .null
		} else if let bool = try? container.decode(Bool.self) {
			self = .bool(bool)
		} else if let number = try? container.decode(Double.self) {
			self = .number(number)
		} else if let string = try? container.decode(String.self) {
			self = .string(string)
		} else if let array = try? container.decode([CodexValue].self) {
			self = .array(array)
		} else if let object = try? container.decode([String: CodexValue].self) {
			self = .object(object)
		} else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported CodexValue payload.")
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.singleValueContainer()
		switch self {
		case .null:
			try container.encodeNil()
		case let .bool(value):
			try container.encode(value)
		case let .number(value):
			try container.encode(value)
		case let .string(value):
			try container.encode(value)
		case let .array(value):
			try container.encode(value)
		case let .object(value):
			try container.encode(value)
		}
	}
}

private enum ClientIdentityKind: String {
	case thread
	case turn
	case userMessageItem
	case agentMessageItem
	case planItem
	case reasoningItem
	case commandExecutionItem
	case fileChangeItem
	case mcpToolCallItem
	case dynamicToolCallItem
	case collabAgentToolCallItem
	case webSearchItem
	case imageViewItem
	case imageGenerationItem
	case reviewModeItem
	case contextCompactionItem
}

private enum ClientIdentityRegistry {
	private static var storage: [String: UUID] = [:]
	private static let lock = NSLock()

	static func id(for kind: ClientIdentityKind, codexId: String) -> UUID {
		let key = "\(kind.rawValue):\(codexId)"
		lock.lock()
		defer { lock.unlock() }
		if let existing = storage[key] {
			return existing
		}
		let created = UUID()
		storage[key] = created
		return created
	}
}

enum ClientIdentity {
	static func thread(_ codexId: String) -> UUID { ClientIdentityRegistry.id(for: .thread, codexId: codexId) }
	static func turn(_ codexId: String) -> UUID { ClientIdentityRegistry.id(for: .turn, codexId: codexId) }
	static func userMessageItem(_ codexId: String) -> UUID { ClientIdentityRegistry.id(for: .userMessageItem, codexId: codexId) }
	static func agentMessageItem(_ codexId: String) -> UUID { ClientIdentityRegistry.id(for: .agentMessageItem, codexId: codexId) }
	static func planItem(_ codexId: String) -> UUID { ClientIdentityRegistry.id(for: .planItem, codexId: codexId) }
	static func reasoningItem(_ codexId: String) -> UUID { ClientIdentityRegistry.id(for: .reasoningItem, codexId: codexId) }
	static func commandExecutionItem(_ codexId: String) -> UUID { ClientIdentityRegistry.id(for: .commandExecutionItem, codexId: codexId) }
	static func fileChangeItem(_ codexId: String) -> UUID { ClientIdentityRegistry.id(for: .fileChangeItem, codexId: codexId) }
	static func mcpToolCallItem(_ codexId: String) -> UUID { ClientIdentityRegistry.id(for: .mcpToolCallItem, codexId: codexId) }
	static func dynamicToolCallItem(_ codexId: String) -> UUID { ClientIdentityRegistry.id(for: .dynamicToolCallItem, codexId: codexId) }
	static func collabAgentToolCallItem(_ codexId: String) -> UUID { ClientIdentityRegistry.id(for: .collabAgentToolCallItem, codexId: codexId) }
	static func webSearchItem(_ codexId: String) -> UUID { ClientIdentityRegistry.id(for: .webSearchItem, codexId: codexId) }
	static func imageViewItem(_ codexId: String) -> UUID { ClientIdentityRegistry.id(for: .imageViewItem, codexId: codexId) }
	static func imageGenerationItem(_ codexId: String) -> UUID { ClientIdentityRegistry.id(for: .imageGenerationItem, codexId: codexId) }
	static func reviewModeItem(_ codexId: String) -> UUID { ClientIdentityRegistry.id(for: .reviewModeItem, codexId: codexId) }
	static func contextCompactionItem(_ codexId: String) -> UUID { ClientIdentityRegistry.id(for: .contextCompactionItem, codexId: codexId) }
}

public enum ServiceTier: String, Sendable, Codable, Equatable, Hashable {
	case fast
	case flex
}

public enum ReasoningEffort: String, Sendable, Codable, Equatable, Hashable {
	case none
	case minimal
	case low
	case medium
	case high
	case xhigh
}

public enum Personality: String, Sendable, Codable, Equatable, Hashable {
	case none
	case friendly
	case pragmatic
}

public enum CollaborationModeKind: String, Sendable, Codable, Equatable, Hashable {
	case plan
	case `default`
}

public struct CollaborationModeSettings: Sendable, Codable, Equatable, Hashable {
	public var model: String
	public var reasoningEffort: ReasoningEffort?
	public var developerInstructions: String?

	private enum CodingKeys: String, CodingKey {
		case model
		case reasoningEffort = "reasoning_effort"
		case developerInstructions = "developer_instructions"
	}
}

public struct CollaborationMode: Sendable, Codable, Equatable, Hashable {
	public var mode: CollaborationModeKind
	public var settings: CollaborationModeSettings
}

public enum AskForApproval: Sendable, Codable, Equatable, Hashable {
	case untrusted
	case onFailure
	case onRequest
	case reject(AskForApprovalReject)
	case never

	private enum CodingKeys: String, CodingKey {
		case reject
	}

	public init(from decoder: any Decoder) throws {
		if let container = try? decoder.singleValueContainer(), let value = try? container.decode(String.self) {
			switch value {
			case "untrusted": self = .untrusted
			case "on-failure": self = .onFailure
			case "on-request": self = .onRequest
			case "never": self = .never
			default:
				throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported AskForApproval value: \(value)")
			}
			return
		}

		let container = try decoder.container(keyedBy: CodingKeys.self)
		self = .reject(try container.decode(AskForApprovalReject.self, forKey: .reject))
	}

	public func encode(to encoder: any Encoder) throws {
		switch self {
		case .untrusted, .onFailure, .onRequest, .never:
			var container = encoder.singleValueContainer()
			switch self {
			case .untrusted: try container.encode("untrusted")
			case .onFailure: try container.encode("on-failure")
			case .onRequest: try container.encode("on-request")
			case .never: try container.encode("never")
			case .reject: break
			}
		case let .reject(value):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(value, forKey: .reject)
		}
	}
}

public struct AskForApprovalReject: Sendable, Codable, Equatable, Hashable {
	public var sandboxApproval: Bool
	public var rules: Bool
	public var mcpElicitations: Bool

	private enum CodingKeys: String, CodingKey {
		case sandboxApproval = "sandbox_approval"
		case rules
		case mcpElicitations = "mcp_elicitations"
	}
}

public enum SandboxMode: String, Sendable, Codable, Equatable, Hashable {
	case readOnly = "read-only"
	case workspaceWrite = "workspace-write"
	case dangerFullAccess = "danger-full-access"
}

public enum NetworkAccess: String, Sendable, Codable, Equatable, Hashable {
	case restricted
	case enabled
}

public enum ReadOnlyAccess: Sendable, Codable, Equatable, Hashable {
	case restricted(includePlatformDefaults: Bool, readableRoots: [String])
	case fullAccess

	private enum CodingKeys: String, CodingKey {
		case type
		case includePlatformDefaults
		case readableRoots
	}

	private enum Kind: String, Codable {
		case restricted
		case fullAccess
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		switch try container.decode(Kind.self, forKey: .type) {
		case .restricted:
			self = .restricted(
				includePlatformDefaults: try container.decode(Bool.self, forKey: .includePlatformDefaults),
				readableRoots: try container.decode([String].self, forKey: .readableRoots)
			)
		case .fullAccess:
			self = .fullAccess
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .restricted(includePlatformDefaults, readableRoots):
			try container.encode(Kind.restricted, forKey: .type)
			try container.encode(includePlatformDefaults, forKey: .includePlatformDefaults)
			try container.encode(readableRoots, forKey: .readableRoots)
		case .fullAccess:
			try container.encode(Kind.fullAccess, forKey: .type)
		}
	}
}

public enum SandboxPolicy: Sendable, Codable, Equatable, Hashable {
	case dangerFullAccess
	case readOnly(access: ReadOnlyAccess, networkAccess: Bool)
	case externalSandbox(networkAccess: NetworkAccess)
	case workspaceWrite(
		writableRoots: [String],
		readOnlyAccess: ReadOnlyAccess,
		networkAccess: Bool,
		excludeTmpdirEnvVar: Bool,
		excludeSlashTmp: Bool
	)

	private enum CodingKeys: String, CodingKey {
		case type
		case access
		case networkAccess
		case writableRoots
		case readOnlyAccess
		case excludeTmpdirEnvVar
		case excludeSlashTmp
	}

	private enum Kind: String, Codable {
		case dangerFullAccess
		case readOnly
		case externalSandbox
		case workspaceWrite
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		switch try container.decode(Kind.self, forKey: .type) {
		case .dangerFullAccess:
			self = .dangerFullAccess
		case .readOnly:
			self = .readOnly(
				access: try container.decode(ReadOnlyAccess.self, forKey: .access),
				networkAccess: try container.decode(Bool.self, forKey: .networkAccess)
			)
		case .externalSandbox:
			self = .externalSandbox(
				networkAccess: try container.decode(NetworkAccess.self, forKey: .networkAccess)
			)
		case .workspaceWrite:
			self = .workspaceWrite(
				writableRoots: try container.decode([String].self, forKey: .writableRoots),
				readOnlyAccess: try container.decode(ReadOnlyAccess.self, forKey: .readOnlyAccess),
				networkAccess: try container.decode(Bool.self, forKey: .networkAccess),
				excludeTmpdirEnvVar: try container.decode(Bool.self, forKey: .excludeTmpdirEnvVar),
				excludeSlashTmp: try container.decode(Bool.self, forKey: .excludeSlashTmp)
			)
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case .dangerFullAccess:
			try container.encode(Kind.dangerFullAccess, forKey: .type)
		case let .readOnly(access, networkAccess):
			try container.encode(Kind.readOnly, forKey: .type)
			try container.encode(access, forKey: .access)
			try container.encode(networkAccess, forKey: .networkAccess)
		case let .externalSandbox(networkAccess):
			try container.encode(Kind.externalSandbox, forKey: .type)
			try container.encode(networkAccess, forKey: .networkAccess)
		case let .workspaceWrite(writableRoots, readOnlyAccess, networkAccess, excludeTmpdirEnvVar, excludeSlashTmp):
			try container.encode(Kind.workspaceWrite, forKey: .type)
			try container.encode(writableRoots, forKey: .writableRoots)
			try container.encode(readOnlyAccess, forKey: .readOnlyAccess)
			try container.encode(networkAccess, forKey: .networkAccess)
			try container.encode(excludeTmpdirEnvVar, forKey: .excludeTmpdirEnvVar)
			try container.encode(excludeSlashTmp, forKey: .excludeSlashTmp)
		}
	}
}

public struct ByteRange: Sendable, Codable, Equatable, Hashable {
	public var start: Int
	public var end: Int
}

public struct TextElement: Sendable, Codable, Equatable, Hashable {
	public var byteRange: ByteRange
	public var placeholder: String?
}

public enum UserInput: Sendable, Codable, Equatable, Hashable {
	case text(text: String, textElements: [TextElement])
	case image(url: String)
	case localImage(path: String)
	case skill(name: String, path: String)
	case mention(name: String, path: String)

	private enum CodingKeys: String, CodingKey {
		case type
		case text
		case textElements = "text_elements"
		case url
		case path
		case name
	}

	private enum Kind: String, Codable {
		case text
		case image
		case localImage
		case skill
		case mention
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		switch try container.decode(Kind.self, forKey: .type) {
		case .text:
			self = .text(
				text: try container.decode(String.self, forKey: .text),
				textElements: try container.decode([TextElement].self, forKey: .textElements)
			)
		case .image:
			self = .image(url: try container.decode(String.self, forKey: .url))
		case .localImage:
			self = .localImage(path: try container.decode(String.self, forKey: .path))
		case .skill:
			self = .skill(
				name: try container.decode(String.self, forKey: .name),
				path: try container.decode(String.self, forKey: .path)
			)
		case .mention:
			self = .mention(
				name: try container.decode(String.self, forKey: .name),
				path: try container.decode(String.self, forKey: .path)
			)
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .text(text, textElements):
			try container.encode(Kind.text, forKey: .type)
			try container.encode(text, forKey: .text)
			try container.encode(textElements, forKey: .textElements)
		case let .image(url):
			try container.encode(Kind.image, forKey: .type)
			try container.encode(url, forKey: .url)
		case let .localImage(path):
			try container.encode(Kind.localImage, forKey: .type)
			try container.encode(path, forKey: .path)
		case let .skill(name, path):
			try container.encode(Kind.skill, forKey: .type)
			try container.encode(name, forKey: .name)
			try container.encode(path, forKey: .path)
		case let .mention(name, path):
			try container.encode(Kind.mention, forKey: .type)
			try container.encode(name, forKey: .name)
			try container.encode(path, forKey: .path)
		}
	}
}

public enum DynamicToolCallOutputContentItem: Sendable, Codable, Equatable, Hashable {
	case inputText(text: String)
	case inputImage(imageUrl: String)

	private enum CodingKeys: String, CodingKey {
		case type
		case text
		case imageUrl
	}

	private enum Kind: String, Codable {
		case inputText
		case inputImage
	}

	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		switch try container.decode(Kind.self, forKey: .type) {
		case .inputText:
			self = .inputText(text: try container.decode(String.self, forKey: .text))
		case .inputImage:
			self = .inputImage(imageUrl: try container.decode(String.self, forKey: .imageUrl))
		}
	}

	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .inputText(text):
			try container.encode(Kind.inputText, forKey: .type)
			try container.encode(text, forKey: .text)
		case let .inputImage(imageUrl):
			try container.encode(Kind.inputImage, forKey: .type)
			try container.encode(imageUrl, forKey: .imageUrl)
		}
	}
}

public enum CodexErrorInfo: Sendable, Codable, Equatable, Hashable {
	case contextWindowExceeded
	case usageLimitExceeded
	case serverOverloaded
	case httpConnectionFailed(httpStatusCode: Int?)
	case responseStreamConnectionFailed(httpStatusCode: Int?)
	case internalServerError
	case unauthorized
	case badRequest
	case threadRollbackFailed
	case sandboxError
	case responseStreamDisconnected(httpStatusCode: Int?)
	case responseTooManyFailedAttempts(httpStatusCode: Int?)
	case other

	private enum CodingKeys: String, CodingKey {
		case httpConnectionFailed
		case responseStreamConnectionFailed
		case responseStreamDisconnected
		case responseTooManyFailedAttempts
		case httpStatusCode
	}

	public init(from decoder: any Decoder) throws {
		if let container = try? decoder.singleValueContainer(), let value = try? container.decode(String.self) {
			switch value {
			case "contextWindowExceeded": self = .contextWindowExceeded
			case "usageLimitExceeded": self = .usageLimitExceeded
			case "serverOverloaded": self = .serverOverloaded
			case "internalServerError": self = .internalServerError
			case "unauthorized": self = .unauthorized
			case "badRequest": self = .badRequest
			case "threadRollbackFailed": self = .threadRollbackFailed
			case "sandboxError": self = .sandboxError
			case "other": self = .other
			default:
				throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported CodexErrorInfo value: \(value)")
			}
			return
		}

		let container = try decoder.container(keyedBy: CodingKeys.self)
		if container.contains(.httpConnectionFailed) {
			let nested = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .httpConnectionFailed)
			self = .httpConnectionFailed(httpStatusCode: try nested.decodeIfPresent(Int.self, forKey: .httpStatusCode))
		} else if container.contains(.responseStreamConnectionFailed) {
			let nested = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .responseStreamConnectionFailed)
			self = .responseStreamConnectionFailed(httpStatusCode: try nested.decodeIfPresent(Int.self, forKey: .httpStatusCode))
		} else if container.contains(.responseStreamDisconnected) {
			let nested = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .responseStreamDisconnected)
			self = .responseStreamDisconnected(httpStatusCode: try nested.decodeIfPresent(Int.self, forKey: .httpStatusCode))
		} else if container.contains(.responseTooManyFailedAttempts) {
			let nested = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .responseTooManyFailedAttempts)
			self = .responseTooManyFailedAttempts(httpStatusCode: try nested.decodeIfPresent(Int.self, forKey: .httpStatusCode))
		} else {
			throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unsupported CodexErrorInfo payload."))
		}
	}

	public func encode(to encoder: any Encoder) throws {
		switch self {
		case .contextWindowExceeded, .usageLimitExceeded, .serverOverloaded, .internalServerError, .unauthorized, .badRequest, .threadRollbackFailed, .sandboxError, .other:
			var container = encoder.singleValueContainer()
			switch self {
			case .contextWindowExceeded: try container.encode("contextWindowExceeded")
			case .usageLimitExceeded: try container.encode("usageLimitExceeded")
			case .serverOverloaded: try container.encode("serverOverloaded")
			case .internalServerError: try container.encode("internalServerError")
			case .unauthorized: try container.encode("unauthorized")
			case .badRequest: try container.encode("badRequest")
			case .threadRollbackFailed: try container.encode("threadRollbackFailed")
			case .sandboxError: try container.encode("sandboxError")
			case .other: try container.encode("other")
			default: break
			}
		case let .httpConnectionFailed(httpStatusCode):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(["httpStatusCode": httpStatusCode], forKey: .httpConnectionFailed)
		case let .responseStreamConnectionFailed(httpStatusCode):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(["httpStatusCode": httpStatusCode], forKey: .responseStreamConnectionFailed)
		case let .responseStreamDisconnected(httpStatusCode):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(["httpStatusCode": httpStatusCode], forKey: .responseStreamDisconnected)
		case let .responseTooManyFailedAttempts(httpStatusCode):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(["httpStatusCode": httpStatusCode], forKey: .responseTooManyFailedAttempts)
		}
	}
}

public enum SubAgentSource: Sendable, Codable, Equatable, Hashable {
	case review
	case compact
	case threadSpawn(parentThreadCodexId: String, depth: Int, agentNickname: String?, agentRole: String?)
	case memoryConsolidation
	case other(String)

	private enum CodingKeys: String, CodingKey {
		case threadSpawn = "thread_spawn"
		case parentThreadCodexId = "parent_thread_id"
		case depth
		case agentNickname = "agent_nickname"
		case agentRole = "agent_role"
		case other
	}

	public init(from decoder: any Decoder) throws {
		if let container = try? decoder.singleValueContainer(), let value = try? container.decode(String.self) {
			switch value {
			case "review": self = .review
			case "compact": self = .compact
			case "memory_consolidation": self = .memoryConsolidation
			default:
				throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported SubAgentSource value: \(value)")
			}
			return
		}

		let container = try decoder.container(keyedBy: CodingKeys.self)
		if container.contains(.threadSpawn) {
			let nested = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .threadSpawn)
			self = .threadSpawn(
				parentThreadCodexId: try nested.decode(String.self, forKey: .parentThreadCodexId),
				depth: try nested.decode(Int.self, forKey: .depth),
				agentNickname: try nested.decodeIfPresent(String.self, forKey: .agentNickname),
				agentRole: try nested.decodeIfPresent(String.self, forKey: .agentRole)
			)
		} else if container.contains(.other) {
			self = .other(try container.decode(String.self, forKey: .other))
		} else {
			throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unsupported SubAgentSource payload."))
		}
	}

	public func encode(to encoder: any Encoder) throws {
		switch self {
		case .review:
			var container = encoder.singleValueContainer()
			try container.encode("review")
		case .compact:
			var container = encoder.singleValueContainer()
			try container.encode("compact")
		case .memoryConsolidation:
			var container = encoder.singleValueContainer()
			try container.encode("memory_consolidation")
		case let .threadSpawn(parentThreadCodexId, depth, agentNickname, agentRole):
			var container = encoder.container(keyedBy: CodingKeys.self)
			var nested = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .threadSpawn)
			try nested.encode(parentThreadCodexId, forKey: .parentThreadCodexId)
			try nested.encode(depth, forKey: .depth)
			try nested.encodeIfPresent(agentNickname, forKey: .agentNickname)
			try nested.encodeIfPresent(agentRole, forKey: .agentRole)
		case let .other(value):
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(value, forKey: .other)
		}
	}
}
