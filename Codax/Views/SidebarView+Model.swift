//
//  SidebarView+Model.swift
//  Codax
//
//  Created by Gale Williams on 3/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class SidebarViewModel {
	var orchestrator: CodaxOrchestrator?

	func bind(to orchestrator: CodaxOrchestrator) {
		self.orchestrator = orchestrator
	}

	var threads: [ThreadSummary] {
		orchestrator?.threads ?? []
	}

	var selectedThreadID: String? {
		orchestrator?.activeThread?.id
	}

	var compatibilityBannerText: String? {
		guard let orchestrator else { return nil }
		guard case let .unsupported(version, _, supportedRange, reason) = orchestrator.compatibility else {
			return nil
		}
		let versionText = version?.displayString ?? "unknown version"
		return "Unsupported CLI \(versionText). Expected \(supportedRange). \(reason)"
	}

	func startThread() async {
		await orchestrator?.startThread()
	}

	func selectThread(id: String) {
		orchestrator?.selectThread(id: id)
	}

	func displayTitle(for thread: ThreadSummary) -> String {
		if let name = thread.name, !name.isEmpty {
			return name
		}
		return thread.preview
	}
}
