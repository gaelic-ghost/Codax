//
//  ContentView.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import SwiftUI

struct ContentView: View {
	@Environment(CodaxOrchestrator.self) private var orchestrator
	@State private var vm = ContentViewModel()

	var body: some View {
		@Bindable var bindableVM = vm

		VStack(alignment: .leading, spacing: 16) {
			Text(vm.connectionLabel)
				.font(.headline)

			Text(vm.compatibilityDescription)
				.font(.subheadline)
				.foregroundStyle(.secondary)

			HStack {
				Button("Connect") {
					Task {
						await vm.connect()
					}
				}
				.disabled(!vm.canConnect)

				Button("Start Thread") {
					Task {
						await vm.startThread()
					}
				}
				.disabled(orchestrator.connectionState != .connected)
			}

			Divider()

			Text(vm.activeThreadTitle)
				.font(.title3)

			if vm.activeThreadHasTurns {
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
					await vm.startTurn()
				}
			}
			.disabled(orchestrator.activeThread == nil || bindableVM.turnInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

			if let error = vm.activeError {
				Text(error)
					.foregroundStyle(.red)
			}

			Spacer()
		}
		.padding()
		.navigationTitle("Session")
		.task(id: ObjectIdentifier(orchestrator)) {
			vm.bind(to: orchestrator)
		}
	}
}

#Preview {
	ContentView()
		.environment(CodaxOrchestrator())
}
