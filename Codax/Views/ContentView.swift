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
	@State private var vm = ContentViewModel()

	var body: some View {
		@Bindable var bindableVM = vm

		SelectedThreadStoreView(selectedThreadCodexId: viewModel.selectedThreadCodexId) { thread in
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

				TextField("Start a turn", text: $bindableVM.turnInput, axis: .vertical)
					.textFieldStyle(.roundedBorder)

				Button("Send Turn") {
					Task {
						let input = bindableVM.turnInput
						await viewModel.startTurn(inputText: input)
						guard viewModel.errorState == nil else { return }
						bindableVM.turnInput = ""
					}
				}
				.disabled(thread == nil || bindableVM.turnInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

				if let error = viewModel.errorState {
					Text(error.message)
						.foregroundStyle(.red)
				}

				Spacer()
			}
			.padding()
			.navigationTitle("Session")
		}
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
	let container = try! CodaxPersistenceBridge.makeModelContainer(inMemory: true)
	ContentView()
		.environment(CodaxViewModel(modelContainer: container))
		.modelContainer(container)
}
