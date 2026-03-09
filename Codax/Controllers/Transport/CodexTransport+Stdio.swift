//
//  CodexTransport+Stdio.swift
//  Codax
//
//  Created by Gale Williams on 3/7/26.
//

import Foundation

// MARK: - Concrete Implementation of the CodexTransport protocol using JSONL over STDIO

public actor StdioCodexTransport: CodexTransport {
	private let input: FileHandle
	private let output: FileHandle
	private var partialBuffer = Data()
	private var queuedMessages: [Data] = []
	private var waitingReceiver: CheckedContinuation<Data, Error>?
	private var closed = false

	public init(input: FileHandle, output: FileHandle) {
		self.input = input
		self.output = output
		output.readabilityHandler = { [weak self] handle in
			let data = handle.availableData
			Task {
				await self?.ingest(data)
			}
		}
	}

	public func send(_ message: Data) async throws {
		guard !closed else {
			throw CodexTransportError.closed
		}

		var frame = message
		if frame.last != 0x0A {
			frame.append(0x0A)
		}
		try input.write(contentsOf: frame)
	}

	public func receive() async throws -> Data {
		guard !closed else {
			throw CodexTransportError.closed
		}

		if !queuedMessages.isEmpty {
			return queuedMessages.removeFirst()
		}

		return try await withCheckedThrowingContinuation { continuation in
			waitingReceiver = continuation
		}
	}

	public func close() async {
		guard !closed else { return }
		closed = true
		output.readabilityHandler = nil
		if let waitingReceiver {
			self.waitingReceiver = nil
			waitingReceiver.resume(throwing: CodexTransportError.closed)
		}
		try? input.close()
		try? output.close()
	}

	private func ingest(_ data: Data) {
		guard !closed else { return }

		if data.isEmpty {
			if !partialBuffer.isEmpty {
				queue(partialBuffer)
				partialBuffer.removeAll(keepingCapacity: false)
			}
			if let waitingReceiver {
				self.waitingReceiver = nil
				waitingReceiver.resume(throwing: CodexTransportError.endOfStream)
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

	private func queue(_ message: Data) {
		if let waitingReceiver {
			self.waitingReceiver = nil
			waitingReceiver.resume(returning: message)
		} else {
			queuedMessages.append(message)
		}
	}
}
