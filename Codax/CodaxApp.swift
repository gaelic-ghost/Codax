//
//  CodaxApp.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

	// MARK: - App Shell

@main
struct CodaxApp: App {

		// MARK: Delegate & Environment

	@NSApplicationDelegateAdaptor private var appDelegate: CodaxAppDelegate
	@Environment(\.scenePhase) private var aggScenePhase
	private let modelContainer: ModelContainer

		// MARK: App Level Owned State

	@State private var viewModel: CodaxViewModel
	@State private var columnVisibility = NavigationSplitViewVisibility.automatic
	@State private var preferredColumn = NavigationSplitViewColumn.content
	@State private var selectedProjectRootPath: String?
	@State private var detailInspectorPath: [DetailInspectorRoute] = []
	@State private var isInspectorVisible = true
	@State private var isProjectImporterPresented = false

		// MARK: App Initializer

	init() {
		let modelContainer = try! makeCodaxModelContainer()
		self.modelContainer = modelContainer
		_viewModel = State(initialValue: CodaxViewModel(modelContainer: modelContainer))
	}

		// MARK: - App Scenes

	var body: some Scene {

			// MARK: Primary Window Scene

		Window("Codax", id: "main-window") {
			NavigationSplitView(
				columnVisibility: $columnVisibility,
				preferredCompactColumn: $preferredColumn
			) {
				SidebarView(
					selection: Binding(
						get: { viewModel.selectedThreadCodexId },
						set: { newValue in
							guard let newValue else {
								viewModel.selectedThreadCodexId = nil
								return
							}
							Task {
								await viewModel.selectThread(codexId: newValue)
							}
						}
					),
					selectedProjectRootPath: $selectedProjectRootPath
				)
				.navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 360)
			} content: {
				ContentView()
					.navigationSplitViewColumnWidth(min: 340, ideal: 420, max: 640)
			} detail: {
				detailColumn
					.navigationSplitViewColumnWidth(
						min: detailColumnWidth.min,
						ideal: detailColumnWidth.ideal,
						max: detailColumnWidth.max
					)
			}
			.navigationSplitViewStyle(.balanced)

			// MARK: Toolbar

			.toolbar {
				ToolbarItem(placement: .navigation) {
					Button {
						isProjectImporterPresented = true
					} label: {
						Label("New Project", systemImage: "folder.badge.plus")
					}
					.keyboardShortcut("N", modifiers: [.command, .shift])
				}

				ToolbarItem(placement: .principal) {
					Button {
						Task {
							await viewModel.startThread(cwd: currentProjectRootPath)
						}
					} label: {
						Label("New Thread", systemImage: "plus.bubble")
					}
					.disabled(viewModel.connectionState != .connected)
					.keyboardShortcut("N", modifiers: [.command])
				}
			}

			// MARK: File Importer

			.fileImporter(
				isPresented: $isProjectImporterPresented,
				allowedContentTypes: [.folder]
			) { result in
				handleProjectImport(result)
			}

			// MARK: Env & Container Injection

			.environment(viewModel)
			.modelContainer(modelContainer)
		}

			// MARK: Settings Scene

		SwiftUI.Settings {
			SettingsView()
		}
	}
}

// MARK: - Private Helpers

private extension CodaxApp {
	var currentProjectRootPath: String? {
		selectedProjectRootPath
	}

	var detailColumn: some View {
		Group {
			if isInspectorVisible {
				DetailView(inspectorPath: $detailInspectorPath)
			} else {
				Color.clear
					.accessibilityHidden(true)
			}
		}
	}

	var detailColumnWidth: (min: CGFloat, ideal: CGFloat, max: CGFloat) {
		guard isInspectorVisible else { return (1, 1, 1) }
		return detailInspectorPath.isEmpty ? (72, 80, 96) : (320, 340, 380)
	}

	func toggleInspector() {
		if isInspectorVisible {
			isInspectorVisible = false
			detailInspectorPath.removeAll()
		} else {
			isInspectorVisible = true
		}
	}

	func handleProjectImport(_ result: Result<URL, Error>) {
		guard case let .success(url) = result else { return }
		let rootPath = url.path()
		let context = modelContainer.mainContext
		let descriptor = FetchDescriptor<Project>(
			predicate: #Predicate<Project> { $0.rootPath == rootPath }
		)
		if let project = try? context.fetch(descriptor).first {
			project.activate()
		} else {
			let name = url.lastPathComponent
			context.insert(
				Project(
					record: ProjectRecord(
						name: name.isEmpty ? rootPath : name,
						rootPath: rootPath,
						isActive: true
					)
				)
			)
		}
		if context.hasChanges {
			try? context.save()
		}
		selectedProjectRootPath = rootPath
	}
}
