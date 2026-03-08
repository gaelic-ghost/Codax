# Project Roadmap

## Vision

- Build an accessible, intuitive, native macOS Codex client that speaks the app-server protocol reliably, uses the end user's existing Codex CLI installation by default, and presents a usable multi-pane desktop interface for managing sessions.
- Provide a truly accessible interface to agentic coding for the millions left behind by exitsing tooling from the much bigger, and incredibly well-resourced, vendors.
- Provide a user experience that involves developers in their work, instead of separating them from it.
- Provide a UX that works with developers' existing tools, instead of corraling them into an unfamiliar, half-baked, walled-garden of a tool.

## Product principles

- Keep protocol work deterministic and grounded in the app-server docs plus pinned schema artifacts.
- Ship in bounded domain slices so transport, connection, client, orchestration, and UI can be validated independently.
- Prefer clear compatibility checks over silent fallback behavior when local Codex versions drift.
- Keep roadmap tracking checklist-based, current, and implementation-relevant.

## Milestone Progress

- [ ] Milestone 0: Foundation
- [ ] Milestone 1: Transport
- [ ] Milestone 2: Connection
- [ ] Milestone 3: Client
- [ ] Milestone 4: Version Compatibility
- [ ] Milestone 5: Orchestration
- [ ] Milestone 6: NavigationSplitView UI
- [ ] Milestone 7: Codax TTS
- [ ] Milestone 8: Codax Axplanation™
- [ ] Milestone 9: Schema Diff-Check Automation
- [ ] Milestone 10: Performance Improvements (AppKit Views)

## Milestone 0: Foundation

Scope:

- [ ] Establish the Xcode app target, local schema references, and baseline project scaffolding needed for feature work.

Tickets:

- [x] Create the app target and source tree.
- [x] Add `codex-schemas` as an Xcode reference group.
- [ ] Add an automated test target for transport and client coverage.
- [ ] Normalize placeholder docs and the app shell beyond the current scaffolding.

Exit criteria:

- [ ] Project structure is stable enough for feature milestones and tests can run in local and CI workflows.

## Milestone 1: Transport

Scope:

- [ ] Deliver raw transport primitives, local process launch, stdio JSONL transport, and explicit websocket deferral.

Tickets:

- [x] Define `CodexTransport`.
- [x] Implement `CodexProcess` to launch `codex app-server --listen stdio://`.
- [x] Implement `StdioCodexTransport` with newline-delimited framing and partial-buffer handling.
- [x] Document websocket as experimental and unsupported only.
- [ ] Add transport unit tests for framing, partial reads, EOF, and malformed frames.
- [ ] Harden process lifecycle, cancellation, and stderr/log handling.

Exit criteria:

- [ ] A local `codex` process can be launched, spoken to over stdio, and shut down predictably under automated coverage.

## Milestone 2: Connection

Scope:

- [ ] Deliver app-server wire messages, request and response correlation, notification fanout, and server-request dispatch.

Tickets:

- [x] Support request ids and app-server wire envelopes without `jsonrpc` on the wire.
- [x] Implement generic request correlation in `CodexConnection`.
- [x] Implement notification streaming via `AsyncStream`.
- [x] Implement server-request dispatch and JSON-RPC responses.
- [x] Cover the full current `ServerRequest.ts` union in `ServerRequestEnvelope`.
- [ ] Add retry and backoff policy for retryable server overload errors (`-32001`).
- [ ] Broaden `ServerNotificationEnvelope` beyond the current validation subset.
- [ ] Add automated connection tests for success and error correlation, notification delivery, and dispatch behavior.

Exit criteria:

- [ ] The connection layer can sustain real request and response traffic and route inbound server traffic deterministically under test.

## Milestone 3: Client

Scope:

- [ ] Deliver a typed Swift facade over the generic connection layer for the current app-server methods in scope.

Tickets:

- [x] Wire `initialize(_:)`.
- [x] Wire `sendInitialized()`.
- [x] Wire the current thread, turn, account, and login wrappers through generic request routing.
- [ ] Validate all current DTO shapes against real app-server payloads.
- [ ] Add remaining typed client methods for thread management, listing, metadata, and other supported endpoints as needed.
- [ ] Reduce generic `JSONValue` placeholders where stable DTOs are known.

Exit criteria:

- [ ] The client layer is a trustworthy typed facade for current app features, not just thin pass-through wrappers.

## Milestone 4: Version Compatibility

Scope:

- [ ] Add startup-time detection of the installed Codex CLI and compatibility gating against supported schema and protocol expectations.

Tickets:

- [ ] Detect the installed `codex` binary path and version at startup.
- [ ] Define the supported version policy for Codax relative to the pinned schema and transport report version.
- [ ] Fail clearly for unsupported or unknown versions.
- [ ] Surface compatibility warnings or errors into app state for the UI layer.
- [ ] Document compatibility behavior in the roadmap, report, and startup flow.

Exit criteria:

- [ ] Codax never silently talks to an unsupported app-server version.

## Milestone 5: Orchestration

Scope:

- [ ] Deliver app session management, connect and login flows, thread lifecycle control, and notification-driven state updates.

Tickets:

- [ ] Replace current `CodaxOrchestrator` placeholder behavior with a real connection lifecycle.
- [ ] Inject a concrete `CodexClient` and transport or process startup path.
- [ ] Implement connect, login, thread-loading, and start-turn flows.
- [ ] Implement a concrete `CodexServerRequestHandler`.
- [ ] Map connection, auth, and thread state into observable app state.

Exit criteria:

- [ ] The app can connect, initialize, handle login state, and manage a thread session without bypassing the orchestrator.

## Milestone 6: NavigationSplitView UI

Scope:

- [ ] Deliver a basic three-panel macOS shell using `NavigationSplitView` with sidebar, content, and detail panes.

Tickets:

- [ ] Replace the placeholder `ContentView` shell with a real three-panel layout.
- [ ] Define the sidebar thread list, middle conversation pane, and right-side detail or inspector pane.
- [ ] Bind all three panes to orchestrator state.
- [ ] Add loading, error, and empty states for startup, connection, and thread selection.
- [ ] Preserve the current minimal app shell only until the split-view is in place.

Exit criteria:

- [ ] The app presents a usable three-panel shell that reflects transport, client, and orchestrator state.

## Milestone 7: Codax TTS

Scope:

- [ ] TBD.

Tickets:

- [ ] TBD.

Exit Criteria:

- [ ] TBD.

## Milestone 8: Codax Axplanation

Scope:

- [ ] TBD.

Tickets:

- [ ] TBD.

Exit Criteria:

- [ ] TBD.

## Milestone 9: Schema Diff-Check Automation

Scope:

- [ ] TBD.

Tickets:

- [ ] TBD.

Exit Criteria:

- [ ] TBD.

## Milestone 10: Performance Improvements (AppKit Views)

Scope:

- [ ] TBD.

Tickets:

- [ ] TBD.

Exit Criteria:

- [ ] TBD.
