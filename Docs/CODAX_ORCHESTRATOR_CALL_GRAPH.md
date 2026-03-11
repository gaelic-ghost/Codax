# `CodaxOrchestrator` Call Graph

## Status

This document is a high-level call-flow note for the current architecture.

## Current Accurate Statement

- `CodaxOrchestrator` sits above `CodexRuntimeCoordinator`
- `CodexRuntimeCoordinator` sits directly on `CodexConnection`
- `CodexConnection` sits directly on `LocalCodexTransport`
- `LocalCodexTransport` owns local `codex app-server` process launch, stdio framing, stderr capture, and shutdown

## Practical Flow

- views call `CodaxOrchestrator`
- `CodaxOrchestrator` drives `CodexRuntimeCoordinator`
- `CodexRuntimeCoordinator` starts `LocalCodexTransport` and `CodexConnection`
- typed requests flow downward into `CodexConnection`
- typed notifications and server requests flow back upward through runtime into orchestration
