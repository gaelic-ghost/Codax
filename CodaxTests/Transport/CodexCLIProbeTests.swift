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
			whichOutput: .init(status: 0, stdout: "/usr/local/bin/codex\n", stderr: "")
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
			whichOutput: .init(status: 0, stdout: "/opt/homebrew/bin/codex\n", stderr: "")
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
			whichOutput: .init(status: 0, stdout: "/usr/local/bin/codex\n", stderr: "")
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
		let probe = CodexCLIProbe { executableURL, arguments in
			if executableURL.path == "/usr/bin/which" && arguments == ["codex"] {
				return .init(status: 1, stdout: "", stderr: "")
			}

			throw NSError(
				domain: "CodaxTests",
				code: 1,
				userInfo: [NSLocalizedDescriptionKey: "No such file or directory"]
			)
		}

		let compatibility = await probe.probeCompatibility()
		guard case let .unsupported(version, path, supportedRange, reason) = compatibility else {
			#expect(Bool(false))
			return
		}

		#expect(version == nil)
		#expect(path == nil)
		#expect(supportedRange == "0.111.x and 0.112.x")
		#expect(reason.contains("Could not run"))
	}
}
