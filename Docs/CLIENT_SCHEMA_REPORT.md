# Client Schema Report

## Status

This report is now historical.

The separate client layer no longer exists in the codebase. Its responsibilities were collapsed into `CodexConnection` and the connection-owned generated schema graph under `Codax/Controllers/Connection`.

## Replacement Architecture

Current ownership is:

- `CodexConnection`
  - the only app-server boundary
  - typed request methods for every `ClientRequest` method
  - typed inbound `ServerNotificationEnvelope`
  - typed inbound `ServerRequestEnvelope`
  - typed `ServerRequestResponse`
- `CodexSchema.generated.swift`
  - generated Swift representations for every exported schema in `codex-schemas/v0.112.0`
- `CodexConnection+Types.swift`
  - handwritten JSON-RPC support types used by the connection actor

## Coverage State

Current verified state is tracked in [connection-schema-progress.md](/Users/galew/Workspace/Codax/Docs/connection-schema-progress.md):

- `433/433` exported schema types represented
- `47/47` client requests represented
- `44/44` server notifications represented
- `8/8` server requests represented

## Removed Concepts

These are no longer current architecture and should not be used as reference:

- `CodexClient`
- `CodexValue` as a public client-layer escape hatch
- a separate typed client facade over a generic public connection API

## Practical Conclusion

Do not add new protocol DTOs or request wrappers under a revived client layer.

All schema and typed wire work now belongs in `Codax/Controllers/Connection`.
