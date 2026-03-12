//
//  SidebarProjectsView.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import SwiftUI

struct SidebarProjectsView: View {
	// MARK: - Environment

	@Environment(CodaxViewModel.self) private var viewModel

	// MARK: - View Owned State

	@State private var selectedProjectID: UUID?

	// MARK: - Body

	var body: some View {
		NavigationStack {
			List(viewModel.projects) { project in
				Button {
					viewModel.selectedProjectID = project.id
					selectedProjectID = project.id
				} label: {
					VStack(alignment: .leading, spacing: 4) {
						Text(project.name)
							.font(.headline)
						Text(project.rootPath)
							.font(.caption)
							.foregroundStyle(.secondary)
							.lineLimit(1)
						Text("\(project.threadCodexIDs.count) threads")
							.font(.caption2)
							.foregroundStyle(.tertiary)
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.contentShape(Rectangle())
				}
				.buttonStyle(.plain)
			}
			.navigationTitle("Projects")
			.navigationDestination(item: $selectedProjectID) { projectID in
				SidebarProjectThreadsView(projectID: projectID)
			}
			.onAppear {
				selectedProjectID = viewModel.selectedProjectID
			}
		}
	}
}

#Preview {
	SidebarProjectsView()
}
