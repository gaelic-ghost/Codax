import Foundation
import Testing
@testable import Codax

@Suite(.serialized)
struct CodexProcessTests {
	@Test func launchReturnsTransportAndTracksRunningState() async throws {
		let process = makeSleepProcess()

		let returned = try await process.launchBundledCodex(arguments: ["1"])

		#expect(returned is StdioCodexTransport)
		#expect(await process.state() == .running(processIdentifier: await processIdentifier(from: process)))

		await process.terminate()
	}

	@Test func repeatedLaunchReusesExistingTransport() async throws {
		let process = makeSleepProcess()

		let first = try await process.launchBundledCodex(arguments: ["1"])
		let second = try await process.launchBundledCodex(arguments: ["1"])

		#expect((first as AnyObject) === (second as AnyObject))

		await process.terminate()
	}

	@Test func launchFailureSurfacesProcessErrorAndFailedLaunchState() async throws {
		let process = CodexProcess(
			executableURL: URL(fileURLWithPath: "/definitely/missing/codex"),
			baseArguments: []
		)

		do {
			_ = try await process.launchBundledCodex(arguments: [])
			#expect(Bool(false))
		} catch let error as CodexProcessError {
			guard case let .launchFailed(command, reason, snapshot) = error else {
				#expect(Bool(false))
				return
			}
			#expect(command.contains("/definitely/missing/codex"))
			#expect(!reason.isEmpty)
			#expect(snapshot == nil)
			#expect(await process.state() == .failedLaunch)
		}
	}

	@Test func launchFailureDoesNotBlockTerminationOrStateReads() async throws {
		let process = CodexProcess(
			executableURL: URL(fileURLWithPath: "/definitely/missing/codex"),
			baseArguments: []
		)

		do {
			_ = try await process.launchBundledCodex(arguments: [])
			#expect(Bool(false))
		} catch let error as CodexProcessError {
			guard case .launchFailed = error else {
				#expect(Bool(false))
				return
			}
		}

		#expect(await process.state() == .failedLaunch)
		await process.terminate()
		#expect(await process.state() == .idle)
	}

	@Test func terminateIsSafeBeforeAndAfterLaunch() async throws {
		let process = makeSleepProcess()

		await process.terminate()
		#expect(await process.state() == .idle)

		_ = try await process.launchBundledCodex(arguments: ["1"])
		await process.terminate()
		await process.terminate()

		#expect(await process.state() == .idle)
	}

	@Test func unexpectedTerminationUpdatesStateAndClosesTransport() async throws {
		let process = makeShellProcess()

		let transport = try await process.launchBundledCodex(arguments: ["printf 'boom\\n' >&2; exit 7"])

		try await waitForCondition {
			await process.state() == .exited(status: 7)
		}

		let snapshot = await process.stderrSnapshot()
		#expect(snapshot?.text.contains("boom") == true)
		#expect(snapshot?.truncated == false)

		do {
			_ = try await transport.receive()
			#expect(Bool(false))
		} catch let error as CodexTransportError {
			#expect(error == .closed)
		}
	}

	@Test func stderrSnapshotTruncatesLargeOutput() async throws {
		let command = "i=0; while [ $i -lt 400 ]; do printf 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' >&2; i=$((i+1)); done; exit 1"
		let process = makeShellProcess()

		_ = try await process.launchBundledCodex(arguments: [command])

		try await waitForCondition {
			await process.state() == .exited(status: 1)
		}

		let snapshot = await process.stderrSnapshot()
		#expect(snapshot?.text.isEmpty == false)
		#expect(snapshot?.truncated == true)
	}

	@Test func explicitTerminateKeepsStateIdleAfterAsyncExitCallback() async throws {
		let process = makeSleepProcess()
		let transport = try await process.launchBundledCodex(arguments: ["1"])

		await process.terminate()
		#expect(await process.state() == .idle)

		try await waitForCondition {
			await process.state() == .idle
		}

		do {
			_ = try await transport.receive()
			#expect(Bool(false))
		} catch let error as CodexTransportError {
			#expect(error == .closed)
		}
	}

}

private func makeShellProcess() -> CodexProcess {
	CodexProcess(
		executableURL: URL(fileURLWithPath: "/bin/sh"),
		baseArguments: ["-c"]
	)
}

private func makeSleepProcess() -> CodexProcess {
	CodexProcess(
		executableURL: URL(fileURLWithPath: "/bin/sleep"),
		baseArguments: []
	)
}

private func processIdentifier(from process: CodexProcess) async -> Int32? {
	switch await process.state() {
		case let .running(processIdentifier), let .terminating(processIdentifier):
			return processIdentifier
		default:
			return nil
	}
}
