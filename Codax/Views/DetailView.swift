//
//  DetailView.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import SwiftData
import SwiftUI

// MARK: - Detail Inspector Route

enum DetailInspectorRoute: String, CaseIterable, Hashable, Identifiable {
	case tokenUsage
	case reasoningEffort
	case gitSummary
	case permissions
	case pendingRequests

	var id: String { rawValue }

	var title: String {
		switch self {
		case .tokenUsage:
			"Token Usage"
		case .reasoningEffort:
			"Reasoning"
		case .gitSummary:
			"Git"
		case .permissions:
			"Permissions"
		case .pendingRequests:
			"Pending"
		}
	}

	var systemImage: String {
		switch self {
		case .tokenUsage:
			"gauge"
		case .reasoningEffort:
			"brain"
		case .gitSummary:
			"arrow.triangle.branch"
		case .permissions:
			"lock.shield"
		case .pendingRequests:
			"questionmark.bubble"
		}
	}
}

// MARK: - Detail View

struct DetailView: View {
	@Environment(CodaxViewModel.self) private var viewModel
	@Binding var inspectorPath: [DetailInspectorRoute]

	var body: some View {
		SelectedThreadInspector(
			selectedThreadCodexId: viewModel.selectedThreadCodexId,
			inspectorPath: $inspectorPath
		)
	}
}

// MARK: - Selected Thread Inspector

private struct SelectedThreadInspector: View {
	@Binding var inspectorPath: [DetailInspectorRoute]
	@Query private var threads: [ThreadModel]
	@Query(sort: [SortDescriptor(\PendingServerRequestModel.updatedAt, order: .reverse)]) private var pendingRequests: [PendingServerRequestModel]

	init(
		selectedThreadCodexId: String?,
		inspectorPath: Binding<[DetailInspectorRoute]>
	) {
		_inspectorPath = inspectorPath
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
		let thread = threads.first
		let visiblePendingRequests = pendingRequests.filter { request in
			guard let thread else { return request.threadCodexId == nil }
			return request.threadCodexId == nil || request.threadCodexId == thread.codexId
		}

		NavigationStack(path: $inspectorPath) {
			DetailInspectorRail(thread: thread, pendingRequests: visiblePendingRequests)
				.navigationTitle("Inspector")
				.navigationDestination(for: DetailInspectorRoute.self) { route in
					DetailInspectorPanel(route: route, thread: thread, pendingRequests: visiblePendingRequests)
				}
		}
	}
}

// MARK: - Detail View Helpers

private func gitDiffLineCounts(_ diff: String) -> (added: Int, removed: Int) {
	diff.split(whereSeparator: \.isNewline).reduce(into: (added: 0, removed: 0)) { counts, line in
		guard let first = line.first else { return }
		if first == "+", !line.hasPrefix("+++") {
			counts.added += 1
		} else if first == "-", !line.hasPrefix("---") {
			counts.removed += 1
		}
	}
}

// MARK: - Detail Inspector Rail

private struct DetailInspectorRail: View {
	@Environment(CodaxViewModel.self) private var viewModel

	let thread: ThreadModel?
	let pendingRequests: [PendingServerRequestModel]

	var body: some View {
		List {
			ForEach(DetailInspectorRoute.allCases) { route in
				NavigationLink(value: route) {
					VStack(spacing: 6) {
						Image(systemName: route.systemImage)
							.font(.title3)
						if let badge = badgeText(for: route) {
							Text(badge)
								.font(.caption2.monospacedDigit())
								.foregroundStyle(.secondary)
								.lineLimit(1)
						}
					}
					.frame(maxWidth: .infinity)
					.padding(.vertical, 4)
				}
				.buttonStyle(.plain)
			}
		}
		.listStyle(.sidebar)
	}

	private func badgeText(for route: DetailInspectorRoute) -> String? {
		switch route {
		case .tokenUsage:
			let totalTokens = thread?.tokenUsage?.total.totalTokens
			return totalTokens.map { "\($0)" }
		case .reasoningEffort:
			return thread?.session?.reasoningEffort.map(reasoningLabel)
		case .gitSummary:
			if viewModel.isRefreshingSelectedGitDiff {
				return "…"
			}
			if let response = thread?.gitDiff?.response {
				let lineCounts = gitDiffLineCounts(response.diff)
				return "\(lineCounts.added + lineCounts.removed)"
			}
			return thread?.gitInfo?.branch
		case .permissions:
			return thread?.session.map { approvalLabel($0.approvalPolicy) } ?? "?"
		case .pendingRequests:
			return pendingRequests.isEmpty ? nil : "\(pendingRequests.count)"
		}
	}

	private func reasoningLabel(_ reasoningEffort: ReasoningEffort) -> String {
		switch reasoningEffort {
		case .none:
			"None"
		case .minimal:
			"Min"
		case .low:
			"Low"
		case .medium:
			"Med"
		case .high:
			"High"
		case .xhigh:
			"XH"
		}
	}

	private func approvalLabel(_ approvalPolicy: AskForApproval) -> String {
		switch approvalPolicy {
		case .untrusted:
			"Untrusted"
		case .onFailure:
			"On Fail"
		case .onRequest:
			"Request"
		case .never:
			"Never"
		case .reject:
			"Reject"
		}
	}
}

// MARK: - Detail Inspector Panel

private struct DetailInspectorPanel: View {
	@Environment(CodaxViewModel.self) private var viewModel

	let route: DetailInspectorRoute
	let thread: ThreadModel?
	let pendingRequests: [PendingServerRequestModel]

	var body: some View {
		List {
			switch route {
			case .tokenUsage:
				tokenUsagePanel
			case .reasoningEffort:
				reasoningPanel
			case .gitSummary:
				gitPanel
			case .permissions:
				permissionsPanel
			case .pendingRequests:
				pendingRequestsPanel
			}
		}
		.navigationTitle(route.title)
	}

	@ViewBuilder
	private var tokenUsagePanel: some View {
		let usage = thread?.tokenUsage
		if let usage {
			Section("Overall") {
				VStack(alignment: .leading, spacing: 12) {
					if let modelContextWindow = usage.modelContextWindow, modelContextWindow > 0 {
						ProgressView(value: min(Double(usage.total.totalTokens) / Double(modelContextWindow), 1))
							.progressViewStyle(.circular)
						Text("\(usage.total.totalTokens) / \(modelContextWindow)")
							.font(.caption.monospacedDigit())
							.foregroundStyle(.secondary)
					}

					LabeledContent("Total", value: "\(usage.total.totalTokens)")
					LabeledContent("Input", value: "\(usage.total.inputTokens)")
					LabeledContent("Output", value: "\(usage.total.outputTokens)")
					LabeledContent("Last Input", value: "\(usage.last.inputTokens)")
					LabeledContent("Last Output", value: "\(usage.last.outputTokens)")
				}
			}
		} else {
			unavailableSection("No token usage is available for the selected thread yet.")
		}
	}

	@ViewBuilder
	private var reasoningPanel: some View {
		if let reasoningEffort = thread?.session?.reasoningEffort {
			Section("Session") {
				LabeledContent("Reasoning", value: reasoningEffort.rawValue)
			}
		} else {
			unavailableSection("Reasoning effort is not available for this thread session.")
		}
	}

	@ViewBuilder
	private var gitPanel: some View {
		if let gitInfo = thread?.gitInfo {
			Section("Repository") {
				LabeledContent("Branch", value: gitInfo.branch ?? "Unknown")
				LabeledContent("HEAD", value: thread?.gitDiff?.response?.sha ?? gitInfo.sha ?? "Unknown")
				LabeledContent("Remote", value: gitInfo.originUrl ?? "Unknown")
			}
		}

		if let response = thread?.gitDiff?.response {
			let lineCounts = gitDiffLineCounts(response.diff)
			Section("Diff") {
				LabeledContent("Added", value: "+\(lineCounts.added)")
				LabeledContent("Removed", value: "-\(lineCounts.removed)")
				if viewModel.isRefreshingSelectedGitDiff {
					Text("Refreshing git summary…")
						.foregroundStyle(.secondary)
				}
				if let errorMessage = thread?.gitDiff?.errorMessage {
					Text(errorMessage)
						.foregroundStyle(.secondary)
				}
			}
		} else if viewModel.isRefreshingSelectedGitDiff || thread?.gitDiff?.errorMessage != nil || thread?.gitInfo != nil {
			Section("Diff") {
				if viewModel.isRefreshingSelectedGitDiff {
					Text("Refreshing git summary…")
						.foregroundStyle(.secondary)
				} else if let errorMessage = thread?.gitDiff?.errorMessage {
					Text(errorMessage)
						.foregroundStyle(.secondary)
				} else {
					Text("Git diff summary is not available yet.")
						.foregroundStyle(.secondary)
				}
			}
		} else {
			unavailableSection("No git metadata is available for the selected thread.")
		}
	}

	@ViewBuilder
	private var permissionsPanel: some View {
		if let session = thread?.session {
			Section("Approval") {
				LabeledContent("Mode", value: approvalTitle(session.approvalPolicy))
			}

			Section("Sandbox") {
				Label(sandboxTitle(session.sandboxPolicy), systemImage: sandboxIcon(session.sandboxPolicy))
					.foregroundStyle(sandboxColor(session.sandboxPolicy))
				Text(sandboxSummary(session.sandboxPolicy))
					.font(.caption)
					.foregroundStyle(.secondary)
			}
		} else {
			unavailableSection("Permission details are not available for this thread session.")
		}
	}

	@ViewBuilder
	private var pendingRequestsPanel: some View {
		if pendingRequests.isEmpty {
			unavailableSection("No pending approval or input requests are active right now.")
		} else {
			Section("Requests") {
				ForEach(pendingRequests) { request in
					VStack(alignment: .leading, spacing: 4) {
						Text(requestTitle(request))
						Text(requestSummary(request))
							.font(.caption)
							.foregroundStyle(.secondary)
					}
				}
			}
		}
	}

	@ViewBuilder
	private func unavailableSection(_ message: String) -> some View {
		Section {
			Text(message)
				.foregroundStyle(.secondary)
		}
	}

	private func approvalTitle(_ approvalPolicy: AskForApproval) -> String {
		switch approvalPolicy {
		case .untrusted:
			return "Untrusted"
		case .onFailure:
			return "On Failure"
		case .onRequest:
			return "On Request"
		case .never:
			return "Never"
		case .reject:
			return "Reject"
		}
	}

	private func sandboxTitle(_ sandboxPolicy: SandboxPolicy) -> String {
		switch sandboxPolicy {
		case .dangerFullAccess:
			return "Full Access"
		case .readOnly:
			return "Read Only"
		case .externalSandbox:
			return "External Sandbox"
		case .workspaceWrite:
			return "Workspace Write"
		}
	}

	private func sandboxSummary(_ sandboxPolicy: SandboxPolicy) -> String {
		switch sandboxPolicy {
		case .dangerFullAccess:
			return "Unrestricted local access."
		case let .readOnly(_, networkAccess):
			return "Read-only filesystem. Network: \(networkAccess ? "enabled" : "disabled")."
		case let .externalSandbox(networkAccess):
			return "External sandbox. Network mode: \(networkAccess.rawValue)."
		case let .workspaceWrite(writableRoots, _, networkAccess, _, _):
			return "Writable roots: \(writableRoots.count). Network: \(networkAccess ? "enabled" : "disabled")."
		}
	}

	private func sandboxIcon(_ sandboxPolicy: SandboxPolicy) -> String {
		switch sandboxPolicy {
		case .dangerFullAccess:
			return "exclamationmark.triangle.fill"
		case .readOnly:
			return "lock"
		case .externalSandbox:
			return "shippingbox"
		case .workspaceWrite:
			return "folder.badge.gearshape"
		}
	}

	private func sandboxColor(_ sandboxPolicy: SandboxPolicy) -> Color {
		switch sandboxPolicy {
		case .dangerFullAccess:
			return .red
		case .readOnly:
			return .blue
		case .externalSandbox:
			return .orange
		case .workspaceWrite:
			return .green
		}
	}

	private func requestTitle(_ request: PendingServerRequestModel) -> String {
		request.title
	}

	private func requestSummary(_ request: PendingServerRequestModel) -> String {
		request.summary
	}
}

// MARK: - Preview

#Preview {
	let container = try! makeCodaxModelContainer(inMemory: true)
	DetailView(inspectorPath: .constant([]))
		.environment(CodaxViewModel(modelContainer: container))
		.modelContainer(container)
}
