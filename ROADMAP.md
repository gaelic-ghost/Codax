# Project Roadmap

## Current Architecture Baseline

- `Transport -> Connection -> Runtime -> Orchestration -> Views`
- `CodexConnection` is the only app-server boundary
- the separate client layer has been removed
- the connection schema generator and verifier currently report `433/433` exported schema types represented

## What Is Done

- [x] Local `codex app-server` process launch and stdio transport
- [x] JSON-RPC request/response routing in `CodexConnection`
- [x] typed `CodexConnection` request API for every `ClientRequest` method in `codex-schemas/v0.112.0`
- [x] typed `ServerNotificationEnvelope` for every `ServerNotification` method
- [x] typed `ServerRequestEnvelope` and `ServerRequestResponse` for every `ServerRequest` method
- [x] generated connection-owned Swift representation for every exported schema in `codex-schemas/v0.112.0`
- [x] connection schema verification gate via `node Tools/update_connection_schema_progress.js --verify`
- [x] generated schema output ignored in `.gitignore`

## What Still Needs Work

### UI and app behavior

- [ ] Finish login behavior beyond placeholders
- [ ] Add real approval, elicitation, and auth-refresh UX
- [ ] Improve item, diff, plan, and realtime rendering
- [ ] Continue accessibility-first UI refinement

### Automation and quality

- [ ] Add automated verification that regenerates the connection schema and fails CI on coverage drift
- [ ] Add targeted tests for the full generated connection boundary where useful

## Immediate Priority

The protocol typing pass and the transport/runtime cleanup pass are complete. The highest-value next work is app behavior above that boundary: approvals, elicitation flows, auth-refresh behavior, and UI polish.
