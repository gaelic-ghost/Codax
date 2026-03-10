//
//  DetailView.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import SwiftUI

struct DetailView: View {
	@Environment(\.scenePhase) private var scenePhase
	@Environment(CodaxOrchestrator.self) private var orchestrator
	@State private var vm = DetailViewModel()

	var body: some View {
		List {
			Section("Compatibility") {
				Text(vm.compatibilityText)
			}

			Section("Thread") {
				if vm.threadMetadata.isEmpty {
					Text("No active thread")
						.foregroundStyle(.secondary)
				} else {
					ForEach(vm.threadMetadata, id: \.self) { row in
						Text(row)
					}
				}
			}

			if let tokenUsageText = vm.tokenUsageText {
				Section("Token Usage") {
					Text(tokenUsageText)
				}
			}

			if !vm.planSteps.isEmpty {
				Section("Plan") {
					ForEach(Array(vm.planSteps.enumerated()), id: \.offset) { entry in
						Text("\(entry.element.step) (\(entry.element.status.rawValue))")
					}
				}
			}

			if let diffText = vm.diffText, !diffText.isEmpty {
				Section("Diff") {
					Text(diffText)
						.textSelection(.enabled)
				}
			}

			if let activeError = vm.activeError {
				Section("Error") {
					Text(activeError)
						.foregroundStyle(.red)
				}
			}
		}
		.navigationTitle("Details")
		.task(id: ObjectIdentifier(orchestrator)) {
			vm.bind(to: orchestrator)
		}
	}
}

#Preview {
	DetailView()
		.environment(CodaxOrchestrator())
}
