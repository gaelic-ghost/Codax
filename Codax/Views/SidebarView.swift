//
//  SidebarView.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import SwiftData
import SwiftUI

// MARK: - Sidebar View

struct SidebarView: View {
	@Environment(CodaxViewModel.self) private var viewModel
	@Query(
		sort: [SortDescriptor(\Project.updatedAt, order: .reverse)]
	) private var projects: [Project]
	@Binding var selection: String?
	@State private var navigationPath: [ProjectSidebarRoute] = []

	var body: some View {
		NavigationStack(path: $navigationPath) {
			List {
				if let banner = compatibilityBannerText {
					Section("Compatibility") {
						Text(banner)
							.font(.caption)
					}
				}

				Section("Projects") {
					if projects.isEmpty {
						Text("No projects yet")
							.foregroundStyle(.secondary)
					} else {
						ForEach(projects) { project in
							NavigationLink(value: ProjectSidebarRoute(project: project)) {
								ProjectRow(project: project)
							}
						}
					}
				}
			}
			.navigationTitle("Projects")
			.navigationDestination(for: ProjectSidebarRoute.self) { route in
				ProjectThreadListScreen(
					route: route,
					selection: $selection
				) {
					Task {
						await viewModel.startThread()
					}
				}
			}
		}
	}

	// MARK: Private Helpers

	private var compatibilityBannerText: String? {
		guard case let .unsupported(version, _, supportedRange, reason) = viewModel.compatibility else {
			return nil
		}
		let versionText = version?.displayString ?? "unknown version"
		return "Unsupported CLI \(versionText). Expected \(supportedRange). \(reason)"
	}
}

// MARK: - Project Sidebar Route

private struct ProjectSidebarRoute: Hashable {
	let rootPath: String
	let displayName: String

	init(project: Project) {
		rootPath = project.rootPath
		displayName = project.name.isEmpty ? project.rootPath : project.name
	}
}

// MARK: - Project Row

private struct ProjectRow: View {
	let project: Project

	var body: some View {
		VStack(alignment: .leading, spacing: 2) {
			Text(project.name.isEmpty ? project.rootPath : project.name)
			Text(project.rootPath)
				.font(.caption)
				.foregroundStyle(.secondary)
				.lineLimit(1)
		}
	}
}

// MARK: - Project Thread Screen

private struct ProjectThreadListScreen: View {
	let route: ProjectSidebarRoute
	@Binding var selection: String?
	let startThread: @Sendable () -> Void
	@State private var sort = ProjectThreadSort.recentFirst
	@State private var filter = ProjectThreadFilter.activeOnly

	var body: some View {
		ProjectThreadQueryList(
			projectRootPath: route.rootPath,
			selection: $selection,
			sort: sort,
			filter: filter
		)
		.navigationTitle(route.displayName)
		.toolbar {
			ToolbarItemGroup {
				Menu("View") {
					Picker("Sort", selection: $sort) {
						ForEach(ProjectThreadSort.allCases) { sort in
							Text(sort.label).tag(sort)
						}
					}

					Picker("Filter", selection: $filter) {
						ForEach(ProjectThreadFilter.allCases) { filter in
							Text(filter.label).tag(filter)
						}
					}
				}

				Button("New Thread", action: startThread)
			}
		}
	}
}

// MARK: - Project Thread Query List

private struct ProjectThreadQueryList: View {
	@Query private var threads: [ThreadModel]
	@Binding var selection: String?

	init(
		projectRootPath: String,
		selection: Binding<String?>,
		sort: ProjectThreadSort,
		filter: ProjectThreadFilter
	) {
		_selection = selection
		let predicate: Predicate<ThreadModel>
		if filter == .activeOnly {
			predicate = #Predicate<ThreadModel> { thread in
				thread.cwd == projectRootPath && !thread.isArchived && !thread.isClosed
			}
		} else {
			predicate = #Predicate<ThreadModel> { thread in
				thread.cwd == projectRootPath
			}
		}
		let sortDescriptors: [SortDescriptor<ThreadModel>]
		if sort == .recentFirst {
			sortDescriptors = [SortDescriptor(\ThreadModel.updatedAt, order: .reverse)]
		} else {
			sortDescriptors = [SortDescriptor(\ThreadModel.updatedAt, order: .forward)]
		}
		_threads = Query(filter: predicate, sort: sortDescriptors)
	}

	var body: some View {
		List(selection: $selection) {
			if threads.isEmpty {
				Text("No matching threads")
					.foregroundStyle(.secondary)
			} else {
				ForEach(threads) { thread in
					ProjectThreadRow(thread: thread)
						.tag(thread.codexId)
				}
			}
		}
	}
}

// MARK: - Project Thread Row

private struct ProjectThreadRow: View {
	let thread: ThreadModel

	var body: some View {
		VStack(alignment: .leading, spacing: 2) {
			Text(thread.displayTitle)
			Text(threadStatusSummary)
				.font(.caption)
				.foregroundStyle(.secondary)
				.lineLimit(1)
		}
	}

	private var threadStatusSummary: String {
		var parts = [thread.modelProvider]
		if thread.isArchived {
			parts.append("archived")
		}
		if thread.isClosed {
			parts.append("closed")
		}
		return parts.joined(separator: " · ")
	}
}

// MARK: - Project Thread Sort

private enum ProjectThreadSort: String, CaseIterable, Identifiable {
	case recentFirst
	case oldestFirst

	var id: String { rawValue }

	var label: String {
		switch self {
			case .recentFirst:
				"Most Recent"
			case .oldestFirst:
				"Oldest"
		}
	}
}

// MARK: - Project Thread Filter

private enum ProjectThreadFilter: String, CaseIterable, Identifiable {
	case activeOnly
	case all

	var id: String { rawValue }

	var label: String {
		switch self {
			case .activeOnly:
				"Open Threads"
			case .all:
				"All Threads"
		}
	}
}

// MARK: - Preview

#Preview {
	let container = try! CodaxPersistenceBridge.makeModelContainer(inMemory: true)
	SidebarView(selection: .constant(nil))
		.environment(CodaxViewModel(modelContainer: container))
		.modelContainer(container)
}
