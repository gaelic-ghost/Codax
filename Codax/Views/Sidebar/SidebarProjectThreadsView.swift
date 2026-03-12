//
//  SidebarProjectThreadsView.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import SwiftUI

struct SidebarProjectThreadsView: View {
	// MARK: - Environment

	@Environment(CodaxViewModel.self) private var viewModel

	// MARK: - Input

	let projectID: UUID

	// MARK: - Derived State

	private var project: CodaxProject? {
		viewModel.projects.first(where: { $0.id == projectID })
	}

	private var projectThreads: [Thread] {
		guard let project else { return [] }
		let threadsByID = Dictionary(uniqueKeysWithValues: viewModel.threads.map { ($0.id, $0) })
		return project.threadCodexIDs.compactMap { threadsByID[$0] }
	}

	// MARK: - Body

	var body: some View {
		Group {
			if let project {
				List(projectThreads, id: \.id) { thread in
					Button {
						viewModel.selectedThreadCodexId = thread.id
					} label: {
						VStack(alignment: .leading, spacing: 4) {
							Text(thread.name ?? thread.preview)
								.font(.headline)
							Text(thread.preview)
								.font(.caption)
								.foregroundStyle(.secondary)
								.lineLimit(2)
						}
						.frame(maxWidth: .infinity, alignment: .leading)
						.contentShape(Rectangle())
					}
					.buttonStyle(.plain)
				}
				.navigationTitle(project.name)
				.onAppear {
					viewModel.selectedProjectID = project.id
				}
			} else {
				ContentUnavailableView("Project Not Found", systemImage: "folder")
			}
		}
	}
}

#Preview {
	SidebarProjectThreadsView(projectID: UUID())
}
