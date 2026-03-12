//
//  SidebarProjectsView.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import SwiftUI

struct SidebarProjectsView: View {
	// MARK: - Environment

	@Environment(CodaxOrchestrator.self) private var viewModel

	// MARK: - View Owned State

	@State private var selectedProjectID: UUID?

	// MARK: - Body

	var body: some View {
		NavigationStack {
			List(viewModel.projectListings) { projListing in
				SidebarThreadListing()
			}
			.navigationTitle("Projects")
			.navigationDestination(item: $selectedProjectID) { projectID in
				SidebarProjectThreadsView(projectID: projectID)
			}
			.onAppear {
			}
		}
	}
}

#Preview {
	SidebarProjectsView()
}
