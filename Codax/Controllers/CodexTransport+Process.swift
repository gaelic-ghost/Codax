//
//  CodexTransport+Process.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import Foundation

public actor CodexProcess {
	private var process: Process?
	private var transport: (any CodexTransport)?

	public func launchBundledCodex(arguments: [String]) async throws -> any CodexTransport {
		if let transport {
			return transport
		}

		let process = Process()
		let stdinPipe = Pipe()
		let stdoutPipe = Pipe()

		process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
		process.arguments = ["codex", "app-server", "--listen", "stdio://"] + arguments
		process.standardInput = stdinPipe
		process.standardOutput = stdoutPipe
		process.standardError = FileHandle.standardError
		try process.run()

		let transport = StdioCodexTransport(
			input: stdinPipe.fileHandleForWriting,
			output: stdoutPipe.fileHandleForReading
		)

		self.process = process
		self.transport = transport
		return transport
	}

	public func terminate() async -> () {
		await transport?.close()
		process?.terminate()
		process = nil
		transport = nil
	}
}
