//
//  SidebarView.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import SwiftUI
import SwiftData

struct SidebarView: View {
	@Environment(CodaxViewModel.self) private var viewModel
	@Query(
		filter: #Predicate<ThreadModel> { thread in
			!thread.isArchived && !thread.isClosed
		},
		sort: [SortDescriptor(\ThreadModel.updatedAt, order: .reverse)]
	) private var threads: [ThreadModel]
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
					if threads.isEmpty {
						Text("No threads yet")
							.foregroundStyle(.secondary)
					} else {
						ForEach(threads, id: \.codexId) { thread in
							Text(thread.displayTitle)
								.tag(thread.codexId)
						}
					}
				}
		}
		.navigationTitle("Threads")
		.toolbar {
			Button("New Thread") {
				Task {
					await viewModel.startThread()
				}
			}
		}
	}



	private var compatibilityBannerText: String? {
		guard case let .unsupported(version, _, supportedRange, reason) = viewModel.compatibility else {
			return nil
		}
		let versionText = version?.displayString ?? "unknown version"
		return "Unsupported CLI \(versionText). Expected \(supportedRange). \(reason)"
	}
}

#Preview {
	let container = try! CodaxPersistenceBridge.makeModelContainer(inMemory: true)
	SidebarView(selection: .constant(nil))
		.environment(CodaxViewModel(modelContainer: container))
		.modelContainer(container)
}
