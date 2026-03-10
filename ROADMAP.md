# Project Roadmap

## Vision

- Build an accessible, intuitive, native macOS Codex client that speaks the app-server protocol reliably, uses the end user's existing Codex CLI installation by default, and presents a usable multi-pane desktop interface for managing sessions.
- Provide a truly accessible interface to agentic coding for the millions left behind by existing tooling from the much bigger, and incredibly well-resourced, vendors.
- Provide a user experience that involves developers in their work, instead of separating them from it.
- Provide a UX that works with developers' existing tools, instead of corralling them into an unfamiliar, half-baked, walled-garden of a tool.

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
- [ ] Milestone 7: UI/UX Improvements
- [ ] Milestone 8: Full SwiftUI AX Implementation
- [ ] Milestone 9: Codax TTS (Codex `Speech Generation Skill` Wrapper)
- [ ] Milestone 10: Codax Thread Axe™ (Chop through the thread noise. See the Forest for the Trees)
- [ ] Milestone 11: Codax Thread Axplanation™ (Intelligent, Adaptive Summarization of Stale Threads)
- [ ] Milestone 12: Codax Auto-Lang™ (Automatic Environment Detection for Coding Languages)
- [ ] Milestone 13: Codax Auto-Steer™ (Language-Aware Automatic Context Adjustment)
- [ ] Milestone 14: Codax Code Axe (Chop through the code noise. See the Forest for the Trees)
- [ ] Milestone 15: Codax Code Axplanation (Intelligent, Adaptive Summarization of Codebases)
- [ ] Milestone 16: Schema Diff-Check Automation (Script or SPM/XC Plugin)
- [ ] Milestone 17: Performance Improvements (AppKit Views)
- [ ] Milestone 18: Performance Improvements (Local TTS Engine)
- [ ] Milestone 19: DX Improvements (Various)

## Milestone 0: Foundation

Scope:

- [ ] Establish the Xcode app target, local schema references, and baseline project scaffolding needed for feature work.

Tickets:

- [x] Create the app target and source tree.
- [x] Add `codex-schemas` as an Xcode reference group.
- [x] Add the `CodaxTests` test target and keep it runnable locally.
- [ ] Add meaningful transport and client coverage to `CodaxTests`.
- [ ] Normalize placeholder docs and the app shell beyond the current scaffolding.

Exit criteria:

- [ ] Project structure is stable enough for feature milestones and tests can run in local and CI workflows with non-placeholder coverage.

## Milestone 1: Transport

Scope:

- [ ] Deliver raw transport primitives, local process launch, stdio JSONL transport, and explicit websocket deferral.

Tickets:

- [x] Define `CodexTransport`.
- [x] Implement `CodexProcess` to launch `codex app-server --listen stdio://`.
- [x] Implement actor-based `StdioCodexTransport` with newline-delimited framing and partial-buffer handling.
- [x] Document websocket as experimental and unsupported only.
- [x] Add transport unit tests for framing, partial reads, EOF, and malformed frames.
- [x] Harden process lifecycle, cancellation, and stderr/log handling.
- [ ] If websocket transport is added later, model it as another explicit `CodexProcess`-owned transport implementation rather than reopening a fake-generic transport seam.

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
- [x] Add retry and backoff policy for retryable server overload errors (`-32001`).
- [ ] Broaden `ServerNotificationEnvelope` beyond the current validation subset.
- [x] Add automated connection tests for success and error correlation, notification delivery, and dispatch behavior.

Exit criteria:

- [ ] The connection layer can sustain real request and response traffic and route inbound server traffic deterministically under test.
- [ ] Keep `CodaxTests/` organized by layer so transport, connection, and orchestration coverage stay easy to find; only process-sensitive suites should opt into serialized execution.

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
- [ ] Define the supported version policy for Codax relative to the pinned schema artifacts and the transport or connection reports.
- [ ] Fail clearly for unsupported or unknown versions.
- [ ] Surface compatibility warnings or errors into `CodaxOrchestrator` or `AuthCoordinator` state for the UI layer.
- [ ] Document compatibility behavior in the roadmap, reports, and startup flow.

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

## Milestone 7: UI/UX Improvements

Scope:

- [ ] Make the three-pane shell pleasant and usable for daily work without changing core protocol architecture.

Tickets:

- [ ] Improve conversation rendering, message grouping, and inspector presentation.
- [ ] Add better loading, error, reconnect, and retry UX for connection- and thread-level state.
- [ ] Add command, file-change, reasoning, and approval visual treatments that are readable and scannable.
- [ ] Add app-level affordances for login state, active thread state, pending approvals, and version-compatibility warnings.
- [ ] Tighten typography, spacing, and information hierarchy across sidebar, content, and detail panes.
- [ ] Add keyboard shortcuts and interaction polish for common navigation actions.

Exit Criteria:

- [ ] The app is no longer a functional shell only; it is coherent, readable, and usable for repeated daily sessions.

## Milestone 8: Full SwiftUI AX Implementation

Scope:

- [ ] Deliver a VoiceOver- and keyboard-usable experience across the main app shell and core workflows.

Tickets:

- [ ] Audit all major views for semantic labels, values, hints, and roles.
- [ ] Define predictable focus order across sidebar, conversation pane, and detail pane.
- [ ] Ensure keyboard-only navigation works for thread selection, conversation reading, and approval actions.
- [ ] Add accessibility announcements for connection changes, turn completion, login completion, and approval prompts.
- [ ] Ensure streamed content updates remain understandable to assistive technologies.
- [ ] Add accessibility-oriented tests or repeatable audit checklists for core flows.

Exit Criteria:

- [ ] A user can connect, navigate threads, read conversation state, and handle approvals with VoiceOver and keyboard navigation only.

## Milestone 9: Codax TTS (Codex `Speech Generation Skill` Wrapper)

Scope:

- [ ] Add narrated output using Codex/OpenAI speech generation first.

Tickets:

- [ ] Define which content can be narrated, including assistant replies, summaries, and selected thread content.
- [ ] Wrap the existing speech-generation workflow behind app actions and `CodaxOrchestrator` state.
- [ ] Add playback controls, progress state, cancel/retry handling, and output-file management.
- [ ] Expose narration settings such as voice or profile selection and target content selection.
- [ ] Document fallback behavior when speech generation is unavailable.

Exit Criteria:

- [ ] Users can reliably generate and play narrated output for supported app content from within Codax.

## Milestone 10: Codax Thread Axe™ (Chop through the thread noise. See the Forest for the Trees)

Scope:

- [ ] Build a signal-reduction feature that helps users cut through large conversations, noisy tool output, and multi-item turns.

Tickets:

- [ ] Define target use cases such as “find the important outcome,” “show only blockers,” and “collapse noise.”
- [ ] Add structured filters and views for command output, file changes, reasoning, approvals, and other high-volume item types.
- [ ] Generate condensed “what matters” views using Codex/OpenAI-first summarization or classification support.
- [ ] Let users jump from condensed views back to full underlying context without losing traceability.
- [ ] Ensure the feature works incrementally while a turn is still streaming.

Exit Criteria:

- [ ] Users can reduce a noisy thread or turn to an actionable view without losing traceability back to raw events.

## Milestone 11: Codax Thread Axplanation™ (Intelligent, Adaptive Summarization of Stale Threads)

Scope:

- [ ] Add intelligent, adaptive summaries for threads, turns, or selected content. Integrate with `Codax TTS`, `Codax Thread Axe`, and a dedicated UI control. Consider generating summaries automatically in the background for presentation when users return to a thread later on.

Tickets:

- [ ] Define summary modes such as quick recap, technical summary, handoff summary, and accessible explanation.
- [ ] Define clear, consistent, context-aware summarization policies for each mode.
- [ ] Allow summaries for the current turn, full thread, or selected items.
- [ ] Store or cache generated summaries in app state where appropriate.
- [ ] Integrate summary generation into the inspector and detail workflow.
- [ ] Distinguish summary output from raw model content so users can trust what is derived versus original.

Exit Criteria:

- [ ] Users can request and consume reliable summaries tailored to their current task and reading needs.
- [ ] Users can request and consume these summaries via minimal interaction with native UI controls.
- [ ] Summarization policies work consistently, and reliably in common modes and contexts.

## Milestone 12: Codax Auto-Lang™ (Automatic Environment Detection for Coding Languages)

Scope:

- [ ] Build automatic project-level coding language detection, starting with Swift.

Tickets:

- [ ] Define detection criteria (Presence of `Package.Swift`, `.xcodeproj`, `.xcworkspace`, etc.)
- [ ] Implement detection which occurs before new thread creation within the project repo.
- [ ] Add user and agent facing communication of the active language. For the user, this could include a UI element with language logo.
- [ ] Consider the next language(s) to add, and create a future milestone for that.

Exit Criteria:

- [ ] Swift Package support. Xcode Project support.

## Milestone 13: Codax Auto-Steer™ (Language-Aware Automatic Context Adjustment)

Scope:

- [ ] Add a repo-level automatic "context setup" system that uses `Codax Auto-Lang` to ensure the correct context is present, and tools/agent skills are emphasized, for the given project language/ecosystem. Start with Swift, expanding to other languages later on.

Tickets:

- [ ] Define proper context (template `AGENTS.md`, etc.) and tooling (local cli/build tools, Agent Skills) for language profiles.
- [ ] Add profiles for languages/tooling which include tooling options and template context files such as `AGENTS.md`.
- [ ] Add a UI interface for the user to customize a given language profile.
- [ ] Add an interface for the agent to customize a given language profile, as well as guidance for the agent, allowing the user to customize via agent interaction.
- [ ] Add detection for defined context and tools. This should run before new thread creation for the project so issues like "missing `AGENTS.md`" can be automatically corrected ahead of time.
- [ ] Implement auto-correction of common issues such as "missing `AGENTS.md`".
- [ ] Add user and agent directed communications of findings, including suggestions to remediate issues that could not be automatically corrected, such as "Xcode MCP not enabled for external agents" and "missing Xcode Command Line Tools".
- [ ] Consider the next language(s) to add, and create a future milestone for that.

Exit Criteria:

- [ ] Defined Swift-specific context and tooling availability is detected, and auto-corrected where possible, before new thread start in a given repo/project directory.
- [ ] Findings and remediation options are communicated clearly to both user and agent.
- [ ] Customization of Swift language profile, defined context, and Swift/Xcode tooling is working and available to both user and agent.

## Milestone 14: Codax Code Axe™ (Chop through the code noise. See the Forest for the Trees)

Scope:

- [ ] Build a language-aware "noise-filter" to facilitate clearer views into, and explantions of, requested aspects of a file, library, or codebase. Tailored to what matters in the given coding language/ecosystem. Swift first, other langs later.

Tickets:

- [ ] Define target use cases such as "Which functions take `<symbol>` as a param".
- [ ] Identify other use case examples to define in order to properly steer implementation decisions.
- [ ] Add structured, language-aware filters for Swift Symbols using native tooling. Consider Xcode MCP, swift-syntax, symbol-kit, SourceKit-LSP, etc.
- [ ] Define idiomatic ways to describe symbols, declarations, calls, etc.
- [ ] Define familiar, and idiomatic ways to provide views of symbols, declarations, etc.
- [ ] Generate condensed “what matters” views using Codex/OpenAI-first summarization or classification support.
- [ ] Let users jump from condensed views back to full underlying context without losing traceability.
- [ ] Consider the next language(s) to add, and create a future milestone for that.

Exit Criteria:

- [ ] Users can reduce a noisy Swift file, Package, or Xcode Project to an actionable (optionally filtered) view, or explanation, without losing traceability back to raw events.

## Milestone 15: Codax Code Axplanation™ (Intelligent, Adaptive Summarization of Codebases)

Scope:

- [ ] Add intelligent, adaptive, language-aware summaries for codebases, interfaces, libs, and source files. Integrate with `Codax TTS`, `Codax Code Axe`, and a dedicated UI control. Consider option for eager and/or opportunistic background generation of summaries.

Tickets:

- [ ] Define summary modes such as quick recap, technical summary, handoff summary, and accessible explanation.
- [ ] Define clear, consistent, context-aware summarization policies for each mode.	
- [ ] Allow summaries for a single file, an interface, full framework/sdk, or entire codebase.
- [ ] Store or cache generated summaries in app state where appropriate.
- [ ] Integrate summary generation into the inspector and detail workflow.
- [ ] Distinguish summary output from raw model content so users can trust what is derived versus original.

Exit Criteria:

- [ ] Users can request and consume reliable summaries tailored to their current task and reading needs.
- [ ] Users can request and consume these summaries via minimal interaction with native UI controls.
- [ ] Summarization policies work consistently, and reliably in common modes and contexts.


## Milestone 16: Schema Diff-Check Automation (Script or SPM/XC Plugin)

Scope:

- [ ] Automate detection of schema drift between pinned local schema artifacts and future Codex versions.

Tickets:

- [ ] Define the source of truth for pinned schema versions and report references.
- [ ] Add a script or SwiftPM/Xcode-integrated tool that compares schema snapshots.
- [ ] Generate a readable diff summary for changed request, notification, and payload shapes.
- [ ] Identify breaking versus additive schema changes.
- [ ] Connect the output to roadmap and report maintenance workflow.

Exit Criteria:

- [ ] Schema-version drift is detectable and reviewable before protocol mismatches silently ship.

## Milestone 17: Performance Improvements (AppKit Views)

Scope:

- [ ] Address UI performance bottlenecks by selectively introducing AppKit-backed views where SwiftUI is insufficient.

Tickets:

- [ ] Identify likely high-churn or high-volume surfaces such as long conversations, rich logs, or diff views.
- [ ] Profile current SwiftUI behavior under realistic large-thread loads.
- [ ] Define the first AppKit-backed candidates and their interop boundaries.
- [ ] Migrate only the highest-value view or views, not the whole UI.
- [ ] Verify accessibility and keyboard behavior are preserved after migration.

Exit Criteria:

- [ ] Large or noisy sessions remain responsive without regressing the app’s usability.

## Milestone 18: Performance Improvements (Local TTS Engine)

Scope:

- [ ] Add a local speech path as a later performance and resilience enhancement to Milestone 9.

Tickets:

- [ ] Define the local engine strategy and platform constraints.
- [ ] Compare latency, quality, offline behavior, and integration complexity against hosted speech generation.
- [ ] Add an abstraction boundary so hosted and local TTS can coexist cleanly.
- [ ] Expose per-engine selection or fallback policy in app settings if needed.
- [ ] Verify local playback and generation do not degrade main-app responsiveness.

Exit Criteria:

- [ ] Codax can offer a viable local narration path for supported use cases without breaking the hosted-first speech workflow.

## Milestone 19: DX Improvements (Various)

Scope:

- [ ] Bring in some nice, ergonomic helpers from async-alogrithms and the server-side Swift world. Async timer streams, throwing streams, zips and splits, shares, all that good stuff wherever applicable. Already seeing some places where those could work better with less code.

Tickets:

- [x] Refactor `CodexConnection` to an actor-based core with AsyncAlgorithms-backed request waiters.
- [x] Refactor `StdioCodexTransport` to an actor-based stdio transport implementation.
- [ ] Continue reducing concurrency warnings and isolation mismatches in surrounding DTOs and envelopes.
- [ ] Evaluate additional AsyncAlgorithms operators only where they materially simplify real code paths.
- [ ] Evaluate whether stderr/log snapshot buffering should remain in `CodexProcess` or move to a narrower diagnostics helper if process ownership grows further.
- [ ] Evaluate swift-service-lifecycle for handling startup and graceful shutdown of long-lived services, either by wrapping individually in `Service` conformance, or also composing as `ServiceGroup`, depending.

Exit Criteria:

- [ ] Concurrency-sensitive transport and connection code is actor-isolated, readable, and warning-clean under the project’s modern Swift concurrency settings.
