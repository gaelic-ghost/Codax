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

The remaining gaps are not schema coverage gaps. They are application-integration gaps:

- runtime still references the deleted client layer
- orchestration still references deleted client APIs and old convenience properties
- approval, elicitation, and auth-refresh behaviors are not finished in the app layer
- UI reduction of the full schema surface is still partial

## Reference

The authoritative coverage tracker is [connection-schema-progress.md](/Users/galew/Workspace/Codax/Docs/connection-schema-progress.md).
