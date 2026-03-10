//
//  CodaxApp.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import SwiftUI

@main
struct CodaxApp: App {

	@State private var orchestrator = CodaxOrchestrator()
	@State private var columnVis = NavigationSplitViewVisibility.automatic
	@State private var prefferedColumn = NavigationSplitViewColumn.content

    var body: some Scene {
		Window("Codax", id: "main-window") {
			NavigationSplitView(
				columnVisibility: $columnVis,
				preferredCompactColumn: $prefferedColumn) {
					SidebarView()
				} content: {
					ContentView()
				} detail: {
					DetailView()
				}
		}
		.environment(orchestrator)
    }
}
