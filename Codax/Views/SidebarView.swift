//
//  SidebarView.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import SwiftUI

struct SidebarView: View {
	@Environment(CodaxOrchestrator.self) private var orchestrator
	@Binding var selection: String?

	var body: some View {
		List(selection: $selection) {
			if let banner = compatibilityBannerText {
				Section("Compatibility") {
					Text(banner)
						.font(.caption)
				}
			}

			Section("Threads") {
				if orchestrator.threads.isEmpty {
					Text("No threads yet")
						.foregroundStyle(.secondary)
				} else {
					ForEach(orchestrator.threads, id: \.id) { thread in
						Text(displayTitle(for: thread))
							.tag(thread.id)
					}
				}
			}
		}
		.navigationTitle("Threads")
		.toolbar {
			Button("New Thread") {
				Task {
					await orchestrator.startThread()
				}
			}
		}
	}



	private var compatibilityBannerText: String? {
		guard case let .unsupported(version, _, supportedRange, reason) = orchestrator.compatibility else {
			return nil
		}
		let versionText = version?.displayString ?? "unknown version"
		return "Unsupported CLI \(versionText). Expected \(supportedRange). \(reason)"
	}

	private func displayTitle(for thread: Thread) -> String {
		if let name = thread.name, !name.isEmpty {
			return name
		}
		return thread.preview
	}
}

#Preview {
	SidebarView(selection: .constant(nil))
		.environment(CodaxOrchestrator())
}
