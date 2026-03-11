# `CodaxOrchestrator` Call Graph

## Status

This document is now a high-level note rather than a trustworthy detailed call graph.

The reason is straightforward: the connection layer has been fully migrated to a connection-only schema boundary, while `CodaxOrchestrator` still contains stale references to the deleted client layer and old model conveniences. A line-by-line call graph would freeze incorrect assumptions into documentation.

## Current Accurate Statement

- `CodaxOrchestrator` sits above `CodexRuntimeCoordinator`
- `CodexRuntimeCoordinator` should sit directly on `CodexConnection`
- the current orchestrator implementation still needs cleanup to reflect that architecture

## Next Documentation Condition

This file should be regenerated in detail only after runtime and orchestration have been updated to consume `CodexConnection` directly.
