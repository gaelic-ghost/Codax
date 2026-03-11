# Transport Schema Report

## Summary

The transport layer remains deliberately narrow.

It owns:

- raw `Data` send/receive/close semantics through `CodexTransport`
- local `codex app-server` process launch, stdio framing, stderr capture, and shutdown through `LocalCodexTransport`
- local CLI discovery and compatibility probing through `CodexCLIProbe`

It does not own protocol typing. That boundary is now entirely connection-owned.

## Relationship To Higher Layers

Current stack:

- `CodexTransport`
- `CodexConnection`
- `CodexRuntimeCoordinator`
- `CodaxOrchestrator`
- SwiftUI views

There is no separate client layer between transport and the app anymore.

## Current File Ownership

- [`CodexTransport.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexTransport.swift)
- [`CodexCLIProbe.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexCLIProbe.swift)

## Current Conclusion

Transport is now one local-session actor plus the probe seam. Remaining work is above transport in product behavior and UI refinement, not in transport architecture.
