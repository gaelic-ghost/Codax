# Orchestration Schema Report

## Summary

`CodaxOrchestrator` is now the app-state projection layer, not the runtime assembly layer.

It owns:

- connect flow and compatibility gating
- active thread and thread list state
- active turn plan, diff, token-usage, and error state
- notification-to-state reduction
- app-facing async commands such as `connect()`, `loadThreads()`, `startThread()`, and `startTurn()`

It does not own:

- `CodexProcess`
- `CodexConnection`
- `CodexClient`
- the server-request responder implementation

Those lower-level concerns are now owned by `CodexRuntimeCoordinator`.

## Current Ownership Chain

The orchestration layer now sits above a dedicated runtime boundary:

- `CodexRuntimeCoordinator`
  - owns process, connection, client, notification forwarding, and server-request forwarding
- `CodaxOrchestrator`
  - subscribes to runtime streams and maps typed events to observable state
- SwiftUI views
  - read app state from the orchestrator and invoke app-facing async actions

This is the main change relative to earlier architecture reports. `CodaxOrchestrator` is no longer responsible for raw runtime assembly or for directly installing the server-request responder onto the connection.

## Runtime Relationship

`CodaxOrchestrator` now depends on:

- `CodexRuntimeCoordinator.start()`
- `CodexRuntimeCoordinator.initialize(_:)`
- `CodexRuntimeCoordinator.sendInitialized()`
- `CodexRuntimeCoordinator.notifications()`
- `CodexRuntimeCoordinator.serverRequests()`
- `CodexRuntimeCoordinator.client()`
- `CodexRuntimeCoordinator.stop()`

That means the orchestrator owns consumption of runtime outputs, not construction of lower-level runtime parts.

## Event Consumption Model

The orchestrator currently starts two tasks after connect:

### Notification Task

Consumes `AsyncStream<ServerNotificationEnvelope>` and applies the typed notification subset to app state.

This currently drives:

- account state updates
- login completion state
- active thread state
- thread status updates
- token-usage updates
- turn completion state
- active plan state
- active diff state
- turn error state

### Server Request Task

Consumes `AsyncStream<ServerRequestEnvelope>`.

This stream is wired now even though the reducer is currently a no-op. That is intentional: the runtime boundary already surfaces reply-required server requests upward, even before Codax has real app policy for approvals, elicitation, or auth refresh.

## Current App-Facing State

The orchestrator currently owns:

- `account`
- `authMode`
- `threads`
- `activeThread`
- `connectionState`
- `loginState`
- `compatibility`
- `activeThreadTokenUsage`
- `activeTurnPlan`
- `activeTurnDiff`
- `activeError`
- `compatibilityDebugOutput`
- `isLoadingThreads`

This is the correct ownership level for UI-visible state.

## Current Gaps

- `loginWithChatGPT()` is still a placeholder.
- Server-request observation exists, but orchestration does not yet turn those requests into user-visible approval or auth flows.
- Notification coverage remains narrower than the full app-server notification surface, so some runtime changes are still preserved only as `.unknown(...)`.
- Item-level streaming notifications are decoded, but the orchestrator still only reduces a limited subset of the possible item lifecycle into visible UI state.

## Related Types

The orchestration layer still owns app-facing auth and compatibility types:

- `AuthMode`
- `PlanType`
- `LoginState`
- `Account`
- `CodaxCompatibilityState`

Those stay in orchestration because they are app/domain state, even when the same wire shapes are also used in client DTO decoding.

## File Ownership Notes

Current orchestration ownership is primarily centered on:

- [`CodaxOrchestrator.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift)
- [`CodaxOrchestrator+Types.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator+Types.swift)
- [`AuthCoordinator.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/AuthCoordinator.swift)
- [`AuthCoordinator+Types.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/AuthCoordinator+Types.swift)

Current orchestration descriptions should center on `CodexRuntimeCoordinator` as the runtime boundary and `CodaxOrchestrator` as the app-state projection layer.
