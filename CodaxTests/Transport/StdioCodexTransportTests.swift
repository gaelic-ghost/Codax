import Foundation
import Testing
@testable import Codax

struct StdioCodexTransportTests {
	@Test func sendAppendsTrailingNewline() async throws {
		let inbound = Pipe()
		let outbound = Pipe()
		let transport = StdioCodexTransport(
			input: inbound.fileHandleForWriting,
			output: outbound.fileHandleForReading
		)

		try await transport.send(Data("{\"ok\":true}".utf8))

		let sent = inbound.fileHandleForReading.readData(ofLength: 12)
		#expect(sent == Data("{\"ok\":true}\n".utf8))

		await transport.close()
	}

	@Test func sendPreservesExistingTrailingNewline() async throws {
		let inbound = Pipe()
		let outbound = Pipe()
		let transport = StdioCodexTransport(
			input: inbound.fileHandleForWriting,
			output: outbound.fileHandleForReading
		)

		try await transport.send(Data("hello\n".utf8))

		let sent = inbound.fileHandleForReading.readData(ofLength: 6)
		#expect(sent == Data("hello\n".utf8))

		await transport.close()
	}

	@Test func receiveAssemblesFrameAcrossPartialReads() async throws {
		let inbound = Pipe()
		let outbound = Pipe()
		let transport = StdioCodexTransport(
			input: inbound.fileHandleForWriting,
			output: outbound.fileHandleForReading
		)

		let task = Task {
			try await transport.receive()
		}

		try outbound.fileHandleForWriting.write(contentsOf: Data("{\"a\":".utf8))
		try outbound.fileHandleForWriting.write(contentsOf: Data("1}\n".utf8))

		let received = try await task.value
		#expect(received == Data("{\"a\":1}".utf8))

		await transport.close()
	}

	@Test func receiveQueuesMultipleFramesFromSingleRead() async throws {
		let inbound = Pipe()
		let outbound = Pipe()
		let transport = StdioCodexTransport(
			input: inbound.fileHandleForWriting,
			output: outbound.fileHandleForReading
		)

		try outbound.fileHandleForWriting.write(contentsOf: Data("one\ntwo\n".utf8))

		#expect(try await transport.receive() == Data("one".utf8))
		#expect(try await transport.receive() == Data("two".utf8))

		await transport.close()
	}

	@Test func receiveIgnoresEmptyFrames() async throws {
		let inbound = Pipe()
		let outbound = Pipe()
		let transport = StdioCodexTransport(
			input: inbound.fileHandleForWriting,
			output: outbound.fileHandleForReading
		)

		let task = Task {
			try await transport.receive()
		}

		try outbound.fileHandleForWriting.write(contentsOf: Data("\nvalue\n".utf8))

		#expect(try await task.value == Data("value".utf8))

		await transport.close()
	}

	@Test func receiveThrowsClosedAfterClose() async throws {
		let inbound = Pipe()
		let outbound = Pipe()
		let transport = StdioCodexTransport(
			input: inbound.fileHandleForWriting,
			output: outbound.fileHandleForReading
		)

		await transport.close()

		do {
			_ = try await transport.receive()
			#expect(Bool(false))
		} catch let error as CodexTransportError {
			#expect(error == .closed)
		}
	}

	@Test func sendThrowsClosedAfterClose() async throws {
		let inbound = Pipe()
		let outbound = Pipe()
		let transport = StdioCodexTransport(
			input: inbound.fileHandleForWriting,
			output: outbound.fileHandleForReading
		)

		await transport.close()

		do {
			try await transport.send(Data("hello".utf8))
			#expect(Bool(false))
		} catch let error as CodexTransportError {
			#expect(error == .closed)
		}
	}

	@Test func closeResumesWaitingReceiver() async throws {
		let inbound = Pipe()
		let outbound = Pipe()
		let transport = StdioCodexTransport(
			input: inbound.fileHandleForWriting,
			output: outbound.fileHandleForReading
		)

		let task: Task<Error?, Never> = Task {
			do {
				_ = try await transport.receive()
				return nil
			} catch {
				return error
			}
		}

		await transport.close()

		let result = await task.value
		guard let error = result as? CodexTransportError else {
			#expect(Bool(false))
			return
		}
		#expect(error == .closed)
	}

	@Test func eofWithLeftoverPartialBufferIsInvalidFrame() async throws {
		let inbound = Pipe()
		let outbound = Pipe()
		let transport = StdioCodexTransport(
			input: inbound.fileHandleForWriting,
			output: outbound.fileHandleForReading
		)

		let task: Task<Error?, Never> = Task {
			do {
				_ = try await transport.receive()
				return nil
			} catch {
				return error
			}
		}

		try outbound.fileHandleForWriting.write(contentsOf: Data("partial".utf8))
		try outbound.fileHandleForWriting.close()

		let result = await task.value
		guard let error = result as? CodexTransportError else {
			#expect(Bool(false))
			return
		}
		#expect(error == .invalidFrame)
	}

	@Test func cleanEofWithoutPendingFrameIsEndOfStream() async throws {
		let inbound = Pipe()
		let outbound = Pipe()
		let transport = StdioCodexTransport(
			input: inbound.fileHandleForWriting,
			output: outbound.fileHandleForReading
		)

		let task: Task<Error?, Never> = Task {
			do {
				_ = try await transport.receive()
				return nil
			} catch {
				return error
			}
		}

		try outbound.fileHandleForWriting.close()

		let result = await task.value
		guard let error = result as? CodexTransportError else {
			#expect(Bool(false))
			return
		}
		#expect(error == .endOfStream)
	}

	@Test func concurrentReceiveThrowsReceiveAlreadyPending() async throws {
		let inbound = Pipe()
		let outbound = Pipe()
		let transport = StdioCodexTransport(
			input: inbound.fileHandleForWriting,
			output: outbound.fileHandleForReading
		)

		let first: Task<Error?, Never> = Task {
			do {
				_ = try await transport.receive()
				return nil
			} catch {
				return error
			}
		}

		try await waitForCondition {
			do {
				_ = try await transport.receive()
				return false
			} catch let error as CodexTransportError {
				return error == .receiveAlreadyPending
			} catch {
				return false
			}
		}

		await transport.close()
		_ = await first.value
	}
}
