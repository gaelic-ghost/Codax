import Foundation
import Testing
@testable import Codax

@Suite(.serialized)
struct LocalCodexTransportTests {
	@Test func sendAppendsTrailingNewline() async throws {
		let inbound = Pipe()
		let outbound = Pipe()
		let transport = LocalCodexTransport(
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
		let transport = LocalCodexTransport(
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
		let transport = LocalCodexTransport(
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
		let transport = LocalCodexTransport(
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
		let transport = LocalCodexTransport(
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
		let transport = LocalCodexTransport(
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
		let transport = LocalCodexTransport(
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
		let transport = LocalCodexTransport(
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
		let transport = LocalCodexTransport(
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
		let transport = LocalCodexTransport(
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
		let transport = LocalCodexTransport(
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

		var secondReceiveError: CodexTransportError?
		for _ in 0..<10 {
			await Task.yield()
			do {
				_ = try await transport.receive()
				#expect(Bool(false))
			} catch let error as CodexTransportError {
				if error == .receiveAlreadyPending {
					secondReceiveError = error
					break
				}
			} catch {
				#expect(Bool(false))
			}
		}
		#expect(secondReceiveError == .receiveAlreadyPending)

		await transport.close()
		_ = await first.value
	}

	@Test func launchTracksRunningStateAndCloseReturnsIdle() async throws {
		let transport = try await LocalCodexTransport.launch(
			executableURL: URL(fileURLWithPath: "/bin/sleep"),
			baseArguments: [],
			arguments: ["1"]
		)

		guard case let .running(processIdentifier) = await transport.state() else {
			#expect(Bool(false))
			return
		}
		#expect(processIdentifier != nil)

		await transport.close()
		#expect(await transport.state() == .idle)
	}

	@Test func launchFailureSurfacesLaunchErrorAndFailedState() async throws {
		do {
			_ = try await LocalCodexTransport.launch(
				executableURL: URL(fileURLWithPath: "/definitely/missing/codex"),
				baseArguments: [],
				arguments: []
			)
			#expect(Bool(false))
		} catch let error as LocalCodexTransport.LaunchError {
			guard case let .launchFailed(command, reason, snapshot, debugSnapshot) = error else {
				#expect(Bool(false))
				return
			}
			#expect(command.contains("/definitely/missing/codex"))
			#expect(!reason.isEmpty)
			#expect(snapshot == nil)
			#expect(debugSnapshot != nil)
		}
	}

	@Test func terminationCapturesStderrAndClosesTransport() async throws {
		let transport = try await LocalCodexTransport.launch(
			executableURL: URL(fileURLWithPath: "/bin/sh"),
			baseArguments: ["-c"],
			arguments: ["printf 'boom\\n' >&2; exit 7"]
		)

		try await waitForCondition {
			await transport.state() == .exited(status: 7)
		}

		let snapshot = await transport.stderrSnapshot()
		#expect(snapshot?.text.contains("boom") == true)
		#expect(snapshot?.truncated == false)

		do {
			_ = try await transport.receive()
			#expect(Bool(false))
		} catch let error as CodexTransportError {
			#expect(error == .closed)
		}
	}

	@Test func stderrSnapshotTruncatesLargeOutput() async throws {
		let command = "i=0; while [ $i -lt 400 ]; do printf 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' >&2; i=$((i+1)); done; exit 1"
		let transport = try await LocalCodexTransport.launch(
			executableURL: URL(fileURLWithPath: "/bin/sh"),
			baseArguments: ["-c"],
			arguments: [command]
		)

		try await waitForCondition {
			await transport.state() == .exited(status: 1)
		}

		let snapshot = await transport.stderrSnapshot()
		#expect(snapshot?.text.isEmpty == false)
		#expect(snapshot?.truncated == true)
	}
}
