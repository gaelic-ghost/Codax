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

		// MARK: App Level Owned State

	@State private var viewModel: CodaxViewModel
	@State private var columnVisibility = NavigationSplitViewVisibility.automatic
	@State private var preferredColumn = NavigationSplitViewColumn.content

		// MARK: App Initializer

	init() {
		_viewModel = State(wrappedValue: CodaxViewModel())
	}

		// MARK: App Scenes

	var body: some Scene {
		Window("...", id: "...") {
			NavigationSplitView(
				columnVisibility: $columnVisibility,
				preferredCompactColumn: $preferredColumn) {
					SidebarView()
				} content: {
					ContentView()
				} detail: {
					DetailView()
				}
				.environment(viewModel)
		}
		SwiftUI.Settings {
			SettingsView()
		}
	}
}
