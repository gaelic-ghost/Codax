import Testing
@testable import Codax

@MainActor
struct CodaxOrchestratorTests {
	@Test func refreshCompatibilityUpdatesOrchestratorState() async throws {
		let orchestrator = CodaxOrchestrator(
			compatibilityProbe: makeProbe(
				versionOutput: .init(status: 0, stdout: "codex-cli 0.111.9\n", stderr: ""),
				whichOutput: .init(status: 0, stdout: "/usr/local/bin/codex\n", stderr: "")
			)
		)

		await orchestrator.refreshCompatibility()

		#expect(
			orchestrator.compatibility ==
			.supported(
				version: CodexCLIVersion(major: 0, minor: 111, patch: 9),
				path: "/usr/local/bin/codex"
			)
		)
	}

	@Test func connectDoesNotStartSessionWhenCompatibilityIsUnsupported() async throws {
		let starter = TestSessionStarter()
		let orchestrator = CodaxOrchestrator(
			compatibilityProbe: makeProbe(
				versionOutput: .init(status: 0, stdout: "codex-cli 0.113.0\n", stderr: ""),
				whichOutput: .init(status: 0, stdout: "/usr/local/bin/codex\n", stderr: "")
			),
			sessionStarter: {
				await starter.markStarted()
			}
		)

		await orchestrator.connect()

		#expect(await starter.callCount() == 0)
		#expect(orchestrator.connectionState == .disconnected)
		guard case let .unsupported(version, _, _, _) = orchestrator.compatibility else {
			#expect(Bool(false))
			return
		}
		#expect(version == CodexCLIVersion(major: 0, minor: 113, patch: 0))
	}

	@Test func connectStartsSessionWhenCompatibilityIsSupported() async throws {
		let starter = TestSessionStarter()
		let orchestrator = CodaxOrchestrator(
			compatibilityProbe: makeProbe(
				versionOutput: .init(status: 0, stdout: "codex-cli 0.112.0\n", stderr: ""),
				whichOutput: .init(status: 0, stdout: "/usr/local/bin/codex\n", stderr: "")
			),
			sessionStarter: {
				await starter.markStarted()
			}
		)

		await orchestrator.connect()

		#expect(await starter.callCount() == 1)
		#expect(orchestrator.connectionState == .connected)
	}
}

private actor TestSessionStarter {
	private var starts = 0

	func markStarted() {
		starts += 1
	}

	func callCount() -> Int {
		starts
	}
}
