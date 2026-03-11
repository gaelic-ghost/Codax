# Codax

An accessibility-forward native macOS Codex app that talks to a local `codex app-server` over stdio.

## Current State

Codax is still early, but the protocol boundary is no longer partial:

- `Transport -> Connection -> Runtime -> Orchestration -> Views`
- `CodexConnection` is the only app-server boundary
- the separate client layer has been deleted
- the connection layer now represents every exported schema in `codex-schemas/v0.112.0`
- the generated connection surface currently verifies as `433/433` schema exports represented

The remaining unfinished work is above the connection layer:

- runtime and orchestration cleanup after client-layer removal
- UI/state adaptation to the schema-owned connection models
- approval, elicitation, and auth-refresh behavior
- broader end-user polish and accessibility work

## Architecture

### Transport

- `CodexTransport` owns raw `Data` send/receive/close behavior
- `LocalCodexTransport` owns local `codex app-server --listen stdio://` process launch, stdio framing, stderr capture, and shutdown
- `CodexCLIProbe` owns local CLI discovery and compatibility checks

### Connection

- `CodexConnection` owns JSON-RPC framing, request correlation, retry behavior, inbound notification routing, and inbound server-request routing
- schema-owned Swift types live under `Codax/Controllers/Connection`
- the generated file is `CodexSchema.generated.swift`
- raw string-method request helpers are internal implementation details, not the public API

### Runtime And Above

- `CodexRuntimeCoordinator` constructs `LocalCodexTransport`, injects it into `CodexConnection`, and forwards typed notification and server-request streams
- `CodaxOrchestrator` still has stale app-model integration to clean up above the connection/runtime seam
- SwiftUI views sit above orchestration and are not part of the protocol boundary

## Repository Layout

- `Codax/Controllers/Transport`
  - process launch, stdio transport, and CLI probing
- `Codax/Controllers/Connection`
  - connection actor, JSON-RPC support types, generated schema graph, typed request methods, notification envelopes, and server-request envelopes
- `Codax/Controllers/Runtime`
  - runtime ownership and stream forwarding
- `Codax/Controllers/Orchestration`
  - app-facing state projection and auth coordination
- `Codax/Views`
  - the current SwiftUI shell
- `CodaxTests`
  - transport, connection, runtime, and orchestration tests
- `Docs`
  - architecture, coverage, and schema tracking reports

## Verification

The schema coverage gate is:

- `node Tools/generate_connection_schema.js`
- `node Tools/update_connection_schema_progress.js --verify`

Current verified result:

- `433` total exported schema types
- `433` represented in connection Swift
- `0` missing
- `47/47` client requests represented through typed `CodexConnection` methods
- `44/44` server notifications represented through `ServerNotificationEnvelope`
- `8/8` server requests represented through `ServerRequestEnvelope`

## Requirements

- macOS
- Xcode
- a local `codex` CLI capable of running `codex app-server --listen stdio://`

## Project Docs

- [ROADMAP.md](/Users/galew/Workspace/Codax/ROADMAP.md)
- [connection-schema-progress.md](/Users/galew/Workspace/Codax/Docs/connection-schema-progress.md)
- [CONNECTION_SCHEMA_REPORT.md](/Users/galew/Workspace/Codax/Docs/CONNECTION_SCHEMA_REPORT.md)
- [APP_SERVER_COVERAGE_REPORT.md](/Users/galew/Workspace/Codax/Docs/APP_SERVER_COVERAGE_REPORT.md)
- [TRANSPORT_SCHEMA_REPORT.md](/Users/galew/Workspace/Codax/Docs/TRANSPORT_SCHEMA_REPORT.md)
- [ORCHESTRATION_SCHEMA_REPORT.md](/Users/galew/Workspace/Codax/Docs/ORCHESTRATION_SCHEMA_REPORT.md)
- [CLIENT_SCHEMA_REPORT.md](/Users/galew/Workspace/Codax/Docs/CLIENT_SCHEMA_REPORT.md)
- [CLIENT_THREAD_TURN_ITEM_AUDIT.md](/Users/galew/Workspace/Codax/Docs/CLIENT_THREAD_TURN_ITEM_AUDIT.md)
- [SCHEMA_DIFF_REPORT_v0.111.0_to_v0.112.0.md](/Users/galew/Workspace/Codax/Docs/SCHEMA_DIFF_REPORT_v0.111.0_to_v0.112.0.md)
- [CODAX_ORCHESTRATOR_CALL_GRAPH.md](/Users/galew/Workspace/Codax/Docs/CODAX_ORCHESTRATOR_CALL_GRAPH.md)
