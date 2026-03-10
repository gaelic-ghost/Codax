import Testing
@testable import Codax

@MainActor
struct CodaxPaneModelTests {
	@Test func contentViewModelReflectsSharedOrchestratorState() async throws {
		let orchestrator = makeTestOrchestrator()
		orchestrator.connectionState = .connected
		orchestrator.compatibility = .supported(
			version: CodexCLIVersion(major: 0, minor: 112, patch: 0),
			path: "/usr/local/bin/codex"
		)
		orchestrator.activeThread = testThread(id: "thread-1", preview: "Preview")
		orchestrator.activeError = "Oops"

		let vm = ContentViewModel()
		vm.bind(to: orchestrator)

		#expect(vm.connectionLabel == "Connected")
		#expect(vm.activeThreadTitle == "Thread thread-1")
		#expect(vm.activeError == "Oops")
	}

	@Test func sidebarViewModelRoutesSelectionIntoOrchestrator() async throws {
		let orchestrator = makeTestOrchestrator()
		let first = testThread(id: "thread-1", preview: "First")
		let second = testThread(id: "thread-2", preview: "Second")
		orchestrator.threads = [first, second]

		let vm = SidebarViewModel()
		vm.bind(to: orchestrator)
		vm.selectThread(id: "thread-2")

		#expect(vm.selectedThreadID == "thread-2")
		#expect(orchestrator.activeThread?.id == "thread-2")
	}

	@Test func detailViewModelDerivesInspectorStateFromOrchestrator() async throws {
		let orchestrator = makeTestOrchestrator()
		orchestrator.activeThread = testThread(id: "thread-1", preview: "First")
		orchestrator.activeThreadTokenUsage = ThreadTokenUsage(
			total: TokenUsageBreakdown(
				totalTokens: 100,
				inputTokens: 40,
				cachedInputTokens: 0,
				outputTokens: 60,
				reasoningOutputTokens: 10
			),
			last: TokenUsageBreakdown(
				totalTokens: 100,
				inputTokens: 40,
				cachedInputTokens: 0,
				outputTokens: 60,
				reasoningOutputTokens: 10
			),
			modelContextWindow: nil
		)
		orchestrator.activeTurnPlan = [TurnPlanStep(step: "Inspect state", status: .completed)]
		orchestrator.activeTurnDiff = "M CodaxOrchestrator.swift"

		let vm = DetailViewModel()
		vm.bind(to: orchestrator)

		#expect(vm.threadMetadata.count == 4)
		#expect(vm.tokenUsageText == "Tokens: 100 total, 40 input, 60 output")
		#expect(vm.planSteps.count == 1)
		#expect(vm.diffText == "M CodaxOrchestrator.swift")
	}
}

@MainActor
private func makeTestOrchestrator() -> CodaxOrchestrator {
	CodaxOrchestrator(
		compatibilityProbe: makeProbe(
			versionOutput: .init(status: 0, stdout: "codex-cli 0.112.0\n", stderr: ""),
			whichOutput: .init(status: 0, stdout: "/usr/local/bin/codex\n", stderr: "")
		),
		runtimeFactory: {
			throw TestFailure(message: "Runtime should not be used in pane model tests.")
		}
	)
}

private func testThread(id: String, preview: String) -> Thread {
	Thread(
		id: id,
		preview: preview,
		ephemeral: false,
		modelProvider: "openai",
		createdAt: 1,
		updatedAt: 1,
		status: .object(["type": .string("idle")]),
		path: "/tmp/\(id)",
		cwd: "/tmp",
		cliVersion: "0.112.0",
		source: nil,
		agentNickname: nil,
		agentRole: nil,
		gitInfo: nil,
		name: "Thread \(id)",
		turns: []
	)
}
