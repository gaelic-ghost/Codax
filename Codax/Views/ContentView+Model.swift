//
//  ContentView+Model.swift
//  Codax
//
//  Created by Gale Williams on 3/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class ContentViewModel {
	var turnInput = ""
	var orchestrator: CodaxOrchestrator?

	func bind(to orchestrator: CodaxOrchestrator) {
		self.orchestrator = orchestrator
	}

	var compatibilityDescription: String {
		guard let orchestrator else { return "Compatibility unknown." }
		switch orchestrator.compatibility {
		case .unknown:
			return "Compatibility unknown."
		case .checking:
			return "Checking Codex CLI compatibility..."
		case let .supported(version, path):
			let location = path.map { " at \($0)" } ?? ""
			return "Compatible with Codex CLI \(version.displayString)\(location)."
		case let .unsupported(version, path, supportedRange, reason):
			let versionText = version?.displayString ?? "unknown version"
			let location = path.map { " at \($0)" } ?? ""
			return "Unsupported Codex CLI \(versionText)\(location). Expected \(supportedRange). \(reason)"
		}
	}

	var connectionLabel: String {
		switch orchestrator?.connectionState ?? .disconnected {
		case .disconnected:
			return "Disconnected"
		case .connecting:
			return "Connecting..."
		case .connected:
			return "Connected"
		}
	}

	var canConnect: Bool {
		guard let orchestrator else { return false }
		return orchestrator.connectionState == .disconnected
	}

	var activeThreadTitle: String {
		if let name = orchestrator?.activeThread?.name, !name.isEmpty {
			return name
		}
		if let preview = orchestrator?.activeThread?.preview, !preview.isEmpty {
			return preview
		}
		return "No active thread"
	}

	var activeThreadHasTurns: Bool {
		!(orchestrator?.activeThread?.turns.isEmpty ?? true)
	}

	var activeError: String? {
		orchestrator?.activeError
	}

	func connect() async {
		await orchestrator?.connect()
	}

	func startThread() async {
		await orchestrator?.startThread()
	}

	func startTurn() async {
		let input = turnInput
		await orchestrator?.startTurn(inputText: input)
		guard orchestrator?.activeError == nil else { return }
		turnInput = ""
	}
}
