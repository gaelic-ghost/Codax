//
//  CodaxOrchestrator+Types.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

	// MARK: - Orchestration Layer Types

public enum CodaxCompatibilityState: Sendable, Equatable {
	case unknown
	case checking
	case supported(version: CodexCLIVersion, path: String?)
	case unsupported(version: CodexCLIVersion?, path: String?, supportedRange: String, reason: String)

	init(_ compatibility: CodexCLICompatibility) {
		switch compatibility {
			case .unknown:
				self = .unknown
			case .checking:
				self = .checking
			case let .supported(version, path):
				self = .supported(version: version, path: path)
			case let .unsupported(version, path, supportedRange, reason):
				self = .unsupported(
					version: version,
					path: path,
					supportedRange: supportedRange,
					reason: reason
				)
		}
	}
}

struct CodaxOrchestratorError: Equatable {
	let message: String
}

struct CodaxCompatibilityDebugInfo: Equatable {
	let formattedDescription: String
}

struct CodaxThreadSessionState {
	private(set) var order: [String] = []
	private(set) var threadsByCodexId: [String: Thread] = [:]
	private(set) var tokenUsageByThreadCodexId: [String: ThreadTokenUsage] = [:]
	private(set) var turnPlanByThreadCodexId: [String: [TurnPlanStep]] = [:]
	private(set) var turnDiffByThreadCodexId: [String: String] = [:]
	var selectedThreadCodexId: String?

	var threads: [Thread] {
		order.compactMap { threadsByCodexId[$0] }
	}

	var selectedThread: Thread? {
		guard let selectedThreadCodexId else { return nil }
		return threadsByCodexId[selectedThreadCodexId]
	}

	var selectedTokenUsage: ThreadTokenUsage? {
		guard let selectedThreadCodexId else { return nil }
		return tokenUsageByThreadCodexId[selectedThreadCodexId]
	}

	var selectedTurnPlan: [TurnPlanStep] {
		guard let selectedThreadCodexId else { return [] }
		return turnPlanByThreadCodexId[selectedThreadCodexId] ?? []
	}

	var selectedTurnDiff: String? {
		guard let selectedThreadCodexId else { return nil }
		return turnDiffByThreadCodexId[selectedThreadCodexId]
	}

	mutating func replaceThreads(_ threads: [Thread]) {
		order = threads.map(\.codexId)
		threadsByCodexId = Dictionary(uniqueKeysWithValues: threads.map { ($0.codexId, $0) })
	}

	mutating func setSelectedThread(_ thread: Thread?) {
		guard let thread else { return }
		upsert(thread)
		selectedThreadCodexId = thread.codexId
	}

	mutating func selectThread(codexId: String) {
		selectedThreadCodexId = codexId
	}

	mutating func upsert(_ thread: Thread) {
		if !order.contains(thread.codexId) {
			order.append(thread.codexId)
		}
		threadsByCodexId[thread.codexId] = thread
	}

	mutating func updateThread(codexId: String, mutation: (inout Thread) -> Void) {
		guard var thread = threadsByCodexId[codexId] else { return }
		mutation(&thread)
		threadsByCodexId[codexId] = thread
		if !order.contains(codexId) {
			order.append(codexId)
		}
	}

	mutating func merge(turn: Turn, into threadCodexId: String) {
		updateThread(codexId: threadCodexId) { thread in
			if let index = thread.turns.firstIndex(where: { $0.codexId == turn.codexId }) {
				thread.turns[index] = turn
			} else {
				thread.turns.append(turn)
			}
		}
	}

	mutating func merge(turnError: TurnError, into threadCodexId: String, turnCodexId: String) {
		updateThread(codexId: threadCodexId) { thread in
			guard let index = thread.turns.firstIndex(where: { $0.codexId == turnCodexId }) else { return }
			thread.turns[index].error = turnError
		}
	}

	mutating func setTokenUsage(_ tokenUsage: ThreadTokenUsage?, for threadCodexId: String) {
		tokenUsageByThreadCodexId[threadCodexId] = tokenUsage
	}

	mutating func setTurnPlan(_ plan: [TurnPlanStep], for threadCodexId: String) {
		turnPlanByThreadCodexId[threadCodexId] = plan
	}

	mutating func setTurnDiff(_ diff: String?, for threadCodexId: String) {
		turnDiffByThreadCodexId[threadCodexId] = diff
	}

	mutating func clearSelectedTransientState() {
		guard let selectedThreadCodexId else { return }
		tokenUsageByThreadCodexId[selectedThreadCodexId] = nil
		turnPlanByThreadCodexId[selectedThreadCodexId] = []
		turnDiffByThreadCodexId[selectedThreadCodexId] = nil
	}
}
