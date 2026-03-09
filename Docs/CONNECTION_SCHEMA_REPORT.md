# Connection Schema Report

## Summary

This report maps the connection-facing TypeScript schemas in `~/Workspace/codex-schemas/v0.111.0/` onto the current Swift connection skeleton in `/Users/galew/Workspace/Codax/Codax.xcodeproj`.

It is intentionally narrower than the broader transport writeup. The goal here is to define the actual Connection-layer contract in this repo: JSON-RPC envelope handling, request correlation, inbound routing, notification fanout, and server-request dispatch.

The main conclusion is:

- The connection layer is centered on `RequestId.ts`, `ServerRequest.ts`, `ServerNotification.ts`, and the response/error behavior implied by `ClientRequest.ts`.
- The current Swift split is structurally sound:
  - `CodexTransport` owns bytes and transport mechanics.
  - `CodexConnection` owns JSON-RPC framing, request lifecycle, inbound routing, and receive-loop behavior.
  - `CodexClient+InboundMessage.swift`, `CodexClient+ServerNotificationEnvelope.swift`, and `CodexClient+ServerRequestHandlerEnvelope.swift` own curated semantic lifting of inbound server traffic.
  - `CodexClient+ServerRequestHandler.swift` and `CodexClient+ServerRequestHandlerTypes.swift` own the typed dispatch boundary for server-initiated requests.
- `ServerRequestEnvelope` is already aligned with the full current `ServerRequest.ts` union.
- `ServerNotificationEnvelope` is intentionally incomplete and remains the biggest schema-coverage gap inside the connection slice.
- The primary remaining connection work is not architectural. It is protocol hardening:
  - broader notification coverage
  - isolation and `Sendable` cleanup around surrounding DTOs and envelopes
  - continued connection-test expansion as the notification surface grows

## Scope And Boundary

This report is about the connection layer only.

It does not attempt to restate the full transport layer or the full typed client layer. Instead, it documents the concrete boundary between raw bytes and typed endpoint wrappers.

### In Scope

- `/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection+Messages.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection+Types.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+InboundMessage.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerNotificationEnvelope.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerNotificationTypes.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerRequestHandler.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerRequestHandlerEnvelope.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerRequestHandlerTypes.swift`

### Explicitly Adjacent But Separate

- `CodexTransport`
  - raw `Data` send/receive/close
  - stdio/process/websocket specifics
- `CodexClient`
  - typed request methods like `initialize(_:)`, `startThread(_:)`, and `startTurn(_:)`
- `CodaxOrchestrator`
  - app-facing state and UI behavior

That separation is important because the TypeScript dump includes many payloads and endpoints that the connection layer should not own directly.

## Source Of Truth

This report was grounded in three sources:

### 1. Local Generated Schemas

Primary schema roots:

- `~/Workspace/codex-schemas/v0.111.0/RequestId.ts`
- `~/Workspace/codex-schemas/v0.111.0/ServerRequest.ts`
- `~/Workspace/codex-schemas/v0.111.0/ServerNotification.ts`
- `~/Workspace/codex-schemas/v0.111.0/ClientRequest.ts`

These define the concrete wire methods and payload roots that matter most for the connection layer.

### 2. Official Codex App-Server Documentation

- [developers.openai.com/codex/app-server](https://developers.openai.com/codex/app-server/)

This is the clearest source for protocol rules that are not fully captured by the generated unions:

- omitted `"jsonrpc":"2.0"` on the wire
- stdio JSONL framing
- initialize then initialized handshake
- pre-initialization rejection behavior
- retry expectations for `-32001`
- approval and request-resolution sequencing

### 3. Upstream App-Server README

- [github.com/openai/codex/codex-rs/app-server/README.md](https://github.com/openai/codex/blob/main/codex-rs%2Fapp-server%2FREADME.md)

The upstream README materially reinforces the official docs and adds connection-relevant phrasing about:

- bounded queues and ingress saturation
- websocket being experimental and unsupported
- approval flow ordering
- `serverRequest/resolved` behavior for lifecycle cleanup

## Connection Contract In The Schemas

### 1. Request IDs

`RequestId.ts` defines request identifiers as:

- `string`
- `number`

That is the entire request-id contract the connection layer must preserve.

Swift currently models that as:

- `JSONRPCID.string(String)`
- `JSONRPCID.int(Int64)`

This is already a clean mapping.

### 2. Server-Initiated Requests

`ServerRequest.ts` defines the current server-to-client request union:

- `item/commandExecution/requestApproval`
- `item/fileChange/requestApproval`
- `item/tool/requestUserInput`
- `mcpServer/elicitation/request`
- `item/tool/call`
- `account/chatgptAuthTokens/refresh`
- `applyPatchApproval`
- `execCommandApproval`

Each of these is a true JSON-RPC request:

- they carry an `id`
- they expect a client response
- they belong to connection-layer routing before any app-specific policy is applied

This is the core justification for keeping server-request dispatch inside `CodexConnection`, not inside `CodexClient`.

### 3. Server Notifications

`ServerNotification.ts` defines a much broader server-push surface than the current Swift layer models.

Important notification groups include:

- thread lifecycle
  - `thread/started`
  - `thread/status/changed`
  - `thread/archived`
  - `thread/unarchived`
  - `thread/closed`
  - `thread/name/updated`
  - `thread/tokenUsage/updated`
- turn lifecycle
  - `turn/started`
  - `turn/completed`
  - `turn/diff/updated`
  - `turn/plan/updated`
- item lifecycle and deltas
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
- account/app/platform
  - `account/updated`
  - `account/rateLimits/updated`
  - `account/login/completed`
  - `app/list/updated`
  - `mcpServer/oauthLogin/completed`
  - `serverRequest/resolved`
  - `model/rerouted`
  - `deprecationNotice`
  - `configWarning`

For connection work, the main implication is straightforward:

- notification fanout is already implemented generically
- semantic coverage is still curated and narrow

### 4. Client Requests Matter Indirectly

`ClientRequest.ts` is not the main source for inbound connection behavior, but it still matters for connection semantics:

- every outbound request needs an `id`
- every outbound request expects either `result` or `error`
- `initialize` is a request
- some methods return empty objects rather than semantic payloads

The connection layer does not need to model every client request variant. It only needs to preserve the generic request/response/error contract those methods share.

## Protocol Rules That Do Not Live Cleanly In The TS Dump

The generated TypeScript files define method unions and payload shapes, but several critical connection rules come from the docs and the upstream README rather than the schema dump itself.

### 1. JSON-RPC Without The `jsonrpc` Field

Both the official docs and the upstream README describe the protocol as JSON-RPC 2.0 while explicitly omitting `"jsonrpc":"2.0"` on the wire.

That matches the current Swift message structs, which encode:

- `id`
- `method`
- `params`
- `result`
- `error`

and do not inject a `jsonrpc` field.

### 2. Transport Expectations

The connection layer sits above transport, but it still depends on transport behavior:

- `stdio` is the default and supported production transport.
- stdio messages are newline-delimited JSON.
- websocket exists, but both the official docs and the upstream README describe it as experimental and unsupported.

For this repo, that means the connection report should treat websocket as transport-adjacent context, not as a primary driver of connection design.

### 3. Initialization Handshake

The docs and README both require this sequence per connection:

1. send `initialize`
2. receive its response
3. send `initialized`

Any request sent before that handshake is rejected by the server.

That rule is not encoded by `ServerRequest.ts` or `ServerNotification.ts`, but it directly affects connection correctness because `CodexConnection` is the layer that actually sends and correlates those messages.

### 4. Retryable Overload Errors

The docs and README both describe bounded ingress behavior for overloaded connections:

- the server can reject requests with JSON-RPC error code `-32001`
- the error message is `"Server overloaded; retry later."`
- clients should treat this as retryable and use exponential backoff with jitter

This is now implemented in the Swift connection layer. `CodexConnection.request(...)` performs bounded retry with exponential backoff and jitter for retryable `-32001` overload responses, keeping that protocol behavior inside the generic request path rather than leaking it into typed client wrappers.

### 5. `serverRequest/resolved`

The docs and README both describe `serverRequest/resolved` as the cleanup/confirmation notification for server-initiated requests.

That matters because approval-style requests are not complete from the client’s perspective when the response is written. The server can later send a resolution notification when the request is answered or cleared by turn lifecycle events.

Current Swift connection behavior can already deliver this as a generic notification if modeled, but `ServerNotificationEnvelope` does not currently surface it explicitly.

## Swift Ownership By Layer

### 1. `CodexTransport`

**File**

- `/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexTransport.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexTransport+Types.swift`

**Responsibility**

- raw bytes only
- transport send/receive/close
- no JSON-RPC semantics

**Connection-layer implication**

The connection layer should continue to treat transport as an opaque byte source and sink.

### 2. `CodexConnection+Messages`

**File**

- `/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection+Messages.swift`

**Current public types**

- `JSONRPCRequestMessage`
- `JSONRPCNotificationMessage`
- `JSONRPCClientNotificationMessage`
- `JSONRPCResponseMessage`
- `JSONRPCErrorMessage`
- `JSONRPCResponseEnvelope`
- `JSONRPCErrorEnvelope`
- `JSONRPCErrorObject`
- `JSONRPCID`

**Responsibility**

- define wire-format envelopes
- define shared request/response/error structures
- define request-id representation

This file is the connection layer's schema-neutral wire boundary.

### 3. `CodexConnection`

**File**

- `/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection.swift`

**Current responsibility in code**

- generate numeric request ids
- encode outbound requests and notifications
- hold actor-owned per-request waiters keyed by id
- receive raw transport messages
- split inbound messages into:
  - server method objects
  - success responses
  - error responses
- route server requests to `CodexServerRequestHandler`
- stream notifications via `AsyncStream` over actor-managed fanout
- fail pending requests on disconnect or receive-loop failure
- transparently retry retryable overload errors with bounded backoff

This is the actual connection engine.

### 4. Client Inbound Envelopes

**Files**

- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+InboundMessage.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerNotificationEnvelope.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerNotificationTypes.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerRequestHandlerEnvelope.swift`

**Current public enums and types**

- `CodexInboundMessage`
- `ServerNotificationEnvelope`
- `ServerRequestEnvelope`
- concrete notification payload types such as `ErrorNotification` and `ReasoningTextDeltaNotification`

**Responsibility**

- `CodexClient+InboundMessage.swift` owns the top-level inbound message enum
- `CodexClient+ServerNotificationEnvelope.swift` owns notification envelope decoding
- `CodexClient+ServerNotificationTypes.swift` owns the concrete notification payload types currently modeled
- `CodexClient+ServerRequestHandlerEnvelope.swift` owns `ServerRequestEnvelope` and server-request decode logic
- preserve `unknown(...)` fallbacks for forward compatibility

This cluster is the adaptation boundary between generic JSON-RPC routing and app-meaningful inbound events.

### 5. `CodexClient+ServerRequestHandler`

**Files**

- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerRequestHandler.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerRequestHandlerTypes.swift`

**Current responsibility**

- define the typed async dispatch hook:
  - `handle(_ request: ServerRequestEnvelope) async -> ServerRequestResult`
- define the typed request-result payloads used by that contract in `CodexClient+ServerRequestHandlerTypes.swift`

This is correctly placed outside transport and inside the connection-facing boundary. It lets the connection layer remain generic while still emitting typed responses.

### 6. `CodexConnection+Types.swift`

**File**

- `/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection+Types.swift`

**Current public types**

- `ConnectionState`
- `CodexConnectionError`

**Responsibility**

- connection lifecycle state
- connection-specific error semantics

That ownership is reasonable. These types are app-facing but still rooted in connection concerns rather than higher-level product logic.

## Current Alignment

### 1. Request Correlation Is Implemented Correctly At A High Level

The current `CodexConnection` implementation already performs the core request lifecycle:

- assigns a new `JSONRPCID`
- stores an actor-owned one-shot waiter keyed by id
- encodes and sends the request
- completes or fails the pending entry when a matching response arrives

This is the central capability Milestone 2 needed, and it is present.

### 2. Disconnect Behavior Is Coherent

The current code fails all pending requests and finishes notification streams when:

- `stop()` is called
- the receive loop throws

That is the right connection-level behavior for a first implementation because it prevents orphaned request continuations and dangling notification streams.

### 3. Retryable Overload Handling Is Now In Place

The current actor-based implementation now absorbs the documented `-32001` overload behavior directly inside `CodexConnection.request(...)`:

- detect retryable overload server errors
- apply bounded exponential backoff with jitter
- preserve disconnect semantics while retrying
- keep typed client wrappers thin

That is the correct ownership boundary for this protocol behavior.

### 4. Notification Fanout Is Generic And Decoupled

`CodexConnection.notifications()` exposes an `AsyncStream<ServerNotificationEnvelope>`.

That is a sound connection-layer choice because:

- `CodexConnection` stays responsible for routing
- consumers can subscribe independently
- higher layers are not forced to understand raw JSON objects

The current implementation uses actor-managed notification continuations behind that public stream API, so fanout stays decoupled without exposing the internal coordination mechanism.

### 5. Server-Request Dispatch Is In The Right Place

`CodexConnection` distinguishes inbound method objects with `id` from those without `id`, decodes server requests through `ServerRequestEnvelope`, and writes either:

- a result response
- a JSON-RPC error response

That matches the app-server’s approval and elicitation model.

### 6. `ServerRequestEnvelope` Matches The Current Schema Union

Current explicit Swift cases:

- `commandApproval`
- `fileChangeApproval`
- `userInput`
- `mcpServerElicitation`
- `chatgptAuthRefresh`
- `dynamicToolCall`
- `applyPatchApproval`
- `execCommandApproval`
- `unknown(method:id:raw:)`

That covers the full current `ServerRequest.ts` union while preserving a forward-compatible unknown fallback.

This is the strongest area of current connection/schema alignment.

## Intentionally Curated Subsets

### `ServerNotificationEnvelope` Is Deliberately Narrower Than `ServerNotification.ts`

Current explicit Swift notification cases are:

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

This is not a bug by itself. It is a product choice:

- the connection layer can already fan out notifications generically
- the app only lifts the subset it currently wants to reason about directly

That said, the report should state clearly that this is a curated subset, not full schema coverage.

## Documented But Not Yet Modeled In Swift

The following protocol-relevant notifications or behaviors are documented and present in the schema roots, but not currently surfaced as explicit connection-facing Swift cases:

### 1. `serverRequest/resolved`

This is the most important omission for connection work because it closes the lifecycle of:

- command approvals
- file change approvals
- tool user-input requests
- MCP elicitations

Without an explicit case, higher layers can still observe it through `.unknown`, but they cannot reason about it semantically.

### 2. Thread Status And Unload Signals

Not yet explicitly modeled:

- `thread/status/changed`
- `thread/closed`
- `thread/archived`
- `thread/unarchived`
- `thread/name/updated`
- `thread/tokenUsage/updated`

These matter for any UI that wants to present loaded/unloaded state or maintain a thread list accurately.

### 3. Streamed Delta Notifications

Not yet explicitly modeled:

- `item/agentMessage/delta`
- `item/plan/delta`
- `item/commandExecution/outputDelta`
- `item/commandExecution/terminalInteraction`
- `item/fileChange/outputDelta`
- `item/reasoning/summaryTextDelta`
- `item/reasoning/summaryPartAdded`
- `item/mcpToolCall/progress`

These are central to real interactive UX and are likely the next notification cases that need explicit lifting.

### 4. Account And Platform Updates

Not yet explicitly modeled:

- `account/rateLimits/updated`
- `mcpServer/oauthLogin/completed`
- `app/list/updated`
- `model/rerouted`
- `deprecationNotice`
- `configWarning`

These are not required for the first request-correlation slice, but they are part of the current server-push contract.

### 5. Isolation And `Sendable` Cleanup Around DTO Boundaries

The current actor refactor and test pass made the connection internals much cleaner, but the surrounding DTO and envelope layer still needs further concurrency cleanup.

The remaining concurrency-focused gap is not request correlation. It is making sure the broader payload types used around notifications, server requests, and client DTOs are explicitly isolated or `Sendable` in a way that will hold up under future Swift 6 tightening.

## Open Gaps Against Milestone 2

The current open Connection milestone tickets in `/Users/galew/Workspace/Codax/ROADMAP.md` are:

- broaden `ServerNotificationEnvelope` beyond the current validation subset
- continue expanding connection tests as notification and DTO coverage grows
- clean up isolation and `Sendable` boundaries around surrounding DTOs and envelopes

Those roadmap items match the repo and schema state well.

### Gap 1: Notification Coverage Breadth

Current state:

- notification streaming exists
- semantic lifting is narrow

Expected connection-layer outcome:

- add explicit cases for the next app-facing workflows
- keep `unknown(method:raw:)` as the forward-compatible fallback

### Gap 2: Isolation And DTO Concurrency Hygiene

Current state:

- the connection and stdio transport internals now use actor-based concurrency
- core connection tests exist and pass
- some surrounding DTO and envelope types still need explicit isolation/`Sendable` cleanup to fully align with the modern concurrency direction

Expected connection-layer outcome:

- continue narrowing concurrency warnings around payload types that cross actor and nonisolated boundaries
- keep the connection actor’s public surface stable while making DTO ownership more explicit

## Recommended Connection Interpretation For This Repo

### `CodexConnection`

Should remain the only layer that understands:

- raw JSON-RPC message directionality
- request-id generation
- pending request tables
- receive-loop lifecycle
- server method-object splitting into request vs notification
- response/error completion rules

### `ServerNotificationEnvelope`

Should remain curated rather than exhaustive, but it should expand where app behavior depends on semantic cases rather than raw passthrough.

### `ServerRequestEnvelope`

Should continue to track the full current server-request union because request dispatch is a connection responsibility, not merely a convenience mapping.

### `CodexClient`

Should continue to stay thin and typed. The connection layer should absorb generic protocol behaviors like retry and correlation so endpoint wrappers remain simple.

## Conclusions

### 1. The Connection Architecture Is Already Correct

The repo already has the right layer split:

- byte transport below
- generic JSON-RPC connection engine in the middle
- typed client and semantic envelopes above

The current work does not need an architectural rewrite.

### 2. `ServerRequestEnvelope` Is In Good Shape

The server-request side of the connection layer is already aligned with the full current `v0.111.0` schema union and matches the documented app-server approval and elicitation model.

### 3. `ServerNotificationEnvelope` Is The Main Schema Gap

The notification side is intentionally partial. That is acceptable for the current stage, but it should be described honestly as curated subset coverage rather than full protocol support.

### 4. The Highest-Value Next Connection Work Is Narrow And Concrete

The next connection-layer priorities are:

1. add explicit notification cases for the next real app workflows, especially `serverRequest/resolved` and streamed deltas
2. keep expanding automated coverage as the lifted notification surface grows
3. clean up isolation and `Sendable` boundaries around surrounding DTOs and envelopes

## Validation Checklist

This report was checked against the following repo truths:

- `JSONRPCID` matches `RequestId.ts` as `string | number`.
- `CodexConnection` is the layer currently responsible for request correlation, retry/backoff, receive-loop handling, and inbound routing.
- `ServerRequestEnvelope` was compared against the full `ServerRequest.ts` union and covers all current variants.
- `ServerNotificationEnvelope` was compared against the full `ServerNotification.ts` union and is narrower by design.
- The omitted `jsonrpc` field, stdio JSONL framing, initialize-then-initialized handshake, and `-32001` retry guidance are supported by both the official docs and the upstream README.
- The current implementation now uses actor-owned request waiters and actor-managed notification fanout rather than lock-backed pending continuations.
- The `serverRequest/resolved` cleanup semantics are documented upstream and remain an explicit notification-coverage gap in the current Swift layer.
- The remaining work stated here matches the current Milestone 2 focus in `/Users/galew/Workspace/Codax/ROADMAP.md`.

## Files Reviewed

Swift connection layer:

- `/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection+Messages.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection+Types.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+InboundMessage.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerNotificationEnvelope.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerNotificationTypes.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerRequestHandler.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerRequestHandlerEnvelope.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerRequestHandlerTypes.swift`

Adjacent context:

- `/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexTransport.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexTransport+Types.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexProcess.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexProcess+Types.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator+Types.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/AuthCoordinator.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/AuthCoordinator+Types.swift`
- `/Users/galew/Workspace/Codax/ROADMAP.md`
- `/Users/galew/Workspace/Codax/Docs/TRANSPORT_SCHEMA_REPORT.md`

Primary schema roots:

- `~/Workspace/codex-schemas/v0.111.0/RequestId.ts`
- `~/Workspace/codex-schemas/v0.111.0/ServerRequest.ts`
- `~/Workspace/codex-schemas/v0.111.0/ServerNotification.ts`
- `~/Workspace/codex-schemas/v0.111.0/ClientRequest.ts`

Primary external references:

- [Codex App Server docs](https://developers.openai.com/codex/app-server/)
- [codex-rs app-server README](https://github.com/openai/codex/blob/main/codex-rs%2Fapp-server%2FREADME.md)
