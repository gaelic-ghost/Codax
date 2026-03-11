# Transport Schema Report

## Summary

The transport layer is now deliberately narrow.

It owns:

- raw `Data` send/receive/close semantics through `CodexTransport`
- stdio framing and buffering through `StdioCodexTransport`
- local `codex app-server` process launch and termination through `CodexProcess`
- local CLI discovery and compatibility probing through `CodexCLIProbe`

It does not own:

- JSON-RPC framing
- request correlation
- notification decoding
- server-request decoding or response policy
- runtime event fanout to higher layers

Those concerns now belong to `CodexConnection`, `CodexRuntimeCoordinator`, and the client-layer envelope types.

## Current Ownership

### Transport

- `CodexTransport`
  - minimal protocol: send, receive, close
- `StdioCodexTransport`
  - current actor-based stdio implementation
- `CodexTransportError`
  - transport-specific failures such as closed transport and invalid frames

### Process

- `CodexProcess`
  - launches the local CLI as `codex app-server --listen stdio://`
  - owns lifecycle state and stderr diagnostics

### Compatibility

- `CodexCLIProbe`
  - resolves the local `codex` executable
  - checks the supported version range before connect flows proceed

## Current Behavior

The transport slice is hardened around stdio JSONL framing:

- outbound messages are newline-delimited
- partial inbound reads are buffered until a full frame is available
- multiple queued frames can be drained from a single read
- clean EOF becomes end-of-stream
- EOF with a partial leftover frame is treated as an invalid frame
- concurrent `receive()` calls are rejected deterministically
- `close()` resumes waiting receivers

This is the right level of responsibility for the transport layer. It should be byte-correct and lifecycle-correct, but intentionally ignorant of JSON-RPC semantics.

## Relationship To Higher Layers

The current layer stack above transport is:

- `CodexConnection`
  - JSON-RPC routing and reply semantics
- `CodexRuntimeCoordinator`
  - runtime ownership and app-facing stream fanout
- `CodexClient`
  - typed request wrappers and protocol DTOs
- `CodaxOrchestrator`
  - app-state projection

That separation matters because earlier documentation blurred transport and runtime responsibilities. The current code no longer does.

## Current File Ownership

The current transport-facing files are:

- [`CodexTransport.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexTransport.swift)
- [`CodexTransport+Types.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexTransport+Types.swift)
- [`CodexProcess.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexProcess.swift)
- [`CodexProcess+Types.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexProcess+Types.swift)
- [`CodexCLIProbe.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexCLIProbe.swift)
- [`CodexTransport+WebSocket.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexTransport+WebSocket.swift)

`StdioCodexTransport` now lives in `CodexTransport.swift`.

## Current Gaps

- WebSocket remains present only as a placeholder/experimental area and is not the main transport path.
- The compatibility range is intentionally narrow and pinned to the currently validated CLI range.
- Transport correctness is ahead of end-user UX; for example, process launch failures are surfaced, but recovery/presentation behavior still lives higher up.

## Practical Conclusion

Transport work is no longer the main architecture gap. The main remaining gaps are higher up:

- broader client request coverage
- broader notification coverage
- real server-request response behavior
- richer orchestration and UI behavior

The transport layer should continue to stay minimal and should not absorb runtime or protocol policy concerns.
