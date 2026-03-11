# `CodaxOrchestrator` Call Graph

## Summary

This document describes every current call path into and within [`CodaxOrchestrator.swift`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift).

Call sources are classified into:

- UI entrypoints
- runtime/task-driven calls
- self-calls and internal helper flow
- test-only calls

The analysis is strictly current-state. It documents the code as it exists today, including placeholders and no-op handlers.

## Function Surface

Declared on `CodaxOrchestrator`:

- `init()`
- `internal init(compatibilityProbe:runtimeFactory:initializeParamsFactory:)`
- `internal convenience init(compatibilityProbe:runtimeFactory:)`
- `connect()`
- `loginWithChatGPT()`
- `loadThreads()`
- `startThread()`
- `startTurn(inputText:)`
- `selectThread(codexId:)`
- `handle(_ notification: ServerNotificationEnvelope)`
- `handle(_ request: ServerRequestEnvelope)`
- `refreshCompatibility()`

Declared in the private extension:

- `makeRuntime()`
- `makeInitializeParams()`
- `startNotificationTask(runtimeCoordinator:)`
- `startServerRequestTask(runtimeCoordinator:)`
- `teardownRuntime()`
- `upsertThread(_:)`
- `updateThread(codexId:mutation:)`
- `merge(turn:intoThreadCodexId:)`
- `merge(turnError:intoThreadCodexId:turnCodexId:)`

## Public / App-Facing Methods

### `init()`

Signature:
- `init()`

Direct callers:
- [`CodaxApp.swift:17`](/Users/galew/Workspace/Codax/Codax/CodaxApp.swift#L17) via `@State private var orchestrator = CodaxOrchestrator()`
- [`ContentView.swift:125`](/Users/galew/Workspace/Codax/Codax/Views/ContentView.swift#L125) in preview environment injection
- [`SidebarView.swift:65`](/Users/galew/Workspace/Codax/Codax/Views/SidebarView.swift#L65) in preview environment injection
- [`DetailView.swift:92`](/Users/galew/Workspace/Codax/Codax/Views/DetailView.swift#L92) in preview environment injection

Internal callees:
- `CodaxOrchestrator.makeRuntime()`
- `CodaxOrchestrator.makeInitializeParams()`

State initialized:
- sets default compatibility probe
- sets runtime factory closure
- sets initialize-params factory closure

Notes:
- Production-used.
- Also used by previews.

### `internal init(compatibilityProbe:runtimeFactory:initializeParamsFactory:)`

Signature:
- `internal init(compatibilityProbe:runtimeFactory:initializeParamsFactory:)`

Direct callers:
- [`CodaxOrchestrator.swift:62`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L62) from the convenience initializer

Direct external/test callers:
- none

State initialized:
- injects all three dependencies directly

Notes:
- Helper initializer.
- No production call sites outside the type itself.

### `internal convenience init(compatibilityProbe:runtimeFactory:)`

Signature:
- `internal convenience init(compatibilityProbe:runtimeFactory:)`

Direct callers:
- [`CodaxOrchestratorTests.swift:8`](/Users/galew/Workspace/Codax/CodaxTests/Orchestration/CodaxOrchestratorTests.swift#L8)
- [`CodaxOrchestratorTests.swift:31`](/Users/galew/Workspace/Codax/CodaxTests/Orchestration/CodaxOrchestratorTests.swift#L31)
- [`CodaxOrchestratorTests.swift:312`](/Users/galew/Workspace/Codax/CodaxTests/Orchestration/CodaxOrchestratorTests.swift#L312) through `makeConnectedOrchestrator(...)`

Internal callees:
- `CodaxOrchestrator.makeInitializeParams()`
- `internal init(compatibilityProbe:runtimeFactory:initializeParamsFactory:)`

Notes:
- Test-only.

### `connect()`

Signature:
- `func connect() async`

UI entrypoint callers:
- [`ContentView.swift:35`](/Users/galew/Workspace/Codax/Codax/Views/ContentView.swift#L35) from the "Connect" button task

Test-only callers:
- [`CodaxOrchestratorTests.swift:42`](/Users/galew/Workspace/Codax/CodaxTests/Orchestration/CodaxOrchestratorTests.swift#L42)
- [`CodaxOrchestratorTests.swift:58`](/Users/galew/Workspace/Codax/CodaxTests/Orchestration/CodaxOrchestratorTests.swift#L58)
- [`CodaxOrchestratorTests.swift:59`](/Users/galew/Workspace/Codax/CodaxTests/Orchestration/CodaxOrchestratorTests.swift#L59)
- [`CodaxOrchestratorTests.swift:70`](/Users/galew/Workspace/Codax/CodaxTests/Orchestration/CodaxOrchestratorTests.swift#L70)
- [`CodaxOrchestratorTests.swift:82`](/Users/galew/Workspace/Codax/CodaxTests/Orchestration/CodaxOrchestratorTests.swift#L82)
- [`CodaxOrchestratorTests.swift:95`](/Users/galew/Workspace/Codax/CodaxTests/Orchestration/CodaxOrchestratorTests.swift#L95)
- [`CodaxOrchestratorTests.swift:112`](/Users/galew/Workspace/Codax/CodaxTests/Orchestration/CodaxOrchestratorTests.swift#L112)

Internal callees:
- `teardownRuntime()` when a runtime already exists
- `refreshCompatibility()`
- `runtimeFactory()`
- `runtimeCoordinator.start()`
- `initializeParamsFactory()`
- `runtimeCoordinator.initialize(_:)`
- `runtimeCoordinator.sendInitialized()`
- `startNotificationTask(runtimeCoordinator:)`
- `startServerRequestTask(runtimeCoordinator:)`
- `loadThreads()`
- `teardownRuntime()` on failure

State mutations:
- reads and guards on `connectionState`
- may clear previous runtime
- sets `connectionState` to `.connecting`, `.connected`, or `.disconnected`
- clears `activeError` before startup
- stores `runtimeCoordinator`
- on failure sets `activeError`

Trigger semantics:
- main user session bootstrap entrypoint
- also the main orchestration integration entrypoint used by tests

Notes:
- Production-used.
- Mixes compatibility probing, runtime lifecycle, handshake, stream wiring, and initial state load in one method.

### `loginWithChatGPT()`

Signature:
- `func loginWithChatGPT() async`

Direct callers:
- none

Internal callees:
- none

State mutations:
- sets `activeError` to placeholder text

Notes:
- No production callers.
- No test callers.
- Placeholder.

### `loadThreads()`

Signature:
- `func loadThreads() async`

Direct callers:
- [`CodaxOrchestrator.swift:100`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L100) from `connect()`

Test-only callers:
- [`CodaxOrchestratorTests.swift:101`](/Users/galew/Workspace/Codax/CodaxTests/Orchestration/CodaxOrchestratorTests.swift#L101)

Internal callees:
- `runtimeCoordinator?.client()`
- `client.readThread(...)`
- `upsertThread(_:)`

State mutations:
- toggles `isLoadingThreads`
- may clear `threads` and `activeThread`
- updates `activeThreadCodexId`
- updates `activeThread`
- updates `threads`
- sets `activeError` on failure

Trigger semantics:
- initial post-connect state load
- explicit test invocation

Notes:
- No direct production UI caller today.
- Production-used indirectly through `connect()`.

### `startThread()`

Signature:
- `func startThread() async`

UI entrypoint callers:
- [`ContentView.swift:42`](/Users/galew/Workspace/Codax/Codax/Views/ContentView.swift#L42) from the "Start Thread" button task
- [`SidebarView.swift:39`](/Users/galew/Workspace/Codax/Codax/Views/SidebarView.swift#L39) from the "New Thread" toolbar button task

Test-only callers:
- [`CodaxOrchestratorTests.swift:71`](/Users/galew/Workspace/Codax/CodaxTests/Orchestration/CodaxOrchestratorTests.swift#L71)
- [`CodaxOrchestratorTests.swift:83`](/Users/galew/Workspace/Codax/CodaxTests/Orchestration/CodaxOrchestratorTests.swift#L83)
- [`CodaxOrchestratorTests.swift:96`](/Users/galew/Workspace/Codax/CodaxTests/Orchestration/CodaxOrchestratorTests.swift#L96)
- [`CodaxOrchestratorTests.swift:113`](/Users/galew/Workspace/Codax/CodaxTests/Orchestration/CodaxOrchestratorTests.swift#L113)

Internal callees:
- `runtimeCoordinator?.client()`
- `client.startThread(...)`
- `upsertThread(_:)`

State mutations:
- clears `activeError`
- updates `activeThreadCodexId`
- updates `activeThread`
- clears `activeThreadTokenUsage`
- clears `activeTurnPlan`
- clears `activeTurnDiff`
- updates `threads`
- sets `activeError` on failure

Notes:
- Production-used directly from UI.

### `startTurn(inputText:)`

Signature:
- `func startTurn(inputText: String) async`

UI entrypoint callers:
- [`ContentView.swift:67`](/Users/galew/Workspace/Codax/Codax/Views/ContentView.swift#L67) from the "Send Turn" button task

Test-only callers:
- [`CodaxOrchestratorTests.swift:84`](/Users/galew/Workspace/Codax/CodaxTests/Orchestration/CodaxOrchestratorTests.swift#L84)

Internal callees:
- `runtimeCoordinator?.client()`
- `client.startTurn(...)`
- `merge(turn:intoThreadCodexId:)`

State mutations:
- clears `activeError`
- merges returned turn into the active thread
- sets `activeError` on failure

Trigger semantics:
- conversation input submission

Notes:
- Production-used directly from UI.

### `selectThread(codexId:)`

Signature:
- `func selectThread(codexId: String)`

UI entrypoint callers:
- [`CodaxApp.swift:38`](/Users/galew/Workspace/Codax/Codax/CodaxApp.swift#L38) from the sidebar selection binding setter

Internal callees:
- none

State mutations:
- sets `activeThreadCodexId`
- may set `activeThread` by looking up the selected thread in `threads`

Notes:
- Production-used directly from app-level selection plumbing.

### `handle(_ notification: ServerNotificationEnvelope)`

Signature:
- `func handle(_ notification: ServerNotificationEnvelope)`

Runtime-driven callers:
- [`CodaxOrchestrator.swift:343`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L343) from the task created in `startNotificationTask(runtimeCoordinator:)`

Test-only callers:
- [`CodaxOrchestratorTests.swift:115`](/Users/galew/Workspace/Codax/CodaxTests/Orchestration/CodaxOrchestratorTests.swift#L115)
- [`CodaxOrchestratorTests.swift:123`](/Users/galew/Workspace/Codax/CodaxTests/Orchestration/CodaxOrchestratorTests.swift#L123)
- [`CodaxOrchestratorTests.swift:131`](/Users/galew/Workspace/Codax/CodaxTests/Orchestration/CodaxOrchestratorTests.swift#L131)
- [`CodaxOrchestratorTests.swift:141`](/Users/galew/Workspace/Codax/CodaxTests/Orchestration/CodaxOrchestratorTests.swift#L141)

Internal callees:
- `merge(turnError:intoThreadCodexId:turnCodexId:)`
- `upsertThread(_:)`
- `updateThread(codexId:mutation:)`
- `merge(turn:intoThreadCodexId:)`

State mutations:
- may set `activeError`
- may update `authMode`
- may update `account`
- may update `loginState`
- may update `activeThreadCodexId`
- may update `activeThread`
- may update `threads`
- may update `activeThreadTokenUsage`
- may update `activeTurnPlan`
- may update `activeTurnDiff`

Ignored notification cases:
- `serverRequestResolved`
- all item-level delta/start/completed cases currently listed in the `return` group
- `unknown`

Notes:
- Production-used indirectly through the runtime notification stream.
- Directly test-invoked.

### `handle(_ request: ServerRequestEnvelope)`

Signature:
- `func handle(_ request: ServerRequestEnvelope)`

Runtime-driven callers:
- [`CodaxOrchestrator.swift:364`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L364) from the task created in `startServerRequestTask(runtimeCoordinator:)`

Direct test callers:
- none

Internal callees:
- none

State mutations:
- none

Trigger semantics:
- every surfaced runtime server-request event flows through this method

Notes:
- Production-wired.
- Operationally a no-op reducer today.

### `refreshCompatibility()`

Signature:
- `func refreshCompatibility() async`

Self-callers:
- [`CodaxOrchestrator.swift:79`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L79) from `connect()`

Test-only callers:
- [`CodaxOrchestratorTests.swift:18`](/Users/galew/Workspace/Codax/CodaxTests/Orchestration/CodaxOrchestratorTests.swift#L18)

Internal callees:
- `compatibilityProbe.debugProbeCompatibility()`
- `CodaxCompatibilityState.init(_:)`

State mutations:
- sets `compatibility` to `.checking`
- sets `compatibilityDebugOutput`
- sets final `compatibility`

Notes:
- Production-used indirectly through `connect()`.
- Directly test-invoked.

## Internal Helper Methods

### `makeRuntime()`

Signature:
- `static func makeRuntime() async throws -> CodexRuntimeCoordinator`

Direct callers:
- [`CodaxOrchestrator.swift:44`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L44) from the default initializer’s runtime-factory closure

Internal callees:
- `CodexRuntimeCoordinator.init()`

Notes:
- No direct production call sites outside stored closure initialization.
- Construction plumbing only.

### `makeInitializeParams()`

Signature:
- `static func makeInitializeParams() -> InitializeParams`

Direct callers:
- [`CodaxOrchestrator.swift:45`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L45) from the default initializer’s params-factory closure
- [`CodaxOrchestrator.swift:65`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L65) from the convenience initializer

Internal callees:
- `Bundle.main.object(forInfoDictionaryKey:)`

Notes:
- Initialization plumbing only.

### `startNotificationTask(runtimeCoordinator:)`

Signature:
- `func startNotificationTask(runtimeCoordinator: CodexRuntimeCoordinator)`

Direct callers:
- [`CodaxOrchestrator.swift:97`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L97) from `connect()`

Indirect/runtime downstream calls:
- invokes `self.handle(notification)` from inside the created task at [`CodaxOrchestrator.swift:343`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L343)

Internal callees:
- `runtimeCoordinator.notifications()`
- `handle(_ notification:)`

State mutations:
- replaces `notificationTask`
- may later set `connectionState = .disconnected` when the stream ends without task cancellation

Notes:
- Internal plumbing only.

### `startServerRequestTask(runtimeCoordinator:)`

Signature:
- `func startServerRequestTask(runtimeCoordinator: CodexRuntimeCoordinator)`

Direct callers:
- [`CodaxOrchestrator.swift:98`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L98) from `connect()`

Indirect/runtime downstream calls:
- invokes `self.handle(request)` from inside the created task at [`CodaxOrchestrator.swift:364`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L364)

Internal callees:
- `runtimeCoordinator.serverRequests()`
- `handle(_ request:)`

State mutations:
- replaces `serverRequestTask`

Notes:
- Internal plumbing only.
- Exists solely to consume the second runtime stream.

### `teardownRuntime()`

Signature:
- `func teardownRuntime() async`

Direct callers:
- [`CodaxOrchestrator.swift:76`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L76) from `connect()` when reusing a live runtime
- [`CodaxOrchestrator.swift:104`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L104) from `connect()` failure handling

Internal callees:
- `runtimeCoordinator.stop()`

State mutations:
- cancels and nils `notificationTask`
- cancels and nils `serverRequestTask`
- nils `runtimeCoordinator`

Notes:
- Internal lifecycle plumbing only.

### `upsertThread(_:)`

Signature:
- `func upsertThread(_ thread: Thread)`

Direct callers:
- [`CodaxOrchestrator.swift:120`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L120) from `loadThreads()` empty-active-thread branch
- [`CodaxOrchestrator.swift:132`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L132) from `loadThreads()` successful read
- [`CodaxOrchestrator.swift:167`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L167) from `startThread()`
- [`CodaxOrchestrator.swift:241`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L241) from `handle(_ notification:)` thread-started case
- [`CodaxOrchestrator.swift:395`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L395) from `updateThread(...)`

State mutations:
- inserts or replaces a thread in `threads`

Notes:
- Internal state helper.

### `updateThread(codexId:mutation:)`

Signature:
- `func updateThread(codexId: String, mutation: (inout Thread) -> Void)`

Direct callers:
- [`CodaxOrchestrator.swift:244`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L244) from `handle(_ notification:)` thread-status-changed case
- [`CodaxOrchestrator.swift:409`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L409) from `merge(turn:...)`
- [`CodaxOrchestrator.swift:419`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L419) from `merge(turnError:...)`

Internal callees:
- `upsertThread(_:)` in the active-thread branch

State mutations:
- mutates matching thread in `threads`
- may mutate `activeThread`

Notes:
- Internal state helper.

### `merge(turn:intoThreadCodexId:)`

Signature:
- `func merge(turn: Turn, intoThreadCodexId threadCodexId: String)`

Direct callers:
- [`CodaxOrchestrator.swift:199`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L199) from `startTurn(inputText:)`
- [`CodaxOrchestrator.swift:253`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L253) from `handle(_ notification:)` turn-started case
- [`CodaxOrchestrator.swift:256`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L256) from `handle(_ notification:)` turn-completed case

Internal callees:
- `updateThread(codexId:mutation:)`

State mutations:
- inserts or replaces a turn inside the matching thread

Notes:
- Internal state helper.

### `merge(turnError:intoThreadCodexId:turnCodexId:)`

Signature:
- `func merge(turnError: TurnError, intoThreadCodexId threadCodexId: String, turnCodexId: String)`

Direct callers:
- [`CodaxOrchestrator.swift:218`](/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/CodaxOrchestrator.swift#L218) from `handle(_ notification:)` error case

Internal callees:
- `updateThread(codexId:mutation:)`

State mutations:
- updates `error` on the matching turn inside the matching thread

Notes:
- Internal state helper.

## Call-Source View

### UI Entrypoints

Production UI calls currently reach these orchestrator methods:

- `init()`
  - app root and previews
- `connect()`
  - content view "Connect" button
- `startThread()`
  - content view "Start Thread" button
  - sidebar "New Thread" button
- `startTurn(inputText:)`
  - content view "Send Turn" button
- `selectThread(codexId:)`
  - app-level sidebar selection binding

No current UI call sites exist for:

- `loginWithChatGPT()`
- `loadThreads()`
- `handle(_ notification:)`
- `handle(_ request:)`
- `refreshCompatibility()`

### Runtime / Task-Driven Calls

- `handle(_ notification:)`
  - called from the task created by `startNotificationTask(...)`
- `handle(_ request:)`
  - called from the task created by `startServerRequestTask(...)`

### Self-Calls / Internal Flow

- `connect()` -> `teardownRuntime()`
- `connect()` -> `refreshCompatibility()`
- `connect()` -> `startNotificationTask(...)`
- `connect()` -> `startServerRequestTask(...)`
- `connect()` -> `loadThreads()`
- `loadThreads()` -> `upsertThread(_:)`
- `startThread()` -> `upsertThread(_:)`
- `startTurn(inputText:)` -> `merge(turn:...)`
- `handle(_ notification:)` -> `merge(turnError:...)`
- `handle(_ notification:)` -> `upsertThread(_:)`
- `handle(_ notification:)` -> `updateThread(...)`
- `handle(_ notification:)` -> `merge(turn:...)`
- `merge(turn:...)` -> `updateThread(...)`
- `merge(turnError:...)` -> `updateThread(...)`
- `updateThread(...)` -> `upsertThread(_:)` in the active-thread path

### Test-Only Direct Calls

Direct test calls exist for:

- convenience initializer
- `connect()`
- `refreshCompatibility()`
- `startThread()`
- `startTurn(inputText:)`
- `loadThreads()`
- `handle(_ notification:)`

No direct test calls currently exist for:

- `loginWithChatGPT()`
- `selectThread(codexId:)`
- `handle(_ request:)`
- private helpers

## Problems Revealed

- `connect()` is overloaded.
  - It performs compatibility probing, runtime lifecycle, handshake, stream subscription, and initial data loading.
- `loginWithChatGPT()` is a declared app-facing method with no callers and only placeholder behavior.
- `handle(_ request:)` is fully wired by runtime flow but currently does nothing.
- `startNotificationTask(...)`, `startServerRequestTask(...)`, and `teardownRuntime()` are pure orchestration plumbing, not business logic.
- `loadThreads()` has no direct production UI caller; it is effectively part of connect-flow hydration rather than a standalone user action.
- The orchestrator still mixes reducer work and lifecycle work in the same type, which makes the call graph denser than it should be.
