//
//  ContentView.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
	@Environment(CodaxViewModel.self) private var viewModel
	@State private var turnInput = ""

	var body: some View {
		SelectedThreadContent(
			selectedThreadCodexId: viewModel.selectedThreadCodexId,
			turnInput: $turnInput
		)
		.navigationTitle("Session")
	}
}

// MARK: - Selected Thread Content

private struct SelectedThreadContent: View {
	@Environment(CodaxViewModel.self) private var viewModel
	@Binding var turnInput: String
	@Query private var threads: [ThreadModel]

	init(
		selectedThreadCodexId: String?,
		turnInput: Binding<String>
	) {
		_turnInput = turnInput
		if let selectedThreadCodexId {
			_threads = Query(
				filter: #Predicate<ThreadModel> { thread in
					thread.codexId == selectedThreadCodexId
				}
			)
		} else {
			_threads = Query(
				filter: #Predicate<ThreadModel> { _ in
					false
				}
			)
		}
	}

	var body: some View {
		let thread = threads.first

		VStack(alignment: .leading, spacing: 16) {
			Text(connectionLabel)
				.font(.headline)

			Text(compatibilityDescription)
				.font(.subheadline)
				.foregroundStyle(.secondary)

			if let compatibilityDebugInfo = viewModel.compatibilityDebugInfo, !compatibilityDebugInfo.formattedDescription.isEmpty {
				Text(compatibilityDebugInfo.formattedDescription)
					.font(.caption.monospaced())
					.foregroundStyle(.secondary)
					.textSelection(.enabled)
			}

			HStack {
				Button("Connect") {
					Task {
						await viewModel.connect()
					}
				}
				.disabled(viewModel.connectionState != .disconnected)
			}

			Divider()

			Text(activeThreadTitle(thread: thread))
				.font(.title3)

			if !(thread?.turns.isEmpty ?? true) {
				Text("Turn history available in the active thread.")
					.foregroundStyle(.secondary)
			} else {
				Text("No turns started yet.")
					.foregroundStyle(.secondary)
			}

			TextField("Start a turn", text: $turnInput, axis: .vertical)
				.textFieldStyle(.roundedBorder)

			Button("Send Turn") {
				Task {
					let input = turnInput
					await viewModel.startTurn(inputText: input)
					guard viewModel.errorState == nil else { return }
					turnInput = ""
				}
			}
			.disabled(thread == nil || turnInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

			if let error = viewModel.errorState {
				Text(error.message)
					.foregroundStyle(.red)
			}

			Spacer()
		}
		.padding()
	}

	private var connectionLabel: String {
		switch viewModel.connectionState {
		case .disconnected:
			return "Disconnected"
		case .connecting:
			return "Connecting..."
		case .connected:
			return "Connected"
		}
	}

	private var compatibilityDescription: String {
		switch viewModel.compatibility {
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

	private func activeThreadTitle(thread: ThreadModel?) -> String {
		if let name = thread?.name, !name.isEmpty {
			return name
		}
		if let preview = thread?.preview, !preview.isEmpty {
			return preview
		}
		return "No active thread"
	}
}

#Preview {
	let container = try! makeCodaxModelContainer(inMemory: true)
	ContentView()
		.environment(CodaxViewModel(modelContainer: container))
		.modelContainer(container)
}
