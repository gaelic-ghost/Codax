# Client Schema Report

## Summary

The client layer is now a focused wire-model and typed-API layer built on top of `CodexConnection`.

Its current responsibilities are:

- exposing typed client-initiated methods through `CodexClient`
- defining typed request and response DTOs for the currently implemented method subset
- defining the curated `ServerNotificationEnvelope` and `ServerRequestEnvelope`
- hosting shared JSON and `Codable` support such as `CodexValue` and `CodexCoding`
- providing stable client-side identity mapping for server-owned ids

The client layer is no longer organized around a few oversized extension files. It has been split into focused files for coding support, identity support, account/auth types, collaboration and sandbox policy types, tool and error support, item modeling, thread modeling, turn modeling, server notifications, and server requests.

## Current Client Request Surface

`CodexClient` currently wraps these methods:

- `initialize`
- `initialized`
- `thread/start`
- `thread/resume`
- `thread/read`
- `turn/start`
- `turn/interrupt`
- `account/read`
- `account/login/start`
- `account/login/cancel`

That remains an intentionally narrow subset of the wider app-server surface.

## Current Shared Model Infrastructure

### `CodexValue`

`CodexValue` is now the canonical arbitrary-JSON model used across the client and connection layers.

It replaces the earlier duplicate JSON tree situation and is the correct escape hatch for:

- unknown notification payloads
- unknown server-request payloads
- intentionally open-ended nested fields
- `ThreadItem.unknown(raw:)`

### `CodexCoding`

`CodexCoding` now centralizes the repeated `Codable` patterns used across the client layer:

- string-case enums
- string-or-object payloads
- keyed one-of payloads
- tagged `"type"` payloads
- tagged object encoding

This has materially reduced custom decode repetition across account, sandbox, error, tool, request, and item models.

## Current Inbound Envelopes

### `ServerNotificationEnvelope`

The currently typed notification subset includes:

- `error`
- `serverRequest/resolved`
- `account/updated`
- `account/login/completed`
- `thread/started`
- `thread/status/changed`
- `thread/tokenUsage/updated`
- `turn/started`
- `turn/completed`
- `turn/diff/updated`
- `turn/plan/updated`
- `item/started`
- `item/completed`
- `item/agentMessage/delta`
- `item/commandExecution/outputDelta`
- `item/fileChange/outputDelta`
- `item/reasoning/textDelta`
- `item/reasoning/summaryTextDelta`
- `item/reasoning/summaryPartAdded`

Unknown methods still fall back to `.unknown(method:raw:)`.

### `ServerRequestEnvelope`

The currently typed server-request envelope includes:

- `account/chatgptAuthTokens/refresh`
- `item/fileChange/requestApproval`
- `applyPatchApproval`
- `item/tool/requestUserInput`
- `item/tool/call`
- `mcpServer/elicitation/request`
- `item/commandExecution/requestApproval`
- `execCommandApproval`

The paired response union is now named `ServerRequestResponse`, and the runtime installs a `CodexServerRequestResponder`.

## Current File Ownership

The current client split is centered on:

- [`CodexClient.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient.swift)
- [`CodexClient+CodingSupport.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+CodingSupport.swift)
- [`CodexClient+IdentitySupport.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+IdentitySupport.swift)
- [`CodexClient+AccountTypes.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+AccountTypes.swift)
- [`CodexClient+ServerNotificationTypes.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerNotificationTypes.swift)
- [`CodexClient+ServerRequestTypes.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerRequestTypes.swift)
- [`CodexClient+ItemTypes.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ItemTypes.swift)
- [`CodexClient+ItemPayloads.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ItemPayloads.swift)
- [`CodexClient+ItemNotifications.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ItemNotifications.swift)
- [`CodexClient+Thread.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+Thread.swift)
- [`CodexClient+Turn.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+Turn.swift)

The current client ownership should be read from the focused files above, not from older report-era file splits.

## Current Strengths

- The typed client request facade is thin and predictable.
- Shared JSON/coding helpers are centralized instead of duplicated.
- `ThreadItem` is now a real typed union with `.unknown(raw:)` fallback.
- Stable `codexId` plus local `UUID` identity handling is now consistent.
- The request and notification envelope shapes are materially cleaner than earlier versions of the repo.

## Current Gaps

- Request coverage remains narrow relative to `ClientRequest.ts`.
- Notification coverage remains a curated subset.
- Some nested payloads are still intentionally modeled as `CodexValue` where upstream shape is open or not yet worth hardening into first-class DTOs.
- The runtime surfaces server requests, but Codax still lacks real approval, elicitation, and auth-refresh response behavior above the default `.unhandled` responder.

## Practical Next Steps

The next meaningful client-layer expansions are:

- more request wrappers for thread management, model listing, and account utilities
- broader notification coverage for current UI needs
- richer concrete DTOs where `CodexValue` still marks open-ended but high-value payloads
- deeper item and delta modeling once the UI is ready to consume it
