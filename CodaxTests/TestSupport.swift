import Foundation
@testable import Codax

struct TestFailure: Error, Sendable, Equatable {
	let message: String
}

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

func makeProbe(
	versionOutput: CodexCLIProbe.CommandOutput,
	whichOutput: CodexCLIProbe.CommandOutput
) -> CodexCLIProbe {
	CodexCLIProbe { executableURL, arguments in
		switch (executableURL.path, arguments) {
			case ("/usr/bin/env", ["codex", "--version"]):
				return versionOutput
			case ("/usr/bin/which", ["codex"]):
				return whichOutput
			default:
				throw TestFailure(message: "Unexpected command: \(executableURL.path) \(arguments)")
		}
	}
}
