//
//  CodaxApp.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import SwiftUI
import SwiftData

@main
struct CodaxApp: App {
	@NSApplicationDelegateAdaptor private var appDelegate: CodaxAppDelegate
		// `scenePhase` at `App` level is an aggregate
		// ...of all scenes.
		// See docs for more information.
	@Environment(\.scenePhase) private var aggScenePhase
	private let modelContainer: ModelContainer
	@State private var viewModel: CodaxViewModel
	@State private var columnVis = NavigationSplitViewVisibility.automatic
	@State private var prefferedColumn = NavigationSplitViewColumn.content

	init() {
		let modelContainer = try! CodaxPersistenceBridge.makeModelContainer()
		self.modelContainer = modelContainer
		_viewModel = State(initialValue: CodaxViewModel(modelContainer: modelContainer))
	}

    var body: some Scene {
		// Primary `Scene` for main three-pane window.
		Window("Codax", id: "main-window") {
			NavigationSplitView(
				columnVisibility: $columnVis,
				preferredCompactColumn: $prefferedColumn) {
						// sidebar:
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
							)
						)
				} content: {
					ContentView()
				} detail: {
					DetailView()
				}
			}
			.environment(viewModel)
			.modelContainer(modelContainer)

    }
}
