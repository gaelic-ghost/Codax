//
//  CodaxViewModel+Types.swift
//  Codax
//
//  Created by Gale Williams on 3/8/26.
//

import Foundation

// MARK: - View Model Types

public enum CodaxCompatibilityState: Sendable, Equatable {
	case unknown
	case checking
	case supported(version: CodexCLIVersion, path: String?)
	case unsupported(version: CodexCLIVersion?, path: String?, supportedRange: String, reason: String)

	init(_ compatibility: CodexCLICompatibility) {
		switch compatibility {
			case .unknown:
				self = .unknown
			case .checking:
				self = .checking
			case let .supported(version, path):
				self = .supported(version: version, path: path)
			case let .unsupported(version, path, supportedRange, reason):
				self = .unsupported(
					version: version,
					path: path,
					supportedRange: supportedRange,
					reason: reason
				)
		}
	}
}

struct CodaxViewModelError: Equatable {
	let message: String
}

struct CodaxCompatibilityDebugInfo: Equatable {
	let formattedDescription: String
}

struct CodaxPendingLogin: Equatable {
	let loginId: String
	let authURL: String
}

struct CodaxGitSummaryState: Equatable {
	let branch: String?
	let sha: String?
	let originURL: String?
	let addedLineCount: Int
	let removedLineCount: Int
	let isRefreshing: Bool
	let errorMessage: String?
}

struct CodaxThreadSessionConfiguration: Equatable {
	let approvalPolicy: AskForApproval?
	let sandboxPolicy: SandboxPolicy?
	let reasoningEffort: ReasoningEffort?
}

enum CodaxPendingUserRequest: Identifiable, Equatable {
	case itemCommandExecutionRequestApproval(CommandExecutionRequestApprovalParams, requestId: RequestId)
	case itemFileChangeRequestApproval(FileChangeRequestApprovalParams, requestId: RequestId)
	case itemToolRequestUserInput(ToolRequestUserInputParams, requestId: RequestId)
	case mcpServerElicitationRequest(McpServerElicitationRequestParams, requestId: RequestId)
	case itemToolCall(DynamicToolCallParams, requestId: RequestId)
	case accountChatgptAuthTokensRefresh(ChatgptAuthTokensRefreshParams, requestId: RequestId)
	case applyPatchApproval(ApplyPatchApprovalParams, requestId: RequestId)
	case execCommandApproval(ExecCommandApprovalParams, requestId: RequestId)

	init(_ request: ServerRequestEnvelope) {
		switch request {
			case let .itemCommandExecutionRequestApproval(params, id):
				self = .itemCommandExecutionRequestApproval(params, requestId: id)
			case let .itemFileChangeRequestApproval(params, id):
				self = .itemFileChangeRequestApproval(params, requestId: id)
			case let .itemToolRequestUserInput(params, id):
				self = .itemToolRequestUserInput(params, requestId: id)
			case let .mcpServerElicitationRequest(params, id):
				self = .mcpServerElicitationRequest(params, requestId: id)
			case let .itemToolCall(params, id):
				self = .itemToolCall(params, requestId: id)
			case let .accountChatgptAuthTokensRefresh(params, id):
				self = .accountChatgptAuthTokensRefresh(params, requestId: id)
			case let .applyPatchApproval(params, id):
				self = .applyPatchApproval(params, requestId: id)
			case let .execCommandApproval(params, id):
				self = .execCommandApproval(params, requestId: id)
		}
	}

	var id: String {
		requestId.displayString
	}

	var requestId: RequestId {
		switch self {
			case let .itemCommandExecutionRequestApproval(_, requestId),
				let .itemFileChangeRequestApproval(_, requestId),
				let .itemToolRequestUserInput(_, requestId),
				let .mcpServerElicitationRequest(_, requestId),
				let .itemToolCall(_, requestId),
				let .accountChatgptAuthTokensRefresh(_, requestId),
				let .applyPatchApproval(_, requestId),
				let .execCommandApproval(_, requestId):
				return requestId
		}
	}

	var title: String {
		switch self {
			case .itemCommandExecutionRequestApproval:
				return "Command approval"
			case .itemFileChangeRequestApproval:
				return "File change approval"
			case .itemToolRequestUserInput:
				return "Tool input request"
			case .mcpServerElicitationRequest:
				return "MCP elicitation request"
			case .itemToolCall:
				return "Tool call"
			case .accountChatgptAuthTokensRefresh:
				return "Refresh ChatGPT tokens"
			case .applyPatchApproval:
				return "Patch approval"
			case .execCommandApproval:
				return "Exec command approval"
		}
	}

	var summary: String {
		switch self {
			case let .itemCommandExecutionRequestApproval(params, _):
				return params.reason ?? params.command ?? "Command execution requires review."
			case let .itemFileChangeRequestApproval(params, _):
				return params.reason ?? params.grantRoot ?? "File changes require review."
			case let .itemToolRequestUserInput(params, _):
				return params.questions.first?.question ?? "Tool requires user input."
			case let .mcpServerElicitationRequest(params, _):
				switch params {
					case let .form(_, _, serverName, message, _):
						return "\(serverName): \(message)"
					case let .url(_, _, serverName, message, url, _):
						return "\(serverName): \(message) (\(url))"
				}
			case let .itemToolCall(params, _):
				return "\(params.tool) requested \(params.callId)"
			case let .accountChatgptAuthTokensRefresh(params, _):
				return "Reason: \(params.reason.rawValue)"
			case let .applyPatchApproval(params, _):
				return params.reason ?? "Patch application requires review."
			case let .execCommandApproval(params, _):
				return params.reason ?? params.command.joined(separator: " ")
		}
	}
}

private extension RequestId {
	var displayString: String {
		switch self {
			case let .string(value):
				return value
			case let .int(value):
				return String(value)
		}
	}
}

struct CodaxViewModelThreadSessionState {
	private(set) var tokenUsageByThreadCodexId: [String: ThreadTokenUsage] = [:]
	private(set) var turnPlanByThreadCodexId: [String: [TurnPlanStep]] = [:]
	private(set) var turnDiffByThreadCodexId: [String: String] = [:]
	private(set) var gitSummaryByThreadCodexId: [String: CodaxGitSummaryState] = [:]
	private(set) var sessionConfigurationByThreadCodexId: [String: CodaxThreadSessionConfiguration] = [:]
	var selectedThreadCodexId: String?

	var selectedTokenUsage: ThreadTokenUsage? {
		guard let selectedThreadCodexId else { return nil }
		return tokenUsageByThreadCodexId[selectedThreadCodexId]
	}

	var selectedTurnPlan: [TurnPlanStep] {
		guard let selectedThreadCodexId else { return [] }
		return turnPlanByThreadCodexId[selectedThreadCodexId] ?? []
	}

	var selectedTurnDiff: String? {
		guard let selectedThreadCodexId else { return nil }
		return turnDiffByThreadCodexId[selectedThreadCodexId]
	}

	var selectedGitSummary: CodaxGitSummaryState? {
		guard let selectedThreadCodexId else { return nil }
		return gitSummaryByThreadCodexId[selectedThreadCodexId]
	}

	var selectedSessionConfiguration: CodaxThreadSessionConfiguration? {
		guard let selectedThreadCodexId else { return nil }
		return sessionConfigurationByThreadCodexId[selectedThreadCodexId]
	}

	mutating func selectThread(codexId: String) {
		selectedThreadCodexId = codexId
	}

	mutating func setTokenUsage(_ tokenUsage: ThreadTokenUsage?, for threadCodexId: String) {
		tokenUsageByThreadCodexId[threadCodexId] = tokenUsage
	}

	mutating func setTurnPlan(_ plan: [TurnPlanStep], for threadCodexId: String) {
		turnPlanByThreadCodexId[threadCodexId] = plan
	}

	mutating func setTurnDiff(_ diff: String?, for threadCodexId: String) {
		turnDiffByThreadCodexId[threadCodexId] = diff
	}

	mutating func setGitSummary(_ gitSummary: CodaxGitSummaryState?, for threadCodexId: String) {
		gitSummaryByThreadCodexId[threadCodexId] = gitSummary
	}

	mutating func setSessionConfiguration(_ configuration: CodaxThreadSessionConfiguration?, for threadCodexId: String) {
		sessionConfigurationByThreadCodexId[threadCodexId] = configuration
	}

	mutating func clearSelectedTransientState() {
		guard let selectedThreadCodexId else { return }
		tokenUsageByThreadCodexId[selectedThreadCodexId] = nil
		turnPlanByThreadCodexId[selectedThreadCodexId] = []
		turnDiffByThreadCodexId[selectedThreadCodexId] = nil
		gitSummaryByThreadCodexId[selectedThreadCodexId] = nil
		sessionConfigurationByThreadCodexId[selectedThreadCodexId] = nil
	}

	mutating func clearSelection() {
		selectedThreadCodexId = nil
	}

	mutating func pruneTransientState(validThreadCodexIDs: Set<String>) {
		tokenUsageByThreadCodexId = tokenUsageByThreadCodexId.filter { validThreadCodexIDs.contains($0.key) }
		turnPlanByThreadCodexId = turnPlanByThreadCodexId.filter { validThreadCodexIDs.contains($0.key) }
		turnDiffByThreadCodexId = turnDiffByThreadCodexId.filter { validThreadCodexIDs.contains($0.key) }
		gitSummaryByThreadCodexId = gitSummaryByThreadCodexId.filter { validThreadCodexIDs.contains($0.key) }
		sessionConfigurationByThreadCodexId = sessionConfigurationByThreadCodexId.filter { validThreadCodexIDs.contains($0.key) }
		if let selectedThreadCodexId, !validThreadCodexIDs.contains(selectedThreadCodexId) {
			self.selectedThreadCodexId = nil
		}
	}
}
