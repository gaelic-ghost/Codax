# Connection Schema Report

## Summary

`CodexConnection` is the only protocol boundary in Codax.

It now owns:

- JSON-RPC request correlation
- outbound request and notification encoding
- inbound response and error decoding
- inbound `ServerNotificationEnvelope` decoding
- inbound `ServerRequestEnvelope` decoding
- typed request methods for every `ClientRequest` method
- typed server-request response routing through `CodexServerRequestResponder`
- the generated Swift representation of every exported schema in `codex-schemas/v0.112.0`

## Public Surface

The public connection surface is schema-backed, not string-method-backed:

- `start()`
- `stop()`
- `notifications() -> AsyncStream<ServerNotificationEnvelope>`
- generated typed request methods such as `initialize(_:)`, `threadStart(_:)`, `turnStart(_:)`, and the rest of the schema-defined request set
- `initialized()`

The raw JSON-RPC helpers remain internal implementation details.

## Coverage

Verified by [connection-schema-progress.md](/Users/galew/Workspace/Codax/Docs/connection-schema-progress.md):

- `433/433` exported schema types represented
- `47/47` client requests represented
- `44/44` server notifications represented
- `8/8` server requests represented

## File Ownership

- [`CodexConnection.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection.swift)
- [`CodexConnection+Types.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection+Types.swift)
- [`CodexSchema.generated.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexSchema.generated.swift)
- [`generate_connection_schema.js`](/Users/galew/Workspace/Codax/Tools/generate_connection_schema.js)
- [`update_connection_schema_progress.js`](/Users/galew/Workspace/Codax/Tools/update_connection_schema_progress.js)

## Current Limitation

The connection layer is complete as a schema boundary, but the rest of the app has not fully caught up yet. Runtime and orchestration still contain stale assumptions from the removed client layer, and those higher layers are what currently block a full app build.
