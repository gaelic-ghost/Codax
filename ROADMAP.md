# Project Roadmap

## Current Architecture Baseline

- `Transport -> Connection -> Runtime -> Orchestration -> Views` is the intended current direction
- `CodexConnection` is the only app-server boundary
- the separate client layer has been removed
- `Runtime` is a sort of "diverter" intended to help with server reqs/notifs we don't need user input on.
- the connection schema generator and verifier currently report `497/497` exported schema types represented
- until `codex` reaches `v1.x.x`, the schema target is the latest released upstream `codex app-server` contract

## Transition Note

The protocol and schema boundary is substantially ahead of the app shell.

Checked-in source still shows migration seams:

- `CodaxApp` uses `CodaxOrchestrator`
- several view files still contain placeholders or `CodaxViewModel` references
- orchestration tests still target the older `CodaxViewModel` design
- narrative docs had previously overstated the completion of SwiftData-backed views, inspector flows, and toolbar behavior

## What's Done

- [x] Local `codex app-server` process launch and stdio transport
- [x] JSON-RPC request/response routing in `CodexConnection`
- [x] typed `CodexConnection` request API for every `ClientRequest` method in `codex-schemas/v0.114.0`
- [x] typed `ServerNotificationEnvelope` for every `ServerNotification` method
- [x] typed `ServerRequestEnvelope` and `ServerRequestResponse` for every `ServerRequest` method
- [x] generated connection-owned Swift representation for every exported schema in `codex-schemas/v0.114.0`
- [x] connection schema verification gate via `node Tools/update_connection_schema_progress.js --verify`
- [x] generated schema output ignored in `.gitignore`
- [x] `CodexRuntimeCoordinator` owns transport startup and typed event forwarding
- [x] `CodaxOrchestrator` exists as the current checked-in app-facing observable object
- [x] the app entrypoint uses `NavigationSplitView`

## What's In Progress

### App-layer migration

- [ ] Finish migrating app behavior from `CodaxViewModel` assumptions to `CodaxOrchestrator`
- [ ] Unify the SwiftUI environment surface so views no longer reference removed or stale app-layer types
- [ ] Reconcile orchestration tests with the current app-layer architecture
- [ ] Finish gutting initial SwiftData kickstart, impl slimmer CoreData persistence for persisting "Project" abstraction(s).

### UI/UX/AX

- [ ] Add approval, elicitation, and auth-refresh UX
- [ ] Add exec-backed, UI-selectable, git workflow presets for common flows, including commit and commit-and-push UX with approval, output, and failure handling
- [ ] Persist durable project, config, and catalog projections where delayed rendering matters
- [ ] Account and login polish around pending-login, browser handoff (needs impl w/ webkit authview), and auth-refresh flows
- [ ] Improve item, diff, plan, and realtime rendering
- [ ] Dive into accessibility-first UI/UX refinement
- [ ] Full SwiftUI/AppKit AX support. This gets done right for *every* accessibility need. I'll dive into CarbonAX so deep my *dreams* have kPrefixes, if I have to.
- [ ] Finish experimenting and evaluating different TTS implementations and flows

### Automation and quality

- [ ] Add automated regen and verification of the connection schema, should fail CI on coverage drift
- [ ] Add automated verification for the UI-facing app-server coverage tracker
- [ ] Add targeted tests for the full generated connection boundary where useful

## Immediate Priority

The highest-confidence part of the codebase is still the protocol stack: transport, connection typing, schema generation, and runtime forwarding. The highest-value next work is the migration above that boundary: aligning orchestration, views, tests, and documentation around one app-layer design before claiming richer UX completion.
