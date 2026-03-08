//
//  CodaxApp.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import SwiftUI

@main
struct CodaxApp: App {

	@State private var cVis = NavigationSplitViewVisibility.doubleColumn
	@State private var cPref = NavigationSplitViewColumn.content
	@State private var threads = []


    var body: some Scene {

		Window("somethongText", id: "windowID") {
			Text("viewText")
		}
    }
}
