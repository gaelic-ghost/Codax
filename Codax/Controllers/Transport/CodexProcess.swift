//
//  CodexProcess.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import Darwin
import Foundation

	// MARK: - Manager for local Codex process

public actor CodexProcess {
	typealias StdioTransportFactory = @Sendable (FileHandle, FileHandle) -> StdioCodexTransport

	private enum Phase: Sendable, Equatable {
		case idle
		case launching
		case running(processIdentifier: Int32?)
		case terminating(processIdentifier: Int32?)
		case exited(status: Int32)
		case failedLaunch
	}

	private let executableURL: URL
	private let baseArguments: [String]
	private let makeStdioTransport: StdioTransportFactory

	private var process: Process?
	private var transport: StdioCodexTransport?
	private var standardErrorHandle: FileHandle?
	private var phase: Phase = .idle
	private var lifecycleState: CodexProcessLifecycleState = .idle
	private var stderrBuffer = Data()
	private var stderrWasTruncated = false
	private let maxRetainedStderrBytes = 16_384

	public init() {
		let launchCommand = Self.defaultLaunchCommand()
		self.executableURL = launchCommand.executableURL
		self.baseArguments = launchCommand.arguments
		self.makeStdioTransport = { input, output in
			StdioCodexTransport(input: input, output: output)
		}
	}

	internal init(
		executableURL: URL,
		baseArguments: [String],
		makeStdioTransport: @escaping StdioTransportFactory = { input, output in
			StdioCodexTransport(input: input, output: output)
		}
	) {
		self.executableURL = executableURL
		self.baseArguments = baseArguments
		self.makeStdioTransport = makeStdioTransport
	}

	// TODO: Rename to launchLocalCodex(arguments: [String])
	public func launchBundledCodex(arguments: [String]) async throws -> any CodexTransport {
		switch phase {
			case .running:
				if let transport {
					return transport
				}
			case .launching, .terminating:
				throw CodexProcessError.transitionInProgress(state: lifecycleState)
			case .idle, .exited, .failedLaunch:
				break
		}

		phase = .launching
		lifecycleState = .launching
		resetDiagnostics()

		let process = Process()
		let stdinPipe = Pipe()
		let stdoutPipe = Pipe()
		let stderrPipe = Pipe()
		let stderrHandle = stderrPipe.fileHandleForReading

		process.executableURL = executableURL
		process.arguments = baseArguments + arguments
		process.standardInput = stdinPipe
		process.standardOutput = stdoutPipe
		process.standardError = stderrPipe

		self.process = process
		standardErrorHandle = stderrHandle

		stderrHandle.readabilityHandler = { [weak self] handle in
			let data = handle.availableData
			Task {
				await self?.ingestStandardError(data)
			}
		}
		process.terminationHandler = { [weak self] process in
			Task {
				await self?.handleTermination(of: process)
			}
		}

			do {
				try process.run()
			} catch {
				stderrHandle.readabilityHandler = nil
				phase = .failedLaunch
				lifecycleState = .failedLaunch
				self.process = nil
				self.transport = nil
				standardErrorHandle = nil
				let command = ([executableURL.path] + baseArguments + arguments).joined(separator: " ")
				throw CodexProcessError.launchFailed(
					command: command,
					reason: error.localizedDescription,
					stderrSnapshot: stderrSnapshot()
			)
		}

		let transport = makeStdioTransport(
			stdinPipe.fileHandleForWriting,
			stdoutPipe.fileHandleForReading
		)

		self.transport = transport
		phase = .running(processIdentifier: process.processIdentifier)
		lifecycleState = .running(processIdentifier: process.processIdentifier)
		return transport
	}

	public func terminate() async {
		switch phase {
			case .idle, .failedLaunch:
				clearRetainedResources()
				phase = .idle
				lifecycleState = .idle
				return
			case .exited:
				clearRetainedResources()
				phase = .idle
				lifecycleState = .idle
				return
			case .launching, .running:
				break
			case .terminating:
				return
		}

		let processIdentifier = process?.processIdentifier
		phase = .terminating(processIdentifier: processIdentifier)
		lifecycleState = .terminating(processIdentifier: processIdentifier)

		let process = self.process
		let transport = self.transport
		let stderrHandle = standardErrorHandle
		self.process = nil
		self.transport = nil
		standardErrorHandle = nil

		process?.terminationHandler = nil
		stderrHandle?.readabilityHandler = nil
		await transport?.close()
		if let process, process.isRunning {
			process.terminate()
			await waitForProcessExit(process)
		}
		if let stderrHandle {
			drainStandardError(from: stderrHandle)
		}

		phase = .idle
		lifecycleState = .idle
	}

	public func state() -> CodexProcessLifecycleState {
		lifecycleState
	}

	public func stderrSnapshot() -> CodexProcessStderrSnapshot? {
		guard !stderrBuffer.isEmpty else { return nil }
		return CodexProcessStderrSnapshot(
			text: String(decoding: stderrBuffer, as: UTF8.self),
			truncated: stderrWasTruncated
		)
	}
}

private extension CodexProcess {
	static func defaultLaunchCommand() -> (executableURL: URL, arguments: [String]) {
		if let resolvedExecutablePath = CodexCLIProbe.defaultResolveExecutablePath() {
			return (
				URL(fileURLWithPath: resolvedExecutablePath),
				["app-server", "--listen", "stdio://"]
			)
		}

		return (
			URL(fileURLWithPath: "/usr/bin/env"),
			["codex", "app-server", "--listen", "stdio://"]
		)
	}

	func resetDiagnostics() {
		stderrBuffer.removeAll(keepingCapacity: false)
		stderrWasTruncated = false
	}

	func clearRetainedResources() {
		process?.terminationHandler = nil
		standardErrorHandle?.readabilityHandler = nil
		process = nil
		transport = nil
		standardErrorHandle = nil
	}

	func ingestStandardError(_ data: Data) {
		guard !data.isEmpty else { return }
		stderrBuffer.append(data)
		if stderrBuffer.count > maxRetainedStderrBytes {
			let overflow = stderrBuffer.count - maxRetainedStderrBytes
			stderrBuffer.removeFirst(overflow)
			stderrWasTruncated = true
		}
	}

	func handleTermination(of process: Process) async {
		guard self.process?.processIdentifier == process.processIdentifier else {
			return
		}
		guard case .running = phase else {
			return
		}

		phase = .terminating(processIdentifier: process.processIdentifier)
		lifecycleState = .terminating(processIdentifier: process.processIdentifier)

		let transport = self.transport
		let stderrHandle = standardErrorHandle
		self.process = nil
		self.transport = nil
		standardErrorHandle = nil

		stderrHandle?.readabilityHandler = nil
		if let stderrHandle {
			drainStandardError(from: stderrHandle)
		}
		await transport?.close()

		phase = .exited(status: process.terminationStatus)
		lifecycleState = .exited(status: process.terminationStatus)
	}

	func drainStandardError(from handle: FileHandle) {
		while true {
			let data = handle.availableData
			if data.isEmpty {
				return
			}
			ingestStandardError(data)
		}
	}

	func waitForProcessExit(
		_ process: Process,
		timeoutNanoseconds: UInt64 = 1_000_000_000,
		pollIntervalNanoseconds: UInt64 = 10_000_000
	) async {
		let iterations = max(1, Int(timeoutNanoseconds / max(1, pollIntervalNanoseconds)))
		for _ in 0..<iterations {
			if !process.isRunning {
				return
			}
			try? await Task.sleep(nanoseconds: pollIntervalNanoseconds)
		}

		if process.isRunning {
			kill(process.processIdentifier, SIGKILL)
		}

		while process.isRunning {
			try? await Task.sleep(nanoseconds: pollIntervalNanoseconds)
		}
	}
}
