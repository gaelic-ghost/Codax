//
//  CodexTransport.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import Darwin
import Foundation

// MARK: - Transport Protocol

public protocol CodexTransport: Sendable {
	func send(_ message: Data) async throws
	func receive() async throws -> Data
	func close() async
}

// MARK: - Local Session Transport

public actor LocalCodexTransport: CodexTransport {
	public struct StderrSnapshot: Sendable, Equatable {
		public let text: String
		public let truncated: Bool
	}

	public enum LifecycleState: Sendable, Equatable {
		case idle
		case launching
		case running(processIdentifier: Int32?)
		case closing(processIdentifier: Int32?)
		case exited(status: Int32)
		case failedLaunch
	}

	public enum LaunchError: Error, LocalizedError, Sendable {
		case launchFailed(command: String, reason: String, stderrSnapshot: StderrSnapshot?)
		case transitionInProgress(state: LifecycleState)

		public var errorDescription: String? {
			switch self {
				case let .launchFailed(command, reason, _):
					return "Failed to launch `\(command)`: \(reason)"
				case let .transitionInProgress(state):
					return "Transport transition already in progress: \(String(describing: state))"
			}
		}
	}

	private let executableURL: URL?
	private let baseArguments: [String]
	private let maxRetainedStderrBytes: Int

	private var process: Process?
	private var stdinHandle: FileHandle?
	private var stdoutHandle: FileHandle?
	private var stderrHandle: FileHandle?

	private var partialBuffer = Data()
	private var queuedMessages: [Data] = []
	private var waitingReceiver: CheckedContinuation<Data, Error>?
	private var terminalError: CodexTransportError?
	private var lifecycleState: LifecycleState

	private var stderrBuffer = Data()
	private var stderrWasTruncated = false

	public static func launch(arguments: [String] = []) async throws -> LocalCodexTransport {
		let command = defaultLaunchCommand()
		return try await launch(
			executableURL: command.executableURL,
			baseArguments: command.arguments,
			arguments: arguments
		)
	}

	internal static func launch(
		executableURL: URL,
		baseArguments: [String],
		arguments: [String],
		maxRetainedStderrBytes: Int = 16_384
	) async throws -> LocalCodexTransport {
		let transport = LocalCodexTransport(
			executableURL: executableURL,
			baseArguments: baseArguments,
			maxRetainedStderrBytes: maxRetainedStderrBytes
		)
		try await transport.start(arguments: arguments)
		return transport
	}

	internal init(input: FileHandle, output: FileHandle) {
		self.executableURL = nil
		self.baseArguments = []
		self.maxRetainedStderrBytes = 16_384
		self.stdinHandle = input
		self.stdoutHandle = output
		self.lifecycleState = .running(processIdentifier: nil)
		installStdoutHandler(on: output)
	}

	private init(
		executableURL: URL,
		baseArguments: [String],
		maxRetainedStderrBytes: Int
	) {
		self.executableURL = executableURL
		self.baseArguments = baseArguments
		self.maxRetainedStderrBytes = maxRetainedStderrBytes
		self.lifecycleState = .idle
	}

	public func send(_ message: Data) async throws {
		guard terminalError == nil, let stdinHandle else {
			throw CodexTransportError.closed
		}

		var frame = message
		if frame.last != 0x0A {
			frame.append(0x0A)
		}
		try stdinHandle.write(contentsOf: frame)
	}

	public func receive() async throws -> Data {
		guard terminalError != .closed else {
			throw CodexTransportError.closed
		}

		if !queuedMessages.isEmpty {
			return queuedMessages.removeFirst()
		}

		if let terminalError {
			throw terminalError
		}

		guard waitingReceiver == nil else {
			throw CodexTransportError.receiveAlreadyPending
		}

		return try await withCheckedThrowingContinuation { continuation in
			waitingReceiver = continuation
		}
	}

	public func close() async {
		switch lifecycleState {
			case .idle:
				return
			case .launching, .running, .closing, .exited, .failedLaunch:
				break
		}

		let processIdentifier = process?.processIdentifier
		lifecycleState = .closing(processIdentifier: processIdentifier)

		let process = self.process
		if let process {
			process.terminationHandler = nil
		}

		let stderrHandle = self.stderrHandle
		clearReadabilityHandlers()
		if let stderrHandle {
			drainStandardError(from: stderrHandle)
		}

		if let process, process.isRunning {
			process.terminate()
			await waitForProcessExit(process)
		}

		finishSession(error: .closed, lifecycleState: .idle)
	}

	public func state() -> LifecycleState {
		lifecycleState
	}

	public func stderrSnapshot() -> StderrSnapshot? {
		guard !stderrBuffer.isEmpty else { return nil }
		return StderrSnapshot(
			text: String(decoding: stderrBuffer, as: UTF8.self),
			truncated: stderrWasTruncated
		)
	}
}

private extension LocalCodexTransport {
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

	func start(arguments: [String]) async throws {
		switch lifecycleState {
			case .idle, .exited, .failedLaunch:
				break
			case .launching, .closing, .running:
				throw LaunchError.transitionInProgress(state: lifecycleState)
		}

		guard let executableURL else {
			throw LaunchError.transitionInProgress(state: lifecycleState)
		}

		lifecycleState = .launching
		resetDiagnostics()

		let process = Process()
		let stdinPipe = Pipe()
		let stdoutPipe = Pipe()
		let stderrPipe = Pipe()
		let stdoutHandle = stdoutPipe.fileHandleForReading
		let stderrHandle = stderrPipe.fileHandleForReading

		process.executableURL = executableURL
		process.arguments = baseArguments + arguments
		process.standardInput = stdinPipe
		process.standardOutput = stdoutPipe
		process.standardError = stderrPipe

		self.process = process
		self.stdinHandle = stdinPipe.fileHandleForWriting
		self.stdoutHandle = stdoutHandle
		self.stderrHandle = stderrHandle

		installStdoutHandler(on: stdoutHandle)
		installStderrHandler(on: stderrHandle)
		process.terminationHandler = { [weak self] process in
			Task {
				await self?.handleTermination(of: process)
			}
		}

		do {
			try process.run()
		} catch {
			clearReadabilityHandlers()
			lifecycleState = .failedLaunch
			self.process = nil
			self.stdinHandle = nil
			self.stdoutHandle = nil
			self.stderrHandle = nil

			let command = ([executableURL.path] + baseArguments + arguments).joined(separator: " ")
			throw LaunchError.launchFailed(
				command: command,
				reason: error.localizedDescription,
				stderrSnapshot: stderrSnapshot()
			)
		}

		lifecycleState = .running(processIdentifier: process.processIdentifier)
	}

	nonisolated func installStdoutHandler(on handle: FileHandle) {
		handle.readabilityHandler = { [weak self] handle in
			let data = handle.availableData
			Task {
				await self?.ingestStandardOutput(data)
			}
		}
	}

	nonisolated func installStderrHandler(on handle: FileHandle) {
		handle.readabilityHandler = { [weak self] handle in
			let data = handle.availableData
			Task {
				await self?.ingestStandardError(data)
			}
		}
	}

	func clearReadabilityHandlers() {
		stdoutHandle?.readabilityHandler = nil
		stderrHandle?.readabilityHandler = nil
	}

	func resetDiagnostics() {
		partialBuffer.removeAll(keepingCapacity: false)
		queuedMessages.removeAll()
		terminalError = nil
		stderrBuffer.removeAll(keepingCapacity: false)
		stderrWasTruncated = false
	}

	func ingestStandardOutput(_ data: Data) {
		guard terminalError != .closed else { return }

		if data.isEmpty {
			stdoutHandle?.readabilityHandler = nil
			terminalError = partialBuffer.isEmpty ? .endOfStream : .invalidFrame
			partialBuffer.removeAll(keepingCapacity: false)

			if let waitingReceiver {
				self.waitingReceiver = nil
				waitingReceiver.resume(throwing: terminalError ?? CodexTransportError.endOfStream)
			}
			return
		}

		partialBuffer.append(data)

		while let newlineIndex = partialBuffer.firstIndex(of: 0x0A) {
			let frame = partialBuffer[..<newlineIndex]
			let remaining = partialBuffer.index(after: newlineIndex)
			partialBuffer = Data(partialBuffer[remaining...])
			if !frame.isEmpty {
				queue(Data(frame))
			}
		}
	}

	func queue(_ message: Data) {
		if let waitingReceiver {
			self.waitingReceiver = nil
			waitingReceiver.resume(returning: message)
		} else {
			queuedMessages.append(message)
		}
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
		guard self.process?.processIdentifier == process.processIdentifier else { return }
		guard case .running = lifecycleState else { return }

		lifecycleState = .closing(processIdentifier: process.processIdentifier)
		clearReadabilityHandlers()

		if let stderrHandle {
			drainStandardError(from: stderrHandle)
		}

		finishSession(
			error: .closed,
			lifecycleState: .exited(status: process.terminationStatus)
		)
	}

	func finishSession(error: CodexTransportError, lifecycleState: LifecycleState) {
		self.terminalError = error
		self.lifecycleState = lifecycleState
		queuedMessages.removeAll()
		partialBuffer.removeAll(keepingCapacity: false)

		if let waitingReceiver {
			self.waitingReceiver = nil
			waitingReceiver.resume(throwing: error)
		}

		clearReadabilityHandlers()
		try? stdinHandle?.close()
		try? stdoutHandle?.close()
		try? stderrHandle?.close()

		process = nil
		stdinHandle = nil
		stdoutHandle = nil
		stderrHandle = nil
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

// MARK: - Transport Layer Types

public enum CodexTransportError: Error, LocalizedError, Sendable, Equatable {
	case endOfStream
	case invalidFrame
	case receiveAlreadyPending
	case closed

	public var errorDescription: String? {
		switch self {
			case .endOfStream:
				return "The transport closed before another message was received."
			case .invalidFrame:
				return "The transport produced an invalid JSONL frame."
			case .receiveAlreadyPending:
				return "Only one receive operation may be pending at a time."
			case .closed:
				return "The transport is already closed."
		}
	}
}
