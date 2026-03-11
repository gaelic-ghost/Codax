# Connection Schema Report

## Summary

`CodexConnection` is the JSON-RPC boundary for Codax.

It is responsible for:

- generating request ids
- encoding outbound JSON-RPC requests and notifications
- matching inbound success and error responses to pending requests
- decoding inbound server notifications into `ServerNotificationEnvelope`
- decoding inbound server requests into `ServerRequestEnvelope`
- delegating reply-required server requests to `CodexServerRequestResponder`
- serializing the responder's `ServerRequestResponse` back onto the transport
- retrying retryable overload errors with bounded backoff

It is not responsible for runtime ownership, app-state mutation, or UI policy. Those concerns now sit above it in `CodexRuntimeCoordinator` and `CodaxOrchestrator`.

## Current Ownership

The current layering around connection is:

- `CodexTransport`
  - raw bytes
- `CodexConnection`
  - JSON-RPC framing, correlation, routing, and reply mechanics
- `CodexRuntimeCoordinator`
  - owns the live connection and forwards app-facing streams upward
- `CodaxOrchestrator`
  - consumes typed events and projects them into app state

That separation is now explicit in code. `CodexConnection` no longer sits in a direct ownership relationship with `CodaxOrchestrator`.

## Connection Surface

The relevant connection-facing public behavior is:

- `request(method:params:as:)`
- `notify(method:params:)`
- `notify(method:)`
- `start()`
- `stop()`
- `notifications() -> AsyncStream<ServerNotificationEnvelope>`

`CodexConnection` intentionally exposes only the notification stream directly. The separate server-request stream is owned by `CodexRuntimeCoordinator`, which observes requests through the installed responder path and forwards them upward as runtime events.

## Inbound Routing Model

`CodexConnection` currently handles inbound messages in three categories:

### Responses

- success responses complete pending one-shot waiters keyed by `JSONRPCID`
- error responses fail pending requests with `CodexConnectionError.serverError`

### Notifications

Inbound method objects without `id` decode through `ServerNotificationEnvelope.decode(...)` and are yielded on the connection-owned notification stream.

### Server Requests

Inbound method objects with `id` decode through `ServerRequestEnvelope.decode(...)`, are passed to the installed `CodexServerRequestResponder`, and are then encoded back into either:

- a typed JSON-RPC result response
- a JSON-RPC error response when the responder returns `.unhandled`

This is why requests and notifications remain separate at the protocol boundary even though both originate from inbound server method messages.

## Current Typed Inbound Coverage

### Notifications

The current typed notification subset is:

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

Everything else currently falls through to `.unknown(method:raw:)`.

### Server Requests

The current typed server-request envelope covers:

- `account/chatgptAuthTokens/refresh`
- `item/fileChange/requestApproval`
- `applyPatchApproval`
- `item/tool/requestUserInput`
- `item/tool/call`
- `mcpServer/elicitation/request`
- `item/commandExecution/requestApproval`
- `execCommandApproval`

The envelope is complete for the currently known method union, with `.unknown(method:id:raw:)` retained for forward compatibility.

## Current Strengths

- Request correlation is correct and actor-owned.
- Disconnect behavior is coherent: pending requests fail and notification streams finish.
- Retryable overload handling is connection-owned where it belongs.
- Reply-required server requests stay in the connection layer instead of leaking JSON-RPC mechanics upward.

## Current Gaps

- Notification coverage is still a curated subset of the wider app-server notification surface.
- The default responder path currently surfaces server requests upward but still answers `.unhandled`.
- `CodexConnection` still only exposes notifications directly; that is intentional, but it means runtime documentation must explain that request observation now happens one layer up.

## File Ownership Notes

The connection layer now depends on:

- [`CodexConnection.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection.swift)
- [`CodexConnection+Types.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection+Types.swift)
- [`CodexClient+ServerNotificationTypes.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerNotificationTypes.swift)
- [`CodexClient+ServerRequestTypes.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerRequestTypes.swift)
- [`CodexRuntimeCoordinator.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Runtime/CodexRuntimeCoordinator.swift)

The current connection ownership should be read from the files above and from the runtime coordinator boundary, not from older report-era file layouts.
