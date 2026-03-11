//
//  CodexClient+IdentitySupport.swift
//  Codax
//
//  Created by Codex on 3/10/26.
//

import Foundation

protocol CodexClientIdentifiable {
	var codexId: String { get }
	var id: UUID { get set }
}

extension CodexClientIdentifiable {
	mutating func assignIdentity(using makeID: (String) -> UUID) {
		id = makeID(codexId)
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
