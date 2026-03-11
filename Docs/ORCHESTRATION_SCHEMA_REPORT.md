# Orchestration Schema Report

## Summary

`CodaxViewModel` is the app-state projection layer.

It is a runtime-only consumer. It does not own protocol models or call `CodexConnection` directly.

## Current Relationship

- `CodexConnection`
  - complete typed schema boundary
- `CodexRuntimeCoordinator`
  - sole app-facing session boundary
- `CodaxViewModel`
  - app-facing state projection and pending user-request state
- SwiftUI views
  - presentation

## Current State

What is true now:

- the connection layer has complete schema coverage
- runtime constructs `LocalCodexTransport`, injects `CodexConnection`, exposes typed request forwarding, and forwards typed streams
- the view model consumes runtime only and no longer reaches directly into `CodexConnection`
- the view model owns UI projection state, pending login state, pending user-request state, and thread-selection/thread-detail state
- `loadThreads()` uses `thread/list` to populate thread summaries and `thread/read` to hydrate the selected thread
- `loginWithChatGPT()` starts a real `account/login/start` flow and stores pending login state
- test fixtures and app-state projections have been updated to the schema-owned `id` and source shapes
- generator-backed connection types come from `node Tools/generate_connection_schema.js`

## Practical Conclusion

This layer is no longer blocked on the removed client layer or on direct connection reach-through. Remaining work here is richer approval, elicitation, auth-refresh UX, and broader UI shaping, not protocol-boundary migration.
