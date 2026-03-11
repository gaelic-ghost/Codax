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

The schema migration is ahead of orchestration.

What is true now:

- the connection layer has complete schema coverage
- orchestration still has stale assumptions from the deleted client layer
- some orchestration code still expects old convenience properties such as `codexId`
- runtime/orchestration cleanup is the next required pass above the completed schema work

## Practical Conclusion

This layer should now be updated to consume `CodexConnection` and the connection-owned schema types directly. Any document that still describes orchestration as depending on `CodexClient` is outdated.
