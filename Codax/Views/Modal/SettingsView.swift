//
//  SettingsView.swift
//  Codax
//
//  Created by Gale Williams on 3/12/26.
//

import SwiftUI

struct SettingsView: View {

		// MARK: Environment
	
	@Environment(CodaxViewModel.self) private var viewModel

		// MARK: View Owned State

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    SettingsView()
}
