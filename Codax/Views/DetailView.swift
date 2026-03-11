//
//  DetailView.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import SwiftUI

struct DetailView: View {
	@Environment(CodaxViewModel.self) private var viewModel

	var body: some View {
		List {
			Section("Compatibility") {
				Text(compatibilityText)
			}

			Section("Thread") {
				if threadMetadata.isEmpty {
					Text("No active thread")
						.foregroundStyle(.secondary)
				} else {
					ForEach(threadMetadata, id: \.self) { row in
						Text(row)
					}
				}
			}

			if let tokenUsageText = tokenUsageText {
				Section("Token Usage") {
					Text(tokenUsageText)
				}
			}

			if !viewModel.activeTurnPlan.isEmpty {
				Section("Plan") {
					ForEach(Array(viewModel.activeTurnPlan.enumerated()), id: \.offset) { entry in
						Text("\(entry.element.step) (\(entry.element.status.rawValue))")
					}
				}
			}

			if let diffText = viewModel.activeTurnDiff, !diffText.isEmpty {
				Section("Diff") {
					Text(diffText)
						.textSelection(.enabled)
				}
			}

			if let activeError = viewModel.errorState {
				Section("Error") {
					Text(activeError.message)
						.foregroundStyle(.red)
				}
			}

			if !viewModel.pendingUserRequests.isEmpty {
				Section("Pending Requests") {
					ForEach(viewModel.pendingUserRequests) { request in
						VStack(alignment: .leading, spacing: 4) {
							Text(request.title)
							Text(request.summary)
								.font(.caption)
								.foregroundStyle(.secondary)
						}
					}
				}
			}
		}
		.navigationTitle("Details")
	}

	private var compatibilityText: String {
		switch viewModel.compatibility {
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

	private var threadMetadata: [String] {
		guard let thread = viewModel.activeThread else { return [] }
		return [
			"Thread ID: \(thread.id)",
			"Provider: \(thread.modelProvider)",
			"CWD: \(thread.cwd)",
			"CLI: \(thread.cliVersion)",
		]
	}

	private var tokenUsageText: String? {
		guard let usage = viewModel.activeThreadTokenUsage else { return nil }
		return "Tokens: \(usage.total.totalTokens) total, \(usage.total.inputTokens) input, \(usage.total.outputTokens) output"
	}
}

#Preview {
	DetailView()
		.environment(CodaxViewModel())
}
