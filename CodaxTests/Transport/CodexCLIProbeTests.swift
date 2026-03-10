import Foundation
import Testing
@testable import Codax

struct CodexCLIProbeTests {
	@Test func parsesSupportedVersionsFromPlainOutput() async throws {
		#expect(
			CodexCLIProbe.parseFirstSemanticVersion(in: "codex-cli 0.111.4") ==
			CodexCLIVersion(major: 0, minor: 111, patch: 4)
		)
		#expect(
			CodexCLIProbe.parseFirstSemanticVersion(in: "codex-cli 0.112.0") ==
			CodexCLIVersion(major: 0, minor: 112, patch: 0)
		)
	}

	@Test func parsesVersionFromNoisyOutput() async throws {
		let output = """
		WARNING: proceeding, even though we could not update PATH: Operation not permitted (os error 1)
		codex-cli 0.112.0
		"""
		#expect(
			CodexCLIProbe.parseFirstSemanticVersion(in: output) ==
			CodexCLIVersion(major: 0, minor: 112, patch: 0)
		)
	}

	@Test func probeReportsSupportedCompatibility() async throws {
		let probe = makeProbe(
			versionOutput: .init(status: 0, stdout: "codex-cli 0.112.0\n", stderr: ""),
			resolvedPath: "/usr/local/bin/codex"
		)

		let compatibility = await probe.probeCompatibility()
		#expect(
			compatibility ==
			.supported(
				version: CodexCLIVersion(major: 0, minor: 112, patch: 0),
				path: "/usr/local/bin/codex"
			)
		)
	}

	@Test func probeReportsUnsupportedVersion() async throws {
		let probe = makeProbe(
			versionOutput: .init(status: 0, stdout: "codex-cli 0.113.0\n", stderr: ""),
			resolvedPath: "/opt/homebrew/bin/codex"
		)

		let compatibility = await probe.probeCompatibility()
		guard case let .unsupported(version, path, supportedRange, reason) = compatibility else {
			#expect(Bool(false))
			return
		}

		#expect(version == CodexCLIVersion(major: 0, minor: 113, patch: 0))
		#expect(path == "/opt/homebrew/bin/codex")
		#expect(supportedRange == "0.111.x and 0.112.x")
		#expect(reason.contains("supports Codex CLI"))
	}

	@Test func probeRejectsUnparseableVersionOutput() async throws {
		let probe = makeProbe(
			versionOutput: .init(status: 0, stdout: "codex-cli version unknown\n", stderr: ""),
			resolvedPath: "/usr/local/bin/codex"
		)

		let compatibility = await probe.probeCompatibility()
		guard case let .unsupported(version, path, supportedRange, reason) = compatibility else {
			#expect(Bool(false))
			return
		}

		#expect(version == nil)
		#expect(path == "/usr/local/bin/codex")
		#expect(supportedRange == "0.111.x and 0.112.x")
		#expect(reason.contains("Could not parse"))
	}

	@Test func probeRejectsMissingCodexCommand() async throws {
		let probe = CodexCLIProbe(
			runCommand: { _, _ in
				throw NSError(
					domain: "CodaxTests",
					code: 1,
					userInfo: [NSLocalizedDescriptionKey: "No such file or directory"]
				)
			},
			resolveExecutablePath: { nil }
		)

		let compatibility = await probe.probeCompatibility()
		guard case let .unsupported(version, path, supportedRange, reason) = compatibility else {
			#expect(Bool(false))
			return
		}

		#expect(version == nil)
		#expect(path == nil)
		#expect(supportedRange == "0.111.x and 0.112.x")
		#expect(reason.contains("Could not find `codex`"))
	}

	@Test func debugProbeCompatibilityCapturesEnvAndDirectPathAttempts() async throws {
		let probe = CodexCLIProbe(
			runCommand: { executableURL, arguments in
				switch (executableURL.path, arguments) {
				case ("/usr/bin/env", ["codex", "--version"]):
					throw NSError(
						domain: "CodaxTests",
						code: 1,
						userInfo: [NSLocalizedDescriptionKey: "No such file or directory"]
					)
				case ("/opt/homebrew/bin/codex", ["--version"]):
					return .init(status: 0, stdout: "codex-cli 0.112.0\n", stderr: "")
				case ("/usr/local/bin/codex", ["--version"]):
					throw NSError(
						domain: "CodaxTests",
						code: 13,
						userInfo: [NSLocalizedDescriptionKey: "Permission denied"]
					)
				default:
					throw TestFailure(message: "Unexpected command: \(executableURL.path) \(arguments)")
				}
			},
			resolveExecutablePath: { "/opt/homebrew/bin/codex" }
		)

		let snapshot = await probe.debugProbeCompatibility()

		#expect(snapshot.detectedCodexPath == "/opt/homebrew/bin/codex")
		#expect(snapshot.attempts.count >= 3)
		#expect(snapshot.attempts[0].executablePath == "/usr/bin/env")
		#expect(snapshot.attempts[0].errorDescription?.contains("No such file") == true)
		#expect(snapshot.attempts[1].executablePath == "/opt/homebrew/bin/codex")
		#expect(snapshot.attempts[1].stdout.contains("0.112.0"))
		#expect(snapshot.attempts.contains { $0.executablePath == "/usr/local/bin/codex" })
		#expect(snapshot.attempts.contains {
			$0.executablePath == "/usr/local/bin/codex" &&
			($0.errorDescription?.contains("Permission denied") == true)
		})
		#expect(snapshot.formattedDescription.contains("/opt/homebrew/bin/codex"))
	}

	@Test func resolvedExecutablePathFindsHomebrewPnpmAndNpmCandidatesWithoutHardcodedUsername() throws {
		let homeDirectoryPath = "/Users/example-user"
		let resolved = CodexCLIProbe.resolvedExecutablePath(
			environment: ["PATH": "/usr/bin:/bin"],
			homeDirectoryPath: homeDirectoryPath,
			isExecutableFile: { path in
				path == "/Users/example-user/.npm-global/bin/codex"
			},
			directoryEntries: { _ in [] }
		)

		#expect(resolved == "/Users/example-user/.npm-global/bin/codex")

		let candidates = CodexCLIProbe.executableCandidates(
			environment: ["PATH": "/usr/bin:/bin"],
			homeDirectoryPath: homeDirectoryPath,
			directoryEntries: { path in
				if path == "/Users/example-user/.nvm/versions/node" {
					return ["v22.0.0", "v20.18.1"]
				}
				return []
			}
		)

		#expect(candidates.contains("/opt/homebrew/bin/codex"))
		#expect(candidates.contains("/usr/local/bin/codex"))
		#expect(candidates.contains("/Users/example-user/Library/pnpm/codex"))
		#expect(candidates.contains("/Users/example-user/.local/share/pnpm/codex"))
		#expect(candidates.contains("/Users/example-user/.npm-global/bin/codex"))
		#expect(candidates.contains("/Users/example-user/.volta/bin/codex"))
		#expect(candidates.contains("/Users/example-user/.nvm/versions/node/v22.0.0/bin/codex"))
	}
}
