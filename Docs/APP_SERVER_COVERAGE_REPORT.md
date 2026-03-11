# App-Server Coverage Report

## Summary

The protocol boundary is complete in the connection layer.

Current verified state:

- `433/433` exported schema types represented in connection Swift
- `47/47` `ClientRequest` methods represented by typed `CodexConnection` methods
- `44/44` `ServerNotification` methods represented by `ServerNotificationEnvelope`
- `8/8` `ServerRequest` methods represented by `ServerRequestEnvelope`

## What Is Complete

- schema-owned Swift types for the full pinned `codex-schemas/v0.112.0` export set
- typed request API on `CodexConnection`
- typed notification envelope decoding
- typed server-request envelope decoding and response routing

## What Is Still Incomplete

The remaining gaps are not schema coverage gaps.

What still remains is app behavior above the protocol boundary:

- approval UX and decision flows
- elicitation and auth-refresh UX
- broader UI/state reduction of the full schema surface
- end-user polish and accessibility refinement

## Verification

- `node Tools/generate_connection_schema.js`
- `node Tools/update_connection_schema_progress.js --verify`
- `xcodebuild -project /Users/galew/Workspace/Codax/Codax.xcodeproj -scheme Codax -sdk macosx test`

## Reference

The authoritative coverage tracker is [connection-schema-progress.md](/Users/galew/Workspace/Codax/Docs/connection-schema-progress.md).
