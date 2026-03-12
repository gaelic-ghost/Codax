# Project Roadmap

## Current Architecture Baseline

- `Transport -> Connection -> Runtime -> ViewModel -> Views`
- `CodexConnection` is the only app-server boundary
- SwiftData is the durable read model for thread history and hydrated thread detail
- the separate client layer has been removed
- the connection schema generator and verifier currently report `497/497` exported schema types represented

## What Is Done

- [x] Local `codex app-server` process launch and stdio transport
- [x] JSON-RPC request/response routing in `CodexConnection`
- [x] typed `CodexConnection` request API for every `ClientRequest` method in `codex-schemas/v0.114.0`
- [x] typed `ServerNotificationEnvelope` for every `ServerNotification` method
- [x] typed `ServerRequestEnvelope` and `ServerRequestResponse` for every `ServerRequest` method
- [x] generated connection-owned Swift representation for every exported schema in `codex-schemas/v0.114.0`
- [x] connection schema verification gate via `node Tools/update_connection_schema_progress.js --verify`
- [x] generated schema output ignored in `.gitignore`
- [x] dedicated `CodaxPersistenceBridge` as the only app-side SwiftData writer
- [x] `@Query`-backed thread list and selected-thread reads in SwiftUI
- [x] selected-plus-recent thread hydration policy with durable summary/detail reconciliation
- [x] project-rooted sidebar navigation with a sidebar-local `NavigationStack` and project-scoped thread lists
- [x] compact detail inspector rail with a detail-local `NavigationStack` for token usage, reasoning effort, git summary, permissions, and pending requests
- [x] app-shell toolbar actions for `New Project`, `New Thread`, and inspector visibility

## What Still Needs Work

### UI and app behavior

- [ ] Add real approval, elicitation, and auth-refresh UX
- [ ] Add exec-backed git actions after the inspector pass, including commit / commit-and-push UX with approval, output, and failure handling
- [ ] Persist durable account, config, and catalog projections where offline or delayed rendering matters
- [ ] Continue account/login polish around pending-login, browser handoff, and auth-refresh flows
- [ ] Improve item, diff, plan, and realtime rendering
- [ ] Continue accessibility-first UI refinement

### Automation and quality

- [ ] Add automated verification that regenerates the connection schema and fails CI on coverage drift
- [ ] Add automated verification for the UI-facing app-server coverage tracker
- [ ] Add targeted tests for the full generated connection boundary where useful

## Immediate Priority

The protocol typing pass, transport/runtime cleanup, durable-thread persistence split, and first-pass inspector/toolbar cleanup are complete. The highest-value next work is app behavior above that boundary: approvals, elicitation flows, auth-refresh behavior, richer durable projections, exec-backed git actions, and UI polish.
