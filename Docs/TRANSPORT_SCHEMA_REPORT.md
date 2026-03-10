# Transport Schema Report

## Summary

This report maps the transport-facing TypeScript schemas in `~/Workspace/codex-schemas/v0.112.0/` onto the current Swift skeleton in `/Users/galew/Workspace/Codax/Codax.xcodeproj`.

The goal is not to catalog the entire generated schema bundle. It is to identify the subset that defines the actual wire contract for the transport layer, explain how those schemas should map onto the Swift layering already present in this project, and call out the places where the current skeleton is narrower than `v0.112.0`.

The main conclusion is:

- The transport contract is centered on `ClientRequest.ts`, `ClientNotification.ts`, `ServerNotification.ts`, `ServerRequest.ts`, and `RequestId.ts`.
- The current Swift skeleton already has the right high-level layering:
  - `CodexTransport` for raw bytes
  - `CodexConnection` for JSON-RPC framing and routing
  - `CodexClient.swift` plus focused `CodexClient+*.swift` files for typed client and inbound semantics
  - `CodaxOrchestrator.swift` plus `+Types` coordinator files for app-facing consumption
- The current Swift surface is intentionally incomplete but structurally aligned.
- The biggest gap is not architecture. It is schema coverage: the current envelope enums only represent a subset of the server-driven variants present in `v0.112.0`.

## Xcode And Repo Context

- Xcode is currently pointed at `/Users/galew/Workspace/Codax/Codax.xcodeproj`.
- `../codex-schemas` is included in the Xcode project as a `PBXFileSystemSynchronizedRootGroup`.
- That means the schema files are visible from Xcode for reference, but they are not Swift build inputs.
- The active app target is still just the local `Codax` source tree.

This matters because the schema bundle should be treated as a source-of-truth reference set for manual Swift modeling, not as generated code that Xcode is compiling directly.

## Protocol Mechanics

The generated TypeScript schemas are not the whole transport contract. The Codex app-server docs and the `codex-rs/app-server/README.md` protocol notes add wire-level behavior that is not fully represented in the generated unions.

- `stdio` is the supported production transport and uses newline-delimited JSON.
- `websocket` exists but is marked experimental and unsupported.
- The protocol uses JSON-RPC 2.0 semantics, but omits `"jsonrpc":"2.0"` on the wire.
- Each connection must begin with an `initialize` request followed by an `initialized` notification.
- Requests issued before that handshake are rejected by the server.
- `InitializeCapabilities` supports both `experimentalApi` and `optOutNotificationMethods`.
- App-server can reject overloaded ingress with JSON-RPC error code `-32001`, which higher layers should treat as retryable.

## Source-Of-Truth Transport Schemas

### 1. Wire Framing

These are the transport roots that matter first:

- `RequestId.ts`
  - Defines request identifiers as `string | number`.
- `ClientRequest.ts`
  - Defines the client-to-server request union.
- `ClientNotification.ts`
  - Defines client notifications such as `initialized`.
- `ServerNotification.ts`
  - Defines the server-to-client notification union.
- `ServerRequest.ts`
  - Defines server-initiated request/approval flows that require a client response.

These files form the real wire contract for the current transport work. Everything else in the generated schema set is either:

- a payload reachable from one of those unions,
- a deeper domain/entity type used by one of those payloads,
- or adjacent functionality that does not directly define the JSON-RPC contract this Swift skeleton is modeling.

### 2. Adjacent But Separate: `EventMsg.ts`

`EventMsg.ts` is transport-adjacent, but it is not the same surface as the JSON-RPC contract implied by `CodexConnection`, `CodexClient+InboundMessage.swift`, and the client envelope files.

It models a broad event stream with variants like:

- `task_started`
- `task_complete`
- `agent_message`
- `exec_command_begin`
- `request_user_input`
- `dynamic_tool_call_request`
- `plan_update`

That is a different abstraction level from:

- request/response calls in `ClientRequest`
- client notifications in `ClientNotification`
- server push notifications in `ServerNotification`
- server-initiated approval/input requests in `ServerRequest`

For this project, `EventMsg` should be treated as a future or parallel event-stream model, not as the primary source for the JSON-RPC transport layer being scaffolded now.

## Schema Buckets And Swift Ownership

### 1. Wire Framing

**TS source of truth**

- `RequestId.ts`
- implied JSON-RPC envelope shape from the request/notification/request unions
- error payloads such as `CodexErrorInfo.ts` and the corresponding error object type referenced by JSON-RPC failures

**Swift ownership**

- `/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexTransport.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexTransport+Types.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexProcess.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexProcess+Types.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection+Messages.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection+Types.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection.swift`

**Current alignment**

- `CodexTransport` is correctly defined as bytes only:
  - `send(_ message: Data)`
  - `receive() -> Data`
  - `close()`
- `CodexTransport+Types.swift` now owns transport-scoped shared types like:
  - `JSONValue`
  - `CodexTransportError`
- `CodexProcess.swift` and `CodexProcess+Types.swift` now isolate process-launch concerns from the transport protocol itself.
- `JSONRPCID` in `Controllers/Connection/CodexConnection+Messages.swift` already matches the schema intent well:
  - `.string(String)`
  - `.int(Int64)`
- The request/notification/response/error message structs already indicate the right framing split.

**Gaps**

- The current implementation now covers the first transport slice:
  - request correlation
  - response matching
  - server notification fanout
  - server-request dispatch to a handler
- Remaining work is primarily breadth and hardening:
  - richer notification coverage
  - higher-level orchestration on top of the generic transport

### 2. Client-Initiated Methods

**TS source of truth**

The current Swift `CodexClient` surface maps to these `ClientRequest.ts` variants:

- `initialize`
- `thread/start`
- `thread/resume`
- `thread/read`
- `turn/start`
- `turn/interrupt`
- `account/read`
- `account/login/start`
- `account/login/cancel`

The most relevant payload pairs are:

- `InitializeParams` / `InitializeResponse`
- `v2/ThreadStartParams` / `v2/ThreadStartResponse`
- `v2/ThreadResumeParams` / `v2/ThreadResumeResponse`
- `v2/ThreadReadParams` / `v2/ThreadReadResponse`
- `v2/TurnStartParams` / `v2/TurnStartResponse`
- `v2/TurnInterruptParams` / `v2/TurnInterruptResponse`
- `v2/GetAccountParams` / `v2/GetAccountResponse`
- `v2/LoginAccountParams` / `v2/LoginAccountResponse`
- `v2/CancelLoginAccountParams` / `v2/CancelLoginAccountResponse`

**Swift ownership**

- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient.swift`
- backed by `/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection.swift`
- supported by focused client-side type files such as:
  - `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+Account.swift`
  - `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+Thread.swift`
  - `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+Turn.swift`
  - `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+Command.swift`
  - `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+Initialize.swift`

**Current alignment**

The public methods in `CodexClient.swift` are already a strong first-pass subset of `ClientRequest.ts`:

- `initialize(_:)`
- `startThread(_:)`
- `resumeThread(_:)`
- `readThread(_:)`
- `startTurn(_:)`
- `interruptTurn(_:)`
- `readAccount(_:)`
- `startLogin(_:)`
- `cancelLogin(_:)`

This is a good transport-first selection because it covers:

- session establishment
- thread lifecycle entry points
- turn lifecycle entry points
- account/auth bootstrap

**Observed drift**

- `sendInitialized()` is valid, but it maps to `ClientNotification = { "method": "initialized" }`, not to a `ClientRequest.ts` method.
  - The app-server docs, not `ClientRequest.ts`, are the authoritative source for that handshake rule.
- The current client surface is intentionally narrower than `ClientRequest.ts`, which also includes:
  - thread archive/fork/list/rollback metadata operations
  - skills/app/plugin/config flows
  - model/feature listing
  - command execution and other app-control endpoints

That narrower surface is acceptable for a first implementation, but the report should treat it as a deliberate subset, not as full schema coverage.

### 3. Server-Initiated Notifications

**TS source of truth**

`ServerNotification.ts` is the server push union. It includes:

- thread lifecycle:
  - `thread/started`
  - `thread/status/changed`
  - `thread/archived`
  - `thread/unarchived`
  - `thread/closed`
  - `thread/name/updated`
  - `thread/tokenUsage/updated`
  - `thread/compacted`
- turn lifecycle:
  - `turn/started`
  - `turn/completed`
  - `turn/diff/updated`
  - `turn/plan/updated`
- item lifecycle:
  - `item/started`
  - `item/completed`
  - `rawResponseItem/completed`
  - `item/agentMessage/delta`
  - `item/plan/delta`
  - `item/commandExecution/outputDelta`
  - `item/commandExecution/terminalInteraction`
  - `item/fileChange/outputDelta`
  - `item/mcpToolCall/progress`
  - `item/reasoning/summaryTextDelta`
  - `item/reasoning/summaryPartAdded`
  - `item/reasoning/textDelta`
- account/app/platform:
  - `account/updated`
  - `account/rateLimits/updated`
  - `account/login/completed`
  - `app/list/updated`
  - `model/rerouted`
  - `deprecationNotice`
  - `configWarning`
- realtime/platform:
  - `thread/realtime/started`
  - `thread/realtime/itemAdded`
  - `thread/realtime/outputAudio/delta`
  - `thread/realtime/error`
  - `thread/realtime/closed`
  - Windows and fuzzy-file-search notifications

**Swift ownership**

- raw routing in `/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection.swift`
- semantic lifting in:
  - `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+InboundMessage.swift`
  - `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerNotificationEnvelope.swift`
  - `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerNotificationTypes.swift`
- consumption in:
  - `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift`
  - `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator+Types.swift`

**Current alignment**

The current `ServerNotificationEnvelope` now captures the minimum transport-validation set:

- `error`
- `threadStarted`
- `turnStarted`
- `turnCompleted`
- `itemStarted`
- `itemCompleted`
- `accountUpdated`
- `accountLoginCompleted`
- `reasoningTextDelta`
- `unknown(method:raw:)`

This is the right shape for the app layer: a curated semantic enum with an `unknown` escape hatch.

**Observed drift**

The current enum is much narrower than the schema. Notable omissions include:

- error notifications
- turn completion
- item completion
- agent message delta
- plan delta
- command/file output delta
- server request resolution
- account rate limit updates
- thread status/name/token usage updates
- deprecation/config warnings

This is still phase-one coverage, not a complete schema projection.

### 4. Server-Initiated Requests

**TS source of truth**

`ServerRequest.ts` currently includes:

- `item/commandExecution/requestApproval`
- `item/fileChange/requestApproval`
- `item/tool/requestUserInput`
- `mcpServer/elicitation/request`
- `item/tool/call`
- `account/chatgptAuthTokens/refresh`
- `applyPatchApproval`
- `execCommandApproval`

Relevant payloads include:

- `v2/CommandExecutionRequestApprovalParams`
- `v2/FileChangeRequestApprovalParams`
- `v2/ToolRequestUserInputParams`
- `v2/McpServerElicitationRequestParams`
- `v2/DynamicToolCallParams`
- `v2/ChatgptAuthTokensRefreshParams`
- `ApplyPatchApprovalParams`
- `ExecCommandApprovalParams`

**Swift ownership**

- routing in `/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection.swift`
- semantic lifting in `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerRequestHandlerEnvelope.swift`
- response typing in `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerRequestHandlerTypes.swift`
- resolution via `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerRequestHandler.swift`

**Current alignment**

`ServerRequestEnvelope` now covers the full current `ServerRequest.ts` union:

- `commandApproval`
- `fileChangeApproval`
- `userInput`
- `mcpServerElicitation`
- `chatgptAuthRefresh`
- `dynamicToolCall`
- `applyPatchApproval`
- `execCommandApproval`
- `unknown(method:id:raw:)`

## Method Mapping: Current Swift Client To `ClientRequest.ts`

This is the direct mapping the transport report should preserve.

| Swift API | `ClientRequest.ts` method | Params | Response |
| --- | --- | --- | --- |
| `initialize(_:)` | `"initialize"` | `InitializeParams` | `InitializeResponse` |
| `sendInitialized()` | `"initialized"` notification | none | none |
| `startThread(_:)` | `"thread/start"` | `v2/ThreadStartParams` | `v2/ThreadStartResponse` |
| `resumeThread(_:)` | `"thread/resume"` | `v2/ThreadResumeParams` | `v2/ThreadResumeResponse` |
| `readThread(_:)` | `"thread/read"` | `v2/ThreadReadParams` | `v2/ThreadReadResponse` |
| `startTurn(_:)` | `"turn/start"` | `v2/TurnStartParams` | `v2/TurnStartResponse` |
| `interruptTurn(_:)` | `"turn/interrupt"` | `v2/TurnInterruptParams` | `v2/TurnInterruptResponse` |
| `readAccount(_:)` | `"account/read"` | `v2/GetAccountParams` | `v2/GetAccountResponse` |
| `startLogin(_:)` | `"account/login/start"` | `v2/LoginAccountParams` | `v2/LoginAccountResponse` |
| `cancelLogin(_:)` | `"account/login/cancel"` | `v2/CancelLoginAccountParams` | `v2/CancelLoginAccountResponse` |

## Payload Notes That Matter For Swift Modeling

These are the payload details most likely to shape the Swift types.

### Initialization

- `InitializeParams`
  - `{ clientInfo, capabilities }`
- `InitializeResponse`
  - `{ userAgent }`

This is a small, stable request/response pair and a good first endpoint to implement end-to-end.

### Thread Start / Resume / Read

- `ThreadStartParams`
  - mostly optional configuration overrides
  - includes required booleans:
    - `experimentalRawEvents`
    - `persistExtendedHistory`
- `ThreadResumeParams`
  - requires `threadId`
  - includes optional `history` and `path`
  - includes required `persistExtendedHistory`
- `ThreadReadParams`
  - requires `threadId`
  - requires `includeTurns`
- `ThreadStartResponse` and `ThreadResumeResponse`
  - return `thread` plus runtime settings like `model`, `modelProvider`, `cwd`, `approvalPolicy`, `sandbox`, `reasoningEffort`
- `ThreadReadResponse`
  - returns just `thread`

Implication for Swift:

- These should not be treated as thin string-only DTOs.
- The shared model layer needs real DTO support for thread state, sandbox/approval settings, and reasoning/service-tier values.

### Turn Start / Interrupt

- `TurnStartParams`
  - requires `threadId`
  - requires `input: Array<UserInput>`
  - supports optional overrides for cwd, approval policy, sandbox policy, model, service tier, reasoning, output schema, and collaboration mode
- `TurnStartResponse`
  - returns `{ turn }`
- `TurnInterruptParams`
  - requires `threadId`, `turnId`
- `TurnInterruptResponse`
  - empty object

Implication for Swift:

- `TurnStartParams` is one of the first payloads where schema breadth will matter.
- `TurnInterruptResponse` should likely decode into a dedicated empty response type, not `Void`.

### Account / Login

- `GetAccountParams`
  - requires `refreshToken: boolean`
- `GetAccountResponse`
  - returns `{ account, requiresOpenaiAuth }`
- `LoginAccountParams`
  - tagged union:
    - `apiKey`
    - `chatgpt`
    - `chatgptAuthTokens`
- `LoginAccountResponse`
  - tagged union:
    - `apiKey`
    - `chatgpt` with `loginId` and `authUrl`
    - `chatgptAuthTokens`
- `CancelLoginAccountParams`
  - requires `loginId`
- `CancelLoginAccountResponse`
  - returns `{ status }`

Implication for Swift:

- Auth/login types belong in shared models, not buried inside the connection layer.
- The union tagging patterns should map to Swift enums with associated values.

### Server Request Payloads

- `CommandExecutionRequestApprovalParams`
  - rich approval payload with `threadId`, `turnId`, `itemId`, optional `approvalId`, optional `reason`, command metadata, decision lists, and optional policy amendments
- `FileChangeRequestApprovalParams`
  - narrower write-access approval payload
- `ToolRequestUserInputParams`
  - carries structured question arrays
- `DynamicToolCallParams`
  - carries `threadId`, `turnId`, `callId`, `tool`, and JSON arguments
- `ChatgptAuthTokensRefreshParams`
  - carries refresh reason plus optional previous account id

Implication for Swift:

- The server-request handler protocol should eventually deal in strongly typed request enums, not raw dictionaries or generic JSON blobs.

## Mapping The Schemas To The Current Swift Skeleton

### Transport Primitives

**Files**

- `/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexTransport.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexTransport+Types.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexProcess.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexProcess+Types.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection+Messages.swift`

**Role**

- Own raw bytes and JSON-RPC envelope types.

**Recommendation**

- Keep `CodexTransport` byte-oriented only.
- Keep JSON-RPC envelope structs/enums separate from higher-level payload DTOs.
- Expand `CodexConnection+Messages.swift` into a true wire-format layer:
  - request message
  - notification message
  - success response
  - error response
  - request id
  - error object

### Connection / Router Layer

**File**

- `/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection.swift`

**Role**

- Own encoding/decoding, request correlation, response completion, and inbound routing.

**Recommendation**

- `CodexConnection` should be the only layer that understands raw JSON-RPC message directionality.
- It should:
  - send requests with generated `JSONRPCID`
  - await matching success/error responses
  - decode inbound server notifications
  - decode inbound server requests
  - expose a notification stream to higher layers
  - delegate server requests to `CodexServerRequestHandler`

### Typed Client API Layer

**File**

- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient.swift`

**Role**

- Present a schema-backed, app-friendly API surface over `CodexConnection`.

**Recommendation**

- Keep the current method-per-endpoint approach.
- Each method should bind directly to one schema-backed method string and one param/response pair.
- Keep `sendInitialized()` as the explicit wrapper for the `initialized` client notification.

### Inbound Semantic Lifting

**Files**

- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+InboundMessage.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerNotificationEnvelope.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerNotificationTypes.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerRequestHandlerEnvelope.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerRequestHandlerTypes.swift`

**Role**

- Translate raw `ServerNotification` and `ServerRequest` traffic into curated Swift enums.

**Recommendation**

- Preserve the current curated-enum design.
- Keep `unknown(...)` fallback cases for forward compatibility.
- Expand coverage to at least the schema variants needed by the orchestrator and any initial auth/approval UX.

### App / Orchestrator Layer

**File**

- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator+Types.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/AuthCoordinator.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/AuthCoordinator+Types.swift`

**Role**

- Consume typed notifications and requests.
- Update observable app state.

**Recommendation**

- Keep this layer schema-aware only through shared Swift models and envelope enums.
- Do not let raw JSON-RPC or raw TS-union concerns leak this high.

## Concrete Schema / Skeleton Mismatches Visible Today

### 1. `RequestId` Already Maps Cleanly

- TS: `RequestId = string | number`
- Swift: `JSONRPCID = .string(String) | .int(Int64)`

This is aligned and should be retained.

### 2. `CodexClient.sendInitialized()` Is A Client Notification, Not A Client Request

- Present in Swift
- Backed by `ClientNotification.ts`
- Required by the app-server handshake docs

### 3. `ServerRequestEnvelope` Is Now Aligned With `ServerRequest.ts`

The transport slice now includes explicit cases for the full current server-request union, with `unknown(method:id:raw:)` retained for forward compatibility.

### 4. `ServerNotificationEnvelope` Remains A Curated Subset

Current explicit Swift cases:

- error
- thread started
- turn started
- turn completed
- item started
- item completed
- account updated
- account login completed
- reasoning text delta

Notable omissions:

- error
- item completed
- turn completed
- message delta
- plan delta
- command/file output deltas
- account rate limits
- thread status/name/token usage
- warnings/deprecation/platform notices

### 5. Shared Type Ownership Is Now Layer-Local

The old shared `Models/` bucket has been replaced by layer-local type holders:

- `Controllers/Transport/CodexTransport+Types.swift`
- `Controllers/Connection/CodexConnection+Types.swift`
- `Controllers/Client/CodexClient+ServerNotificationTypes.swift`
- `Controllers/Client/CodexClient+ServerRequestHandlerTypes.swift`
- `Controllers/Orchestration/CodaxOrchestrator+Types.swift`
- `Controllers/Orchestration/AuthCoordinator+Types.swift`

That structure is easier to navigate because the types now live near the behavior that owns them. The current gap is not foldering. It is that many higher-level DTOs are still intentionally thin or `JSONValue`-backed.

## Recommended Swift Type Layout For The Next Implementation Step

This is the build map the current repo should use when transport implementation begins.

### `CodexTransport`

Keep responsibility minimal:

- send raw `Data`
- receive raw `Data`
- close transport

No schema DTOs should live here.

The current stdio implementation, `StdioCodexTransport`, is now actor-based rather than a mutable transport class, which keeps the framing buffer and receive queue inside Swift concurrency isolation instead of relying on ad hoc shared mutable state. The current hardening pass also makes EOF and closure behavior explicit: clean EOF now terminates receive with `endOfStream`, EOF with a leftover partial frame now fails with `invalidFrame`, and concurrent `receive()` calls are rejected deterministically instead of relying on undefined continuation behavior.

### `CodexConnection`

Own transport mechanics:

- encode JSON-RPC requests/notifications
- decode JSON-RPC responses/errors
- correlate request ids
- route inbound server notifications
- route inbound server requests
- manage receive loop lifecycle

This is the transport engine.

### `CodexClient`

Own typed endpoint methods:

- one Swift method per schema-backed client request
- no raw method strings outside this layer, except possibly as private constants

This is the schema-backed API facade.

### `ServerNotificationEnvelope` And `ServerRequestEnvelope`

Own curated semantic enums:

- model only the cases the app wants to reason about directly
- preserve `unknown` fallbacks for forward compatibility
- grow incrementally as new product features need more server-driven traffic

This is the adaptation boundary between raw transport and app logic.

### Layer-Local `+Types` Files

Own shared DTOs and domain types close to the behavior that uses them:

- transport-scoped types in `CodexTransport+Types.swift`
- connection-scoped lifecycle and error types in `CodexConnection+Types.swift`
- client notification/request payloads in `CodexClient+ServerNotificationTypes.swift` and `CodexClient+ServerRequestHandlerTypes.swift`
- orchestration-facing aliases and state helpers in `CodaxOrchestrator+Types.swift` and `AuthCoordinator+Types.swift`

These should stay reusable by both client request responses and inbound notification/request payloads, but the ownership is now per-layer rather than under a global `Models/` directory.

## Recommended Next Implementation Order

With the stdio-first transport slice in place, the safest next order is:

1. Expand `ServerNotificationEnvelope` toward the next app-facing workflows.
2. Implement a concrete `CodexServerRequestHandler` for approvals, elicitation, and auth refresh.
3. Extend the new `CodaxTests/Transport/` suite as more notification and lifecycle cases become product-relevant.
4. Lift the transport into `CodaxOrchestrator` for connect/login/thread startup flows.

## Validation Checklist

This report was built against the following checks:

- The report is anchored on schemas reachable from `ClientRequest.ts`, `ClientNotification.ts`, `ServerNotification.ts`, `ServerRequest.ts`, and `RequestId.ts`.
- Every public method in `CodexClient.swift` was mapped to a concrete schema method or notification.
- `ServerRequestEnvelope` coverage was compared against the full `ServerRequest.ts` union.
- `ServerNotificationEnvelope` coverage was compared against the full `ServerNotification.ts` union.
- `EventMsg.ts` was separated from the JSON-RPC transport contract instead of being merged into it.
- The app-server docs were used for transport mechanics that are absent from the TS dump, including the `initialize` -> `initialized` handshake and omitted `jsonrpc` field.
- Websocket was marked experimental and excluded from the first implementation slice.
- The Xcode reference to `../codex-schemas` was identified as a synchronized reference group, not as compiled Swift input.
- The `v0.111.0 -> v0.112.0` diff was reviewed separately, and the wire roots central to the current transport slice were unchanged.

## Files Reviewed

Swift skeleton:

- `/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexTransport.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexTransport+Types.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexProcess.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexProcess+Types.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection+Messages.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection+Types.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+InboundMessage.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerNotificationEnvelope.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerNotificationTypes.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerRequestHandler.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerRequestHandlerEnvelope.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerRequestHandlerTypes.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator+Types.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/AuthCoordinator.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/AuthCoordinator+Types.swift`
- `/Users/galew/Workspace/Codax/Codax.xcodeproj/project.pbxproj`

Primary schema roots:

- `~/Workspace/codex-schemas/v0.112.0/ClientRequest.ts`
- `~/Workspace/codex-schemas/v0.112.0/ClientNotification.ts`
- `~/Workspace/codex-schemas/v0.112.0/ServerNotification.ts`
- `~/Workspace/codex-schemas/v0.112.0/ServerRequest.ts`
- `~/Workspace/codex-schemas/v0.112.0/RequestId.ts`
- `~/Workspace/codex-schemas/v0.112.0/EventMsg.ts`

Key reachable payloads:

- `InitializeParams.ts`
- `InitializeResponse.ts`
- `v2/ThreadStartParams.ts`
- `v2/ThreadStartResponse.ts`
- `v2/ThreadResumeParams.ts`
- `v2/ThreadResumeResponse.ts`
- `v2/ThreadReadParams.ts`
- `v2/ThreadReadResponse.ts`
- `v2/TurnStartParams.ts`
- `v2/TurnStartResponse.ts`
- `v2/TurnInterruptParams.ts`
- `v2/TurnInterruptResponse.ts`
- `v2/GetAccountParams.ts`
- `v2/GetAccountResponse.ts`
- `v2/LoginAccountParams.ts`
- `v2/LoginAccountResponse.ts`
- `v2/CancelLoginAccountParams.ts`
- `v2/CancelLoginAccountResponse.ts`
- `v2/CommandExecutionRequestApprovalParams.ts`
- `v2/FileChangeRequestApprovalParams.ts`
- `v2/ToolRequestUserInputParams.ts`
- `v2/DynamicToolCallParams.ts`
- `v2/ChatgptAuthTokensRefreshParams.ts`
- `v2/Thread.ts`
- `v2/Turn.ts`
