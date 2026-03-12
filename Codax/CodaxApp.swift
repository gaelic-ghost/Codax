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
	@NSApplicationDelegateAdaptor private var appDelegate: CodaxAppDelegate
	@Environment(\.scenePhase) private var aggScenePhase

	private let modelContainer: ModelContainer
	@State private var viewModel: CodaxViewModel
	@State private var columnVisibility = NavigationSplitViewVisibility.automatic
	@State private var preferredColumn = NavigationSplitViewColumn.content
	@State private var sidebarPath: [ProjectSidebarRoute] = []
	@State private var detailInspectorPath: [DetailInspectorRoute] = []
	@State private var isInspectorVisible = true
	@State private var isProjectImporterPresented = false

	init() {
		let modelContainer = try! CodaxPersistenceBridge.makeModelContainer()
		self.modelContainer = modelContainer
		_viewModel = State(initialValue: CodaxViewModel(modelContainer: modelContainer))
	}

	var body: some Scene {
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
					navigationPath: $sidebarPath
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

				ToolbarItem(placement: .automatic) {
					Button {
						toggleInspector()
					} label: {
						Label(
							isInspectorVisible ? "Hide Inspector" : "Show Inspector",
							systemImage: "sidebar.right"
						)
					}
				}
			}
			.fileImporter(
				isPresented: $isProjectImporterPresented,
				allowedContentTypes: [.folder]
			) { result in
				handleProjectImport(result)
			}
			.environment(viewModel)
			.modelContainer(modelContainer)
		}
	}
}

// MARK: - Private Helpers

private extension CodaxApp {
	var currentProjectRootPath: String? {
		sidebarPath.last?.rootPath
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
		viewModel.importProject(rootPath: rootPath)
		sidebarPath = [
			ProjectSidebarRoute(
				rootPath: rootPath,
				displayName: url.lastPathComponent
			)
		]
	}
}
