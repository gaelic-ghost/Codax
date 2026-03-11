//
//  SelectedThreadStoreView.swift
//  Codax
//
//  Created by Codex on 3/11/26.
//

import SwiftData
import SwiftUI

// MARK: - Selected Thread Store View

struct SelectedThreadStoreView<Content: View>: View {
	private let content: (ThreadModel?) -> Content
	@Query private var threads: [ThreadModel]

	init(
		selectedThreadCodexId: String?,
		@ViewBuilder content: @escaping (ThreadModel?) -> Content
	) {
		self.content = content
		if let selectedThreadCodexId {
			_threads = Query(
				filter: #Predicate<ThreadModel> { thread in
					thread.codexId == selectedThreadCodexId
				}
			)
		} else {
			_threads = Query(
				filter: #Predicate<ThreadModel> { _ in
					false
				}
			)
		}
	}

	var body: some View {
		content(threads.first)
	}
}
