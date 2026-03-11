# Orchestration Schema Report

## Summary

`CodaxOrchestrator` is the app-state projection layer.

It does not own protocol models. Those now come directly from the connection layer.

## Current Relationship

- `CodexConnection`
  - complete typed schema boundary
- `CodexRuntimeCoordinator`
  - runtime ownership
- `CodaxOrchestrator`
  - app-facing state projection
- SwiftUI views
  - presentation

## Current State

What is true now:

- the connection layer has complete schema coverage
- runtime constructs `LocalCodexTransport`, injects `CodexConnection`, and forwards typed streams
- orchestration consumes the connection-only runtime boundary directly
- test fixtures and app-state projections have been updated to the schema-owned `id` and source shapes

## Practical Conclusion

This layer is no longer blocked on the removed client layer. Remaining work here is product behavior and UI shaping, not protocol-boundary migration.
