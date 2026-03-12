import Foundation
@testable import Codax

// MARK: - Test Errors

struct TestFailure: Error, Sendable, Equatable {
	let message: String
}

// MARK: - Async Helpers

func waitForCondition(
	timeoutNanoseconds: UInt64 = 1_000_000_000,
	pollIntervalNanoseconds: UInt64 = 10_000_000,
	condition: @escaping @Sendable () async -> Bool
) async throws {
	let iterations = max(1, Int(timeoutNanoseconds / max(1, pollIntervalNanoseconds)))
	for _ in 0..<iterations {
		if await condition() {
			return
		}
		try await Task.sleep(nanoseconds: pollIntervalNanoseconds)
	}
	throw TestFailure(message: "Timed out waiting for condition.")
}

// MARK: - Probe Helpers

func makeProbe(
	versionOutput: CodexCLIProbe.CommandOutput,
	resolvedPath: String? = "/usr/local/bin/codex"
) -> CodexCLIProbe {
	CodexCLIProbe(
		runCommand: { executableURL, arguments in
			switch (executableURL.path, arguments) {
				case let (path, ["--version"]) where path == resolvedPath:
					return versionOutput
				case ("/usr/bin/env", ["codex", "--version"]) where resolvedPath == nil:
					return versionOutput
				default:
					throw TestFailure(message: "Unexpected command: \(executableURL.path) \(arguments)")
			}
		},
		resolveExecutablePath: {
			resolvedPath
		}
	)
}
