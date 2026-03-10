# Orchestration Schema Report

## Summary

This report maps the current orchestration-facing implementation in `/Users/galew/Workspace/Codax/Codax.xcodeproj` onto the intended Milestone 5 orchestration slice described in the repo roadmap.

It is intentionally different from the transport, connection, and client reports in one important way: orchestration is only partially implemented. The goal here is not to pretend that there is a mature orchestration contract already in place. The goal is to define the actual app-facing coordination boundary in this repo today, explain how it sits on top of the lower layers that already exist, and call out the concrete gaps that still separate the current implementation from a finished orchestration layer.

The main conclusion is:

- The orchestration layer is the app-facing coordination boundary between:
  - lower protocol/runtime layers such as `CodexProcess`, `CodexTransport`, `CodexConnection`, and `CodexClient`
  - higher SwiftUI app state and the current `NavigationSplitView` shell
- The current Swift split is directionally correct:
  - `CodaxOrchestrator` is the intended observable app-session owner
  - `AuthCoordinator` is the intended auth-side effect boundary for opening login URLs or future auth handoff behavior
  - `ConnectionState`, `LoginState`, `Account`, and thread-facing models already give the layer an initial state vocabulary
- The current implementation is no longer pure scaffolding. It now owns compatibility checks, runtime startup, connection handshake, thread selection, and first-pass notification-driven state updates.
- The biggest gaps are not naming or architecture. They are missing depth and finish:
  - login is still placeholder-level
  - server-request handling is still minimal
  - thread and turn state are still incomplete relative to the broader app-server surface
  - durable local identity and persistence are still unsettled
- The next orchestration slice should stay tightly aligned with Milestone 5:
  - deeper account and login bootstrap
  - fuller thread loading and turn progression
  - stronger server-request handling
  - richer notification-driven app state updates

## Scope And Boundary

This report is about the `Orchestration` layer only.

It does not attempt to restate the full transport, connection, or client reports. It also does not define final UI composition, pane layout, or rendering behavior. Instead, it documents the layer that should coordinate those lower runtime pieces into observable app state consumable by SwiftUI.

### In Scope

- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator+Types.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/AuthCoordinator.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/AuthCoordinator+Types.swift`

### Orchestration-Adjacent Dependencies

- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+Thread.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+Turn.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+ServerNotificationEnvelope.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Connection/CodexConnection+Types.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Transport/CodexProcess.swift`

These files matter because the orchestrator is expected to consume them, not replace them.

### Explicitly Adjacent But Separate

- `CodexProcess`, `CodexTransport`, and `StdioCodexTransport`
  - process launch, byte transport, and stdio framing
- `CodexConnection`
  - JSON-RPC lifecycle, correlation, receive-loop behavior, and server-request dispatch
- `CodexClient`
  - typed request wrappers and typed endpoint DTOs
- SwiftUI views
- `ContentView`, `SidebarView`, `DetailView`, and the current `NavigationSplitView` shell

That separation is important because the orchestration layer should coordinate lower-layer behavior into app state. It should not absorb transport mechanics, generic JSON-RPC ownership, or final view composition.

## Source Of Truth

This report was grounded in five sources, in descending order of importance.

### 1. Local Orchestration Code

Primary local roots:

- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator+Types.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/AuthCoordinator.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/AuthCoordinator+Types.swift`

These files define the actual orchestration surface that exists in the repo today.

### 2. Adjacent Lower-Layer Types

The orchestration layer depends directly on lower-level state and API surfaces such as:

- `CodexClient`
- `Thread`
- `Turn`
- `ServerNotificationEnvelope`
- `ConnectionState`

These types establish what the orchestrator can realistically coordinate without re-owning lower-layer protocol details.

### 3. Repo Documentation

The orchestration role is also described in:

- `/Users/galew/Workspace/Codax/README.md`
- `/Users/galew/Workspace/Codax/ROADMAP.md`
- `/Users/galew/Workspace/Codax/CONTRIBUTING.md`

These documents are especially important because orchestration is more roadmap-driven than schema-driven at the moment.

### 4. Existing Layer Reports

Boundary consistency was checked against:

- `/Users/galew/Workspace/Codax/Docs/TRANSPORT_SCHEMA_REPORT.md`
- `/Users/galew/Workspace/Codax/Docs/CONNECTION_SCHEMA_REPORT.md`
- `/Users/galew/Workspace/Codax/Docs/CLIENT_SCHEMA_REPORT.md`

Those reports already describe the lower layers that orchestration is supposed to sit above.

### 5. Official App-Server Documentation

- [developers.openai.com/codex/app-server](https://developers.openai.com/codex/app-server/)

This matters only indirectly here. The orchestration report should not restate protocol rules already owned by the lower-layer reports, but it does need to respect behavior that constrains orchestration flow:

- `initialize` then `initialized`
- account/login bootstrap through typed client methods
- server notifications as the source for incremental thread and turn state changes

## Current Orchestration Contract

### 1. Orchestration Is The App-Facing Coordination Layer

Within this repo, orchestration should be understood as the layer that:

- owns app-session lifecycle
- coordinates connection and login flow
- maps thread and turn operations onto observable app state
- receives server notifications and applies them to app-consumable state
- exposes async entrypoints that SwiftUI can call without directly depending on lower protocol/runtime details

That is a narrower and cleaner responsibility than:

- process launch
- raw transport
- JSON-RPC routing
- DTO completeness for every client endpoint
- final UI layout and rendering decisions

### 2. `CodaxOrchestrator.swift` Defines The Intended Session Boundary

`CodaxOrchestrator.swift` is currently the clearest expression of the intended orchestration contract, and it now contains a real first slice of behavior.

The current observable state includes:

- `account: Account?`
- `authMode: AuthMode?`
- `threads: [Thread]`
- `activeThread: Thread?`
- `connectionState: ConnectionState`
- `loginState: LoginState`
- `compatibility: CodaxCompatibilityState`
- `activeThreadTokenUsage: ThreadTokenUsage?`
- `activeTurnPlan: [TurnPlanStep]`
- `activeTurnDiff: String?`
- `activeError: String?`
- `isLoadingThreads: Bool`

The current async entrypoints are:

- `connect()`
- `loginWithChatGPT()`
- `loadThreads()`
- `startThread()`
- `startTurn()`
- `handle(_ notification: ServerNotificationEnvelope)`

Those methods are no longer empty, and they indicate the intended public behavior of the orchestration layer:

- establish or resume a session
- drive login initiation
- surface thread inventory and active-thread state
- start work on a selected or new thread
- react to server notifications without exposing lower-layer notification routing directly to the views

### 3. `CodaxOrchestrator+Types.swift` Defines Runtime And Compatibility Surface

The orchestration-specific types currently defined there include:

- `CodaxOrchestrationRuntime`
- `CodaxCompatibilityState`

That is materially different from the earlier placeholder phase. The runtime bundle now captures the concrete lower-layer objects the orchestrator owns, and compatibility is now first-class app state rather than a future concern.

### 4. `AuthCoordinator.swift` Is A Side-Effect Boundary, Not A Full Auth System

`AuthCoordinator` is currently just a protocol:

- `openAuthURL(_ url: URL) async throws`

That is an intentionally small but useful orchestration boundary. It suggests the repo wants auth side effects, such as opening a browser-based ChatGPT login URL, to be abstracted away from `CodaxOrchestrator` itself.

That is a good ownership direction because the orchestrator should decide when auth needs to happen, while a coordinator can own how external auth is handed off.

### 5. `AuthCoordinator+Types.swift` Owns App-Facing Auth State

This file currently owns:

- `AuthMode`
- `PlanType`
- `LoginState`
- `Account`

Those are naturally orchestration-facing types and remain a sensible place for app-visible auth/account state.

The client-owned account/login request and response DTOs now live under `CodexClient+Account.swift`, which restores the intended boundary between wire payloads and orchestration state.

## Swift Ownership By Layer

### 1. Lower Layers Own Runtime And Protocol Mechanics

The transport, connection, and client layers already own the lower-level concerns that orchestration should consume:

- `CodexProcess`
  - local `codex app-server` process launch and shutdown
- `CodexTransport`
  - raw byte send/receive/close
- `CodexConnection`
  - generic JSON-RPC request, notify, receive-loop, retry, and inbound dispatch behavior
- `CodexClient`
  - typed request wrappers like `initialize(_:)`, `startThread(_:)`, `readAccount(_:)`, and `startTurn(_:)`

Orchestration should not re-implement any of those concerns.

### 2. Orchestration Should Own App Session State

The intended Swift ownership for orchestration is:

- connection lifecycle state suitable for the UI
- login/auth state suitable for the UI
- app-level thread/session selection state
- active thread and turn workflow initiation
- notification-to-state mapping
- app-facing async operations that views can invoke directly

In other words, orchestration should transform:

- lower-layer request methods and notification streams

into:

- stable observable app state
- bounded app actions

### 3. Views Should Consume Orchestration, Not Lower Layers Directly

The current split-view shell should be able to bind to orchestration state such as:

- connection status
- login status
- thread list
- active thread
- loading/error state

without needing to know about:

- process launch
- JSON-RPC retries
- transport shutdown rules
- wire-level server notification variants

That is the main architectural reason this orchestration layer should exist as a first-class layer rather than having SwiftUI views talk directly to `CodexClient` or `CodexConnection`.

## Current Alignment

### 1. The Layer Boundary Is Conceptually Correct

The repo already describes orchestration consistently across code and docs:

- `README.md` says `CodaxOrchestrator` and `AuthCoordinator` are intended to become the app-facing session and auth coordination layer.
- `ROADMAP.md` treats orchestration as a bounded milestone that comes after transport, connection, client, and version compatibility.
- `CONTRIBUTING.md` explicitly calls out orchestration as one of the still-early layers.

That is good alignment. The repo is not confused about where orchestration belongs or why it exists.

### 2. The Current State Vocabulary Is A Reasonable First Pass

Even though the implementation is still transitional, the current state vocabulary is useful:

- `ConnectionState` already expresses disconnected vs connecting vs connected
- `LoginState` already expresses signed-out, authorizing, signed-in, and failure cases
- `Account` and `AuthMode` already express the main account/login modes visible to the app
- `Thread`, `Turn`, and `ServerNotificationEnvelope` already provide enough domain material for a first orchestration slice

That means the next implementation step is mostly deeper behavior and model tightening, not naming discovery.

### 3. The Orchestrator Entry Points Match The Roadmap Slice

The current methods in `CodaxOrchestrator.swift` already point in the right direction for Milestone 5:

- `connect()`
- `loginWithChatGPT()`
- `loadThreads()`
- `startThread()`
- `startTurn()`
- `handle(_:)`

Those align well with the roadmap’s stated goals, and several are now behaviorally real rather than placeholders:

- real connection lifecycle
- login flow
- thread loading and session control
- start-turn flows
- notification-driven state updates

## Gaps / Drift

### 1. Runtime Ownership Exists, But It Is Still Narrow

The current orchestrator now has:

- concrete `CodexClient`, `CodexConnection`, and optional `CodexProcess` ownership
- compatibility preflight before connect
- `initialize` then `initialized`
- notification-task ownership
- runtime teardown behavior

The remaining gap is not total absence of runtime ownership. It is that the lifecycle is still only a first slice and not yet a full app-session policy.

### 2. Handshake Exists, But Account And Login Bootstrap Are Still Thin

The lower layers already support the pieces needed for a real startup flow:

- process launch
- `initialize`
- `initialized`
- `account/read`
- login start/cancel

But the orchestration layer does not yet compose those calls into a fuller product-facing bootstrap, including:

- account inspection
- login-needed state
- login continuation or completion handling

This is one of the largest remaining functional gaps between the lower layers and a usable app shell.

### 3. Notification Subscription Exists, But Coverage Is Still Partial

`CodexConnection` can already expose `AsyncStream<ServerNotificationEnvelope>`.

The orchestration layer now has:

- a notification subscription task
- receive-loop ownership at the app level
- first-pass application of incoming thread/turn/account notifications to observable state

The remaining gap is breadth and fidelity. The current reducer is enough for early connect and thread flows, but not yet complete for the broader app-server surface.

### 4. There Is No Real State Machine Beyond Simple Enums

The current enums are useful, but they are only vocabulary, not orchestration policy.

There is currently no implemented behavior for:

- transition from `.disconnected` to `.connecting` to `.connected`
- transition from `.signedOut` to `.authorizing` to `.signedIn`
- failure rollback or reconnect handling
- active-thread replacement or clearing
- loading vs empty vs failed thread-list states

That missing behavior is expected in an early alpha, but it is still a major current gap.

### 5. Auth And Client Ownership Are Now Better Separated

The client-owned account/login DTOs now live under `Client`, while `AuthCoordinator+Types.swift` keeps the app-facing state types used by the orchestrator and notifications.

That is a cleaner boundary and removes one of the earlier ownership drifts between `Client` and `Orchestration`.

### 6. Views Read Shared State Directly

The current SwiftUI shell now reads shared state directly from an environment-injected `CodaxOrchestrator`.

That means pane models are no longer a shared-state adaptation layer. The only remaining pane-local model is for ephemeral UI state such as local drafts. Shared session state, thread selection, and compatibility state are all owned directly by the orchestrator.

### 7. Compatibility Surfacing Is Now Seeded But Not Complete

The roadmap places compatibility warnings and errors into `CodaxOrchestrator` or `AuthCoordinator` state as part of the Version Compatibility milestone.

The current orchestration layer now has a real compatibility-facing state surface, but it is not yet the full product behavior implied by later milestones.

Remaining work still includes:

- local Codex version status
- compatibility warnings

That is still an active orchestration concern and should be treated as part of the near-future contract.

## Recommended Next Slice

The next orchestration slice should stay narrow and milestone-aligned. The goal is not to finish the entire app shell. The goal is to make the orchestration layer complete enough that the current split-view UI can bind to it more faithfully.

### 1. Deepen Process, Connection, And Client Lifecycle Ownership

`CodaxOrchestrator` is already the concrete owner of:

- process launch through `CodexProcess`
- transport acquisition
- `CodexConnection`
- `CodexClient`

The next slice should deepen that ownership with stronger reconnect policy, fuller error handling, and clearer session teardown semantics at the app-session level.

### 2. Extend Handshake Into Account/Login Bootstrap

The first usable `connect()` flow now:

- run compatibility preflight
- launch the local app-server
- create the connection/client stack
- send `initialize`
- send `initialized`
- start notification listening
- load current thread state

The next gap is to extend that into account inspection, login-needed state, and richer startup decisions for the real app shell.

### 3. Broaden Notification Application To Observable State

The orchestration layer already owns a notification task that:

- listens to `ServerNotificationEnvelope`
- routes notifications into `handle(_:)`
- updates account, thread, turn, and related app state incrementally

This is the key bridge between the already-implemented connection layer and the current UI shell. The next step is broader and more faithful state reduction.

### 4. Expose Fuller Thread Loading And Thread Start/Resume Actions

The next slice should implement enough thread behavior for the current split-view shell to function more fully:

- load available or current thread state more faithfully
- start a new thread
- resume or read an existing thread
- start a turn on the active thread

This should stay app-facing and state-oriented rather than exposing raw client calls directly to the views.

### 5. Defer Non-Blocking Cleanup

The next orchestration slice should explicitly defer:

- broader UI polish and accessibility refinement
- persistence and durable local identity decisions
- broader client endpoint expansion

Those are all real future needs, but they should not block making orchestration functional for Milestone 5.

## Conclusion

The current orchestration layer is correctly placed and now behaviorally real in a first slice, but it is not yet complete.

That is not a sign of architectural confusion. It is a consequence of the project’s deliberate sequencing. Transport, connection, and initial client work have been brought forward first, and the repo already documents orchestration as the next bounded slice above them.

The most important takeaway is simple:

- the orchestration layer should remain the app-facing coordination boundary above `CodexClient` and below SwiftUI
- the current code already has the right nouns and initial ownership in place
- the missing work is deeper lifecycle policy, richer notification-driven state updates, fuller login or account behavior, and stronger app-facing thread modeling

If the next implementation work stays focused on that bounded contract, the repo can keep refining the current split-view milestone without collapsing lower-layer concerns into the app shell.
