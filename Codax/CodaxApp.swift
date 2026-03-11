//
//  CodaxApp.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import SwiftUI

@main
struct CodaxApp: App {
	@NSApplicationDelegateAdaptor private var appDelegate: CodaxAppDelegate
		// `scenePhase` at `App` level is an aggregate
		// ...of all scenes.
		// See docs for more information.
	@Environment(\.scenePhase) private var aggScenePhase
	@State private var orchestrator = CodaxOrchestrator()
	@State private var columnVis = NavigationSplitViewVisibility.automatic
	@State private var prefferedColumn = NavigationSplitViewColumn.content

    var body: some Scene {
		// Primary `Scene` for main three-pane window.
		Window("Codax", id: "main-window") {
			NavigationSplitView(
				columnVisibility: $columnVis,
				preferredCompactColumn: $prefferedColumn) {
						// sidebar:
					SidebarView(
						selection: Binding(
							get: { orchestrator.selectedThreadCodexId },
							set: { orchestrator.selectedThreadCodexId = $0 }
						)
					)
				} content: {
					ContentView()
				} detail: {
					DetailView()
				}
		}
		.environment(orchestrator)

    }
}
