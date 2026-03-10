# Orchestration Schema Report

## Summary

This report maps the current orchestration-facing scaffolding in `/Users/galew/Workspace/Codax/Codax.xcodeproj` onto the intended Milestone 5 orchestration slice described in the repo roadmap.

It is intentionally different from the transport, connection, and client reports in one important way: orchestration is not yet a fully implemented protocol-facing layer. The goal here is not to pretend that there is a mature orchestration contract already in place. The goal is to define the actual app-facing coordination boundary in this repo today, explain how it should sit on top of the lower layers that already exist, and call out the concrete gaps that still separate the current scaffolding from a functioning orchestration implementation.

The main conclusion is:

- The orchestration layer is the app-facing coordination boundary between:
  - lower protocol/runtime layers such as `CodexProcess`, `CodexTransport`, `CodexConnection`, and `CodexClient`
  - higher SwiftUI app state and future `NavigationSplitView` views
- The current Swift split is directionally correct:
  - `CodaxOrchestrator` is the intended observable app-session owner
  - `AuthCoordinator` is the intended auth-side effect boundary for opening login URLs or future auth handoff behavior
  - `ConnectionState`, `LoginState`, `Account`, and thread-facing models already give the layer an initial state vocabulary
- The current implementation is still scaffolding rather than a functioning orchestration layer.
- The biggest gaps are not naming or architecture. They are missing lifecycle behavior:
  - no concrete process/transport/client ownership
  - no initialization handshake flow
  - no login bootstrap behavior
  - no notification subscription and state application
  - no durable thread/session summary model beyond `ThreadSummary = Thread`
- The next orchestration slice should stay tightly aligned with Milestone 5:
  - connect
  - initialize
  - account/login bootstrap
  - thread loading/start/resume
  - turn start
  - notification-driven app state updates

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
  - `ContentView`, `SidebarView`, `DetailView`, and the planned `NavigationSplitView` shell

That separation is important because the orchestration layer should coordinate lower-layer behavior into app state. It should not absorb transport mechanics, generic JSON-RPC ownership, or final view composition.

## Source Of Truth

This report was grounded in five sources, in descending order of importance.

### 1. Local Orchestration Code

Primary local roots:

- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator+Types.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/AuthCoordinator.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/AuthCoordinator+Types.swift`

These files define the actual orchestration surface that exists in the repo today, even though much of it is still placeholder-level.

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

`CodaxOrchestrator.swift` is currently the clearest expression of the intended orchestration contract, even though it is mostly unimplemented.

The current observable state includes:

- `account: Account?`
- `authMode: AuthMode?`
- `threads: [ThreadSummary]`
- `activeThread: Thread?`
- `connectionState: ConnectionState`
- `loginState: LoginState`

The current async entrypoints are:

- `connect()`
- `loginWithChatGPT()`
- `loadThreads()`
- `startThread()`
- `startTurn()`
- `handle(_ notification: ServerNotificationEnvelope)`

Those methods are all empty today, but they still indicate the intended public behavior of the orchestration layer:

- establish or resume a session
- drive login initiation
- surface thread inventory and active-thread state
- start work on a selected or new thread
- react to server notifications without exposing lower-layer notification routing directly to the views

### 3. `CodaxOrchestrator+Types.swift` Is Currently Minimal

The only orchestration-specific type currently defined there is:

- `ThreadSummary = Thread`

That is usable as scaffolding, but it should be treated as a temporary shortcut rather than a durable orchestration-facing summary model. A full `Thread` is a client/domain object, not necessarily the right stable shape for sidebar-oriented app state.

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

The future split-view shell should be able to bind to orchestration state such as:

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

Even though the implementation is still a shell, the current state vocabulary is useful:

- `ConnectionState` already expresses disconnected vs connecting vs connected
- `LoginState` already expresses signed-out, authorizing, signed-in, and failure cases
- `Account` and `AuthMode` already express the main account/login modes visible to the app
- `Thread`, `Turn`, and `ServerNotificationEnvelope` already provide enough domain material for a first orchestration slice

That means the next implementation step is mostly behavior and ownership wiring, not naming discovery.

### 3. The Orchestrator Entry Points Match The Roadmap Slice

The empty methods in `CodaxOrchestrator.swift` already point in the right direction for Milestone 5:

- `connect()`
- `loginWithChatGPT()`
- `loadThreads()`
- `startThread()`
- `startTurn()`
- `handle(_:)`

Those align well with the roadmap’s stated goals:

- real connection lifecycle
- login flow
- thread loading and session control
- start-turn flows
- notification-driven state updates

## Gaps / Drift

### 1. `CodaxOrchestrator` Has No Concrete Runtime Ownership Yet

The current orchestrator has:

- no concrete `CodexClient`
- no `CodexConnection`
- no `CodexProcess`
- no transport ownership
- no setup or teardown behavior

That means the most important orchestration responsibility, owning the app-facing session lifecycle, does not exist yet in behavior.

### 2. There Is No Real Handshake Or Account Bootstrap Flow

The lower layers already support the pieces needed for a real startup flow:

- process launch
- `initialize`
- `initialized`
- `account/read`
- login start/cancel

But the orchestration layer does not currently compose those calls into:

- connect
- initialize
- account inspection
- login-needed state
- login continuation or completion handling

This is the largest functional gap between the lower layers and a usable app shell.

### 3. There Is No Notification Subscription Or State Application Loop

`CodexConnection` can already expose `AsyncStream<ServerNotificationEnvelope>`.

But the orchestration layer currently has:

- no notification subscription task
- no receive-loop ownership at the app level
- no application of incoming thread/turn/account notifications to observable state

Without that behavior, even a successful initial request flow would leave the app unable to reflect streamed or incremental server updates correctly.

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

### 6. `ThreadSummary = Thread` Is Only Temporary

Using `Thread` directly as a summary object works for scaffolding, but it is not a durable orchestration boundary.

It couples app-level sidebar or summary state to:

- the full client thread payload
- client DTO evolution
- fields that may be irrelevant to the UI shell

That shortcut is acceptable for Milestone 5 if it keeps implementation moving, but it should not be mistaken for a finished orchestration model.

### 7. Compatibility Surfacing Is Now Seeded But Not Complete

The roadmap places compatibility warnings and errors into `CodaxOrchestrator` or `AuthCoordinator` state as part of the Version Compatibility milestone.

The current orchestration layer now has an initial compatibility-facing state surface, but it is not yet the full product behavior implied by later milestones.

Remaining work still includes:

- local Codex version status
- unsupported-version blocking
- compatibility warnings

That is still an active orchestration concern and should be treated as part of the near-future contract.

## Recommended Next Slice

The next orchestration slice should stay narrow and milestone-aligned. The goal is not to finish the entire app shell. The goal is to make the orchestration layer real enough that the planned split-view UI can bind to it.

### 1. Own Process, Transport, Connection, And Client Lifecycle

`CodaxOrchestrator` should become the concrete owner of:

- process launch through `CodexProcess`
- transport acquisition
- `CodexConnection`
- `CodexClient`

That ownership should include predictable connection startup and shutdown behavior at the app-session level.

### 2. Implement Handshake And Account/Login Bootstrap

The first usable `connect()` flow should:

- launch the local app-server
- create the connection/client stack
- send `initialize`
- send `initialized`
- read account state
- map the result into `connectionState`, `loginState`, `account`, and `authMode`

That is the minimum orchestration behavior needed to move from placeholder shell to real app session bootstrap.

### 3. Subscribe To Notifications And Apply Them To Observable State

The orchestration layer should own a notification task that:

- listens to `ServerNotificationEnvelope`
- routes notifications into `handle(_:)`
- updates account, thread, turn, and related app state incrementally

This is the key bridge between the already-implemented connection layer and the future UI shell.

### 4. Expose Thread Loading And Thread Start/Resume Actions

The next slice should implement enough thread behavior for the future split-view shell to function:

- load available or current thread state
- start a new thread
- resume or read an existing thread
- start a turn on the active thread

This should stay app-facing and state-oriented rather than exposing raw client calls directly to the views.

### 5. Defer Non-Blocking Cleanup

The next orchestration slice should explicitly defer:

- final `NavigationSplitView` layout design
- broader UI polish and accessibility refinement
- full DTO ownership cleanup
- broader client endpoint expansion

Those are all real future needs, but they should not block making orchestration functional for Milestone 5.

## Conclusion

The current orchestration layer is correctly placed but not yet behaviorally real.

That is not a sign of architectural confusion. It is a consequence of the project’s deliberate sequencing. Transport, connection, and initial client work have been brought forward first, and the repo already documents orchestration as the next bounded slice above them.

The most important takeaway is simple:

- the orchestration layer should remain the app-facing coordination boundary above `CodexClient` and below SwiftUI
- the current code already has the right nouns and entrypoints
- the missing work is concrete lifecycle implementation, notification-driven state updates, and a thinner but real session model for the UI to bind to

If the next implementation work stays focused on that bounded contract, the repo can move into the `NavigationSplitView` milestone without collapsing lower-layer concerns into the app shell.
