//
//  DetailView+Model.swift
//  Codax
//
//  Created by Gale Williams on 3/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class DetailViewModel {
	var orchestrator: CodaxOrchestrator?

	func bind(to orchestrator: CodaxOrchestrator) {
		self.orchestrator = orchestrator
	}

	var compatibilityText: String {
		guard let orchestrator else { return "Compatibility unavailable." }
		switch orchestrator.compatibility {
		case .unknown:
			return "Compatibility unknown."
		case .checking:
			return "Checking compatibility..."
		case let .supported(version, _):
			return "Supported: \(version.displayString)"
		case let .unsupported(version, _, supportedRange, _):
			return "Unsupported: \(version?.displayString ?? "unknown") (expected \(supportedRange))"
		}
	}

	var threadMetadata: [String] {
		guard let thread = orchestrator?.activeThread else { return [] }
		return [
			"Thread ID: \(thread.id)",
			"Provider: \(thread.modelProvider)",
			"CWD: \(thread.cwd)",
			"CLI: \(thread.cliVersion)",
		]
	}

	var tokenUsageText: String? {
		guard let usage = orchestrator?.activeThreadTokenUsage else { return nil }
		return "Tokens: \(usage.total.totalTokens) total, \(usage.total.inputTokens) input, \(usage.total.outputTokens) output"
	}

	var planSteps: [TurnPlanStep] {
		orchestrator?.activeTurnPlan ?? []
	}

	var diffText: String? {
		orchestrator?.activeTurnDiff
	}

	var activeError: String? {
		orchestrator?.activeError
	}
}
