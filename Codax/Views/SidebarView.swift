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
	@Binding var selectedProjectRootPath: String?

	var body: some View {
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
						Button {
							selectedProjectRootPath = project.rootPath
							selection = nil
						} label: {
							ProjectRow(
								project: project,
								isSelected: selectedProjectRootPath == project.rootPath
							)
						}
						.buttonStyle(.plain)
					}
				}
			}

			if let selectedProjectRootPath {
				ProjectThreadListScreen(
					projectRootPath: selectedProjectRootPath,
					selection: $selection
				)
			}
		}
		.navigationTitle("Projects")
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

// MARK: - Project Row

private struct ProjectRow: View {
	let project: Project
	let isSelected: Bool

	var body: some View {
		VStack(alignment: .leading, spacing: 2) {
			Text(project.name.isEmpty ? project.rootPath : project.name)
			Text(project.rootPath)
				.font(.caption)
				.foregroundStyle(.secondary)
				.lineLimit(1)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.contentShape(Rectangle())
		.padding(.vertical, 2)
		.background(isSelected ? Color.accentColor.opacity(0.14) : Color.clear)
		.clipShape(RoundedRectangle(cornerRadius: 8))
	}
}

// MARK: - Project Thread Screen

private struct ProjectThreadListScreen: View {
	@Query private var projects: [Project]
	@Binding var selection: String?
	@State private var sort = ProjectThreadSort.recentFirst
	@State private var filter = ProjectThreadFilter.activeOnly

	init(
		projectRootPath: String,
		selection: Binding<String?>
	) {
		_selection = selection
		_projects = Query(
			filter: #Predicate<Project> { project in
				project.rootPath == projectRootPath
			}
		)
	}

	var body: some View {
		if let project = projects.first {
			Section(projectTitle(project)) {
				ProjectThreadQueryList(
					project: project,
					selection: $selection,
					sort: sort,
					filter: filter
				)
			}
			Section {
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
			}
		}
	}

	private func projectTitle(_ project: Project) -> String {
		project.name.isEmpty ? project.rootPath : project.name
	}
}

// MARK: - Project Thread Rows

private struct ProjectThreadQueryList: View {
	@Query private var threads: [ThreadModel]
	@Binding var selection: String?

	init(
		project: Project,
		selection: Binding<String?>,
		sort: ProjectThreadSort,
		filter: ProjectThreadFilter
	) {
		_selection = selection
		let projectRootPath = project.rootPath
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
		if threads.isEmpty {
			Text("No matching threads")
				.foregroundStyle(.secondary)
		} else {
			ForEach(threads) { thread in
				Button {
					selection = thread.codexId
				} label: {
					ProjectThreadRow(
						thread: thread,
						isSelected: selection == thread.codexId
					)
				}
				.buttonStyle(.plain)
			}
		}
	}
}

// MARK: - Project Thread Row

private struct ProjectThreadRow: View {
	let thread: ThreadModel
	let isSelected: Bool

	var body: some View {
		VStack(alignment: .leading, spacing: 2) {
			Text(thread.displayTitle)
			Text(threadStatusSummary)
				.font(.caption)
				.foregroundStyle(.secondary)
				.lineLimit(1)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.contentShape(Rectangle())
		.padding(.vertical, 2)
		.background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
		.clipShape(RoundedRectangle(cornerRadius: 8))
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
	let container = try! makeCodaxModelContainer(inMemory: true)
	SidebarView(selection: .constant(nil), selectedProjectRootPath: .constant(nil))
		.environment(CodaxViewModel(modelContainer: container))
		.modelContainer(container)
}
