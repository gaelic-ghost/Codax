//
//  SidebarView.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import SwiftUI

struct SidebarView: View {
	@Environment(CodaxOrchestrator.self) private var orchestrator
	@State private var vm = SidebarViewModel()

	var body: some View {
		List(selection: selectionBinding) {
			if let banner = vm.compatibilityBannerText {
				Section("Compatibility") {
					Text(banner)
						.font(.caption)
				}
			}

			Section("Threads") {
				if vm.threads.isEmpty {
					Text("No threads yet")
						.foregroundStyle(.secondary)
				} else {
					ForEach(vm.threads, id: \.id) { thread in
						Button(vm.displayTitle(for: thread)) {
							vm.selectThread(id: thread.id)
						}
						.buttonStyle(.plain)
					}
				}
			}
		}
		.navigationTitle("Threads")
		.toolbar {
			Button("New Thread") {
				Task {
					await vm.startThread()
				}
			}
		}
		.task(id: ObjectIdentifier(orchestrator)) {
			vm.bind(to: orchestrator)
		}
	}

	private var selectionBinding: Binding<String?> {
		Binding(
			get: { vm.selectedThreadID },
			set: { newValue in
				guard let newValue else { return }
				vm.selectThread(id: newValue)
			}
		)
	}
}

#Preview {
	SidebarView()
		.environment(CodaxOrchestrator())
}
