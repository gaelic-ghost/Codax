# Orchestration Schema Report

## Summary

`CodaxViewModel` is the app-state projection layer.

It is a runtime-only consumer. It does not own protocol models or call `CodexConnection` directly.

## Current Relationship

- `CodexConnection`
  - complete typed schema boundary
- `CodexRuntimeCoordinator`
  - sole app-facing session boundary
- `CodaxPersistenceBridge`
  - sole app-side SwiftData writer and durable projection mapper
- `CodaxViewModel`
  - app-facing live state projection and pending user-request state
- SwiftUI views
  - presentation plus durable `@Query` reads

## Current State

What is true now:

- the connection layer has complete schema coverage
- runtime constructs `LocalCodexTransport`, injects `CodexConnection`, exposes typed request forwarding, and forwards typed streams
- the view model consumes runtime only and no longer reaches directly into `CodexConnection`
- the persistence bridge is the only app-side `ModelContext` owner and writer
- the view model owns UI projection state, pending login state, pending user-request state, thread selection, transient turn state, alerts, and hydration progress
- SwiftUI views fetch durable thread summaries and selected-thread detail from SwiftData with `@Query`
- `loadThreads()` uses `thread/list` to persist thread summaries and `thread/read` to hydrate the selected thread into SwiftData
- `loginWithChatGPT()` starts a real `account/login/start` flow and stores pending login state
- selected-plus-recent hydration is bounded and sequential so startup does not flood the `codex app-server` link
- test fixtures and app-state projections have been updated to the schema-owned `id` and source shapes
- generator-backed connection types come from `node Tools/generate_connection_schema.js`

## Practical Conclusion

This layer is no longer blocked on the removed client layer or on direct connection reach-through. Its remaining work is not protocol migration; it is richer approval, elicitation, auth-refresh UX, broader durable projections, and broader UI shaping.
