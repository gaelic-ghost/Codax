//
//  CodexCLIProbe.swift
//  Codax
//
//  Created by Gale Williams on 3/10/26.
//

import Foundation

public struct CodexCLIVersion: Sendable, Codable, Equatable, Comparable, CustomStringConvertible {
	public let major: Int
	public let minor: Int
	public let patch: Int

	public init(major: Int, minor: Int, patch: Int) {
		self.major = major
		self.minor = minor
		self.patch = patch
	}

	public var description: String {
		"\(major).\(minor).\(patch)"
	}

	public var displayString: String {
		description
	}

	public static func < (lhs: CodexCLIVersion, rhs: CodexCLIVersion) -> Bool {
		if lhs.major != rhs.major { return lhs.major < rhs.major }
		if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
		return lhs.patch < rhs.patch
	}
}

public enum CodexCLICompatibility: Sendable, Equatable {
	case unknown
	case checking
	case supported(version: CodexCLIVersion, path: String?)
	case unsupported(version: CodexCLIVersion?, path: String?, supportedRange: String, reason: String)
}

public struct CodexCLIProbe: Sendable {
	public typealias ExecutableResolver = @Sendable () -> String?

	public struct CommandAttemptResult: Sendable, Equatable {
		public let executablePath: String
		public let arguments: [String]
		public let status: Int32?
		public let stdout: String
		public let stderr: String
		public let errorDescription: String?

		public init(
			executablePath: String,
			arguments: [String],
			status: Int32?,
			stdout: String,
			stderr: String,
			errorDescription: String?
		) {
			self.executablePath = executablePath
			self.arguments = arguments
			self.status = status
			self.stdout = stdout
			self.stderr = stderr
			self.errorDescription = errorDescription
		}
	}

	public struct DebugSnapshot: Sendable, Equatable {
		public let inheritedPath: String?
		public let detectedCodexPath: String?
		public let compatibility: CodexCLICompatibility
		public let attempts: [CommandAttemptResult]

		public init(
			inheritedPath: String?,
			detectedCodexPath: String?,
			compatibility: CodexCLICompatibility,
			attempts: [CommandAttemptResult]
		) {
			self.inheritedPath = inheritedPath
			self.detectedCodexPath = detectedCodexPath
			self.compatibility = compatibility
			self.attempts = attempts
		}

		public var formattedDescription: String {
			var lines: [String] = []
			lines.append("Inherited PATH: \(inheritedPath ?? "<nil>")")
			lines.append("Detected codex path: \(detectedCodexPath ?? "<nil>")")
			lines.append("Compatibility: \(String(describing: compatibility))")

			for attempt in attempts {
				lines.append("")
				lines.append("$ \(attempt.executablePath) \(attempt.arguments.joined(separator: " "))")
				if let status = attempt.status {
					lines.append("status: \(status)")
				}
				if let errorDescription = attempt.errorDescription {
					lines.append("error: \(errorDescription)")
				}
				if !attempt.stdout.isEmpty {
					lines.append("stdout:")
					lines.append(attempt.stdout.trimmingCharacters(in: .newlines))
				}
				if !attempt.stderr.isEmpty {
					lines.append("stderr:")
					lines.append(attempt.stderr.trimmingCharacters(in: .newlines))
				}
			}

			return lines.joined(separator: "\n")
		}
	}

	public struct CommandOutput: Sendable, Equatable {
		public let status: Int32
		public let stdout: String
		public let stderr: String

		public init(status: Int32, stdout: String, stderr: String) {
			self.status = status
			self.stdout = stdout
			self.stderr = stderr
		}

		public var combinedText: String {
			[stderr, stdout]
				.filter { !$0.isEmpty }
				.joined(separator: "\n")
		}
	}

	public typealias CommandRunner = @Sendable (_ executableURL: URL, _ arguments: [String]) async throws -> CommandOutput

	private let runCommand: CommandRunner
	private let resolveExecutablePath: ExecutableResolver

	public init(
		runCommand: @escaping CommandRunner = Self.liveRunCommand,
		resolveExecutablePath: @escaping ExecutableResolver = Self.defaultResolveExecutablePath
	) {
		self.runCommand = runCommand
		self.resolveExecutablePath = resolveExecutablePath
	}

	public func probeCompatibility() async -> CodexCLICompatibility {
		let codexPath = detectCodexPath()
		let command = versionCommand(for: codexPath)

		do {
			let output = try await runCommand(command.executableURL, command.arguments)
			let text = output.combinedText
			guard let version = Self.parseFirstSemanticVersion(in: text) else {
				return .unsupported(
					version: nil,
					path: codexPath,
					supportedRange: Self.supportedRangeDescription,
					reason: "Could not parse a supported Codex CLI version from `codex --version` output."
				)
			}

			guard Self.isSupported(version: version) else {
				return .unsupported(
					version: version,
					path: codexPath,
					supportedRange: Self.supportedRangeDescription,
					reason: "Codax currently supports Codex CLI \(Self.supportedRangeDescription) only."
				)
			}

			return .supported(version: version, path: codexPath)
		} catch {
			return .unsupported(
				version: nil,
				path: codexPath,
				supportedRange: Self.supportedRangeDescription,
				reason: codexPath == nil
					? "Could not find `codex` in the inherited PATH or the supported Homebrew/npm/pnpm install locations."
					: "Could not run `\(codexPath!) --version`: \(error.localizedDescription)"
			)
		}
	}

	public func debugProbeCompatibility() async -> DebugSnapshot {
		let codexPath = detectCodexPath()
		var attempts: [CommandAttemptResult] = []

		let envAttempt = await runAttempt(
			executableURL: URL(fileURLWithPath: "/usr/bin/env"),
			arguments: ["codex", "--version"]
		)
		attempts.append(envAttempt)

		for candidate in Self.debugCandidatePaths(resolvedPath: codexPath) {
			attempts.append(
				await runAttempt(
					executableURL: URL(fileURLWithPath: candidate),
					arguments: ["--version"]
				)
			)
		}

		let compatibility = await probeCompatibility()
		return DebugSnapshot(
			inheritedPath: ProcessInfo.processInfo.environment["PATH"],
			detectedCodexPath: codexPath,
			compatibility: compatibility,
			attempts: attempts
		)
	}
}

extension CodexCLIProbe {
	static let supportedRangeDescription = "0.111.x and 0.112.x"

	static func isSupported(version: CodexCLIVersion) -> Bool {
		version.major == 0 && (version.minor == 111 || version.minor == 112)
	}

	static func parseFirstSemanticVersion(in text: String) -> CodexCLIVersion? {
		let pattern = #"\b(\d+)\.(\d+)\.(\d+)\b"#
		guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
		let range = NSRange(text.startIndex..<text.endIndex, in: text)
		guard let match = regex.firstMatch(in: text, options: [], range: range) else { return nil }

		func intValue(at index: Int) -> Int? {
			let capture = match.range(at: index)
			guard let swiftRange = Range(capture, in: text) else { return nil }
			return Int(text[swiftRange])
		}

		guard
			let major = intValue(at: 1),
			let minor = intValue(at: 2),
			let patch = intValue(at: 3)
		else {
			return nil
		}

		return CodexCLIVersion(major: major, minor: minor, patch: patch)
	}

	public static func defaultResolveExecutablePath() -> String? {
		resolvedExecutablePath()
	}

	static func resolvedExecutablePath(
		environment: [String: String] = ProcessInfo.processInfo.environment,
		homeDirectoryPath: String = NSHomeDirectory(),
		isExecutableFile: @escaping @Sendable (String) -> Bool = { FileManager.default.isExecutableFile(atPath: $0) },
		directoryEntries: @escaping @Sendable (String) -> [String] = { path in
			(try? FileManager.default.contentsOfDirectory(atPath: path)) ?? []
		}
	) -> String? {
		for candidate in executableCandidates(
			environment: environment,
			homeDirectoryPath: homeDirectoryPath,
			directoryEntries: directoryEntries
		) where isExecutableFile(candidate) {
			return candidate
		}
		return nil
	}

	static func executableCandidates(
		environment: [String: String] = ProcessInfo.processInfo.environment,
		homeDirectoryPath: String = NSHomeDirectory(),
		directoryEntries: @escaping @Sendable (String) -> [String] = { path in
			(try? FileManager.default.contentsOfDirectory(atPath: path)) ?? []
		}
	) -> [String] {
		var candidates: [String] = []
		var seen = Set<String>()

		func append(_ path: String) {
			guard seen.insert(path).inserted else { return }
			candidates.append(path)
		}

		if let path = environment["PATH"] {
			for directory in path.split(separator: ":").map(String.init) where !directory.isEmpty {
				append((directory as NSString).appendingPathComponent("codex"))
			}
		}

		for directory in [
			"/opt/homebrew/bin",
			"/usr/local/bin",
			(homeDirectoryPath as NSString).appendingPathComponent("Library/pnpm"),
			(homeDirectoryPath as NSString).appendingPathComponent(".local/share/pnpm"),
			(homeDirectoryPath as NSString).appendingPathComponent(".npm-global/bin"),
			(homeDirectoryPath as NSString).appendingPathComponent(".volta/bin"),
		] {
			append((directory as NSString).appendingPathComponent("codex"))
		}

		let nvmVersionsDirectory = (homeDirectoryPath as NSString).appendingPathComponent(".nvm/versions/node")
		for versionDirectory in directoryEntries(nvmVersionsDirectory).sorted(by: >) {
			let candidate = ((nvmVersionsDirectory as NSString).appendingPathComponent(versionDirectory) as NSString)
				.appendingPathComponent("bin/codex")
			append(candidate)
		}

		return candidates
	}

	private func detectCodexPath() -> String? {
		resolveExecutablePath()
	}

	private func versionCommand(for resolvedExecutablePath: String?) -> (executableURL: URL, arguments: [String]) {
		if let resolvedExecutablePath {
			return (URL(fileURLWithPath: resolvedExecutablePath), ["--version"])
		}

		return (URL(fileURLWithPath: "/usr/bin/env"), ["codex", "--version"])
	}

	static func debugCandidatePaths(resolvedPath: String?) -> [String] {
		var candidates: [String] = []
		var seen = Set<String>()

		func append(_ path: String) {
			guard seen.insert(path).inserted else { return }
			candidates.append(path)
		}

		if let resolvedPath {
			append(resolvedPath)
		}
		append("/opt/homebrew/bin/codex")
		append("/usr/local/bin/codex")
		append((NSHomeDirectory() as NSString).appendingPathComponent("Library/pnpm/codex"))
		append((NSHomeDirectory() as NSString).appendingPathComponent(".local/share/pnpm/codex"))
		append((NSHomeDirectory() as NSString).appendingPathComponent(".npm-global/bin/codex"))
		append((NSHomeDirectory() as NSString).appendingPathComponent(".volta/bin/codex"))
		return candidates
	}

	private func runAttempt(executableURL: URL, arguments: [String]) async -> CommandAttemptResult {
		do {
			let output = try await runCommand(executableURL, arguments)
			return CommandAttemptResult(
				executablePath: executableURL.path,
				arguments: arguments,
				status: output.status,
				stdout: output.stdout,
				stderr: output.stderr,
				errorDescription: nil
			)
		} catch {
			return CommandAttemptResult(
				executablePath: executableURL.path,
				arguments: arguments,
				status: nil,
				stdout: "",
				stderr: "",
				errorDescription: error.localizedDescription
			)
		}
	}

	public static func liveRunCommand(executableURL: URL, arguments: [String]) async throws -> CommandOutput {
		try await withCheckedThrowingContinuation { continuation in
			let process = Process()
			let stdoutPipe = Pipe()
			let stderrPipe = Pipe()

			process.executableURL = executableURL
			process.arguments = arguments
			process.standardOutput = stdoutPipe
			process.standardError = stderrPipe

			process.terminationHandler = { process in
				let stdout = String(decoding: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
				let stderr = String(decoding: stderrPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
				continuation.resume(returning: CommandOutput(status: process.terminationStatus, stdout: stdout, stderr: stderr))
			}

			do {
				try process.run()
			} catch {
				continuation.resume(throwing: error)
			}
		}
	}
}
