# Codax

An accessibility-forward native macOS Codex client that uses your local `codex app-server` over stdio.

Codax is still early alpha, but the protocol-facing layers are now real enough that the repo should be read as an actively evolving native client, not just a shell around placeholder architecture.

## What Exists Today

Codax currently has working foundations for:

- local Codex process launch and stdio transport
- JSON-RPC request/response routing with retry handling for retryable overloads
- a typed client layer for the currently implemented app-server methods
- a runtime coordinator that owns process, connection, client, notification forwarding, and server-request observation
- an app-facing orchestrator that projects typed runtime events into SwiftUI state
- an early `NavigationSplitView` shell backed by shared orchestrator state

The app is still incomplete:

- the ChatGPT login flow is still a placeholder
- the UI shell is transitional and needs broader state handling, polish, and accessibility work
- request coverage and notification coverage are both still curated subsets of the broader app-server surface

## Architecture At A Glance

The current ownership chain is:

`Transport -> Connection -> Runtime -> Orchestration -> Views`

### Transport

- `CodexTransport` defines raw `Data` send/receive/close behavior.
- `StdioCodexTransport` is the current actor-based stdio implementation and lives in [`CodexTransport.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexTransport.swift).
- `CodexProcess` launches and terminates the local `codex app-server` process.
- `CodexCLIProbe` performs startup compatibility checks before connect flows proceed.

### Connection

- `CodexConnection` owns JSON-RPC framing, request correlation, retry behavior, inbound response/error handling, notification decoding, and server-request routing.
- `CodexConnection` remains protocol-focused. It does not own UI state or runtime policy.

### Runtime

- `CodexRuntimeCoordinator` owns the live runtime boundary.
- It creates `CodexProcess`, `CodexConnection`, and `CodexClient`.
- It exposes two separate app-facing streams:
  - `notifications() -> AsyncStream<ServerNotificationEnvelope>`
  - `serverRequests() -> AsyncStream<ServerRequestEnvelope>`
- It installs the default `CodexServerRequestResponder` used by `CodexConnection`.

### Client

- `CodexClient` provides typed wrappers over the generic connection layer.
- Shared JSON and decoding helpers live in `CodexClient+CodingSupport.swift`.
- The client model layer is now split into focused files for account/auth, collaboration, sandbox, error/tool support, items, threads, turns, server notifications, and server requests.
- `CodexValue` is the canonical arbitrary-JSON escape hatch used where upstream payloads remain intentionally open-ended.

### Orchestration

- `CodaxOrchestrator` is the app-facing session and state projection layer.
- It owns connect, thread loading, thread start, and turn start flows.
- It consumes both runtime streams, although server-request observation is currently wired as a no-op reducer while the default responder still returns `.unhandled`.
- `AuthCoordinator` remains the side-effect boundary for auth-specific external actions.

### Views

- SwiftUI views consume shared state from `CodaxOrchestrator`.
- `ContentViewModel` remains pane-local UI state, not the source of shared app state.

## Repository Layout

- `Codax/Controllers/Transport`
  - transport protocol, stdio transport, process lifecycle, and CLI compatibility probing
- `Codax/Controllers/Connection`
  - JSON-RPC message and connection-layer types plus routing behavior
- `Codax/Controllers/Runtime`
  - runtime ownership via `CodexRuntimeCoordinator`
- `Codax/Controllers/Client`
  - typed client methods, shared JSON/coding helpers, inbound notification/request envelopes, and protocol DTOs
- `Codax/Controllers/Orchestration`
  - app-facing state, session orchestration, and auth coordination types
- `Codax/Views`
  - the current SwiftUI shell
- `CodaxTests`
  - layer-organized tests for transport, connection, client, runtime, and orchestration
- `Docs`
  - contributor-facing schema, coverage, and architecture reports

## Current Typed Surface

`CodexClient` currently wraps these client-initiated methods:

- `initialize`
- `initialized`
- `thread/start`
- `thread/resume`
- `thread/read`
- `turn/start`
- `turn/interrupt`
- `account/read`
- `account/login/start`
- `account/login/cancel`

The runtime currently surfaces this typed notification subset:

- `error`
- `serverRequest/resolved`
- `account/updated`
- `account/login/completed`
- `thread/started`
- `thread/status/changed`
- `thread/tokenUsage/updated`
- `turn/started`
- `turn/completed`
- `turn/diff/updated`
- `turn/plan/updated`
- `item/started`
- `item/completed`
- `item/agentMessage/delta`
- `item/commandExecution/outputDelta`
- `item/fileChange/outputDelta`
- `item/reasoning/textDelta`
- `item/reasoning/summaryTextDelta`
- `item/reasoning/summaryPartAdded`

The typed server-request envelope covers the full current request-method union, but the default responder still returns `.unhandled` after surfacing each request onto the runtime stream.

## Requirements

Codax currently assumes:

- macOS
- Xcode
- a locally installed `codex` CLI capable of running `codex app-server --listen stdio://`

The current compatibility gate supports Codex CLI `0.111.x` and `0.112.x`.

## Getting Started

1. Open the project in Xcode.
2. Build the `Codax` target.
3. Run the app from Xcode.

Current expectations:

- the app launches into an early `NavigationSplitView` shell
- compatibility is checked before the runtime starts
- some thread and turn flows are real
- broader login, approval handling, and UI refinement are still in progress

## Project Documentation

Start with:

- [ROADMAP.md](/Users/galew/Workspace/Codax/ROADMAP.md)
- [TRANSPORT_SCHEMA_REPORT.md](/Users/galew/Workspace/Codax/Docs/TRANSPORT_SCHEMA_REPORT.md)
- [CONNECTION_SCHEMA_REPORT.md](/Users/galew/Workspace/Codax/Docs/CONNECTION_SCHEMA_REPORT.md)
- [CLIENT_SCHEMA_REPORT.md](/Users/galew/Workspace/Codax/Docs/CLIENT_SCHEMA_REPORT.md)
- [CLIENT_THREAD_TURN_ITEM_AUDIT.md](/Users/galew/Workspace/Codax/Docs/CLIENT_THREAD_TURN_ITEM_AUDIT.md)
- [ORCHESTRATION_SCHEMA_REPORT.md](/Users/galew/Workspace/Codax/Docs/ORCHESTRATION_SCHEMA_REPORT.md)
- [APP_SERVER_COVERAGE_REPORT.md](/Users/galew/Workspace/Codax/Docs/APP_SERVER_COVERAGE_REPORT.md)
- [SCHEMA_DIFF_REPORT_v0.111.0_to_v0.112.0.md](/Users/galew/Workspace/Codax/Docs/SCHEMA_DIFF_REPORT_v0.111.0_to_v0.112.0.md)

## Contributing

Contribution guidance lives in [CONTRIBUTING.md](/Users/galew/Workspace/Codax/CONTRIBUTING.md).

The highest-value work right now is likely to be:

- broader client request coverage
- broader notification coverage
- real server-request response behavior for approvals, elicitation, and auth refresh
- orchestration refinement
- accessibility-first UI work
- continued architecture and report alignment as the runtime grows

## Notes

- Codax is still an early alpha project.
- The protocol-facing layers are ahead of the UX.
- `CodexRuntimeCoordinator` is now the runtime boundary; `CodaxOrchestrator` is no longer responsible for raw runtime assembly.
- `CodexValue` is the single arbitrary-JSON model used across the client and connection layers.
- The current docs are contributor-first because architecture maturity still exceeds end-user polish.
