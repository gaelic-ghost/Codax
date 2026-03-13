# Transport Schema Report

## Summary

The transport layer remains deliberately narrow and is one of the most stable parts of the repo.

It owns:

- raw `Data` send/receive/close semantics through `CodexTransport`
- local `codex app-server` process launch, stdio framing, stderr capture, and shutdown through `LocalCodexTransport`
- local CLI discovery and compatibility probing through `CodexCLIProbe`

It does not own protocol typing. That boundary is connection-owned.

## Relationship To Higher Layers

Current checked-in stack direction:

- `CodexTransport`
- `CodexConnection`
- `CodexRuntimeCoordinator`
- `CodaxOrchestrator`
- SwiftUI app shell and migration-in-progress views

The older `CodaxViewModel` layer is still present in tests and some view references, but it should be treated as migration residue rather than the authoritative current stack.

## Current File Ownership

- [`CodexTransport.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexTransport.swift)
- [`CodexCLIProbe.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexCLIProbe.swift)
- transport startup probing feeds the runtime startup path
- schema generation remains a connection concern owned by [`generate_connection_schema.js`](/Users/galew/Workspace/Codax/Tools/generate_connection_schema.js)

## Current Conclusion

Transport is not where the repo is most unstable right now. The larger uncertainty is above transport, in the migration between the old view-model-driven app layer and the newer orchestrator-driven direction.
