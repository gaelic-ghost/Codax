# Client Schema Report

## Summary

This report maps the client-facing TypeScript schemas in `~/Workspace/codex-schemas/v0.111.0/` onto the current Swift `Client` layer in `/Users/galew/Workspace/Codax/Codax.xcodeproj`.

It is intentionally current-slice-first. The goal is not to inventory every request in `ClientRequest.ts`. The goal is to define the actual `Client`-layer contract in this repo today: the typed Swift facade over generic request routing, the params and response DTOs currently modeled in Swift, and the specific gaps that still separate the current `CodexClient` from the broader app-server surface.

The main conclusion is:

- The client contract is centered on `ClientRequest.ts`, `ClientNotification.ts`, and the concrete params and response files reachable from the currently implemented method subset.
- The current Swift split is structurally sound:
  - `CodexConnection` owns generic JSON-RPC mechanics.
  - `CodexClient` owns typed request methods.
  - `CodexClient+Initialize.swift`, `CodexClient+Thread.swift`, and `CodexClient+Turn.swift` own most of the currently modeled client DTOs.
- The current `CodexClient` surface is a deliberate first slice, not broad schema coverage.
- The biggest `Client`-layer gaps are not request plumbing. They are:
  - broader method coverage
  - richer DTO modeling
  - validating current DTOs against real app-server payloads
- There is also one important ownership drift to correct later:
  - account and login DTOs used by `CodexClient` currently live under `AuthCoordinator+Types.swift`, not under the `Client` layer itself.

## Scope And Boundary

This report is about the `Client` layer only.

It does not attempt to restate the full transport or connection layers. It also does not treat inbound server notifications or server-request handling as the primary thesis of the report, even though those files sit in the broader client directory.

### In Scope

- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+Initialize.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+Thread.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+Turn.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+Account.swift`
- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/AuthCoordinator+Types.swift`

### Client-Adjacent But Secondary

- `CodexClient+InboundMessage.swift`
- `CodexClient+ServerNotificationEnvelope.swift`
- `CodexClient+ServerNotificationTypes.swift`
- `CodexClient+ServerRequestHandler.swift`
- `CodexClient+ServerRequestHandlerEnvelope.swift`
- `CodexClient+ServerRequestHandlerTypes.swift`
- `CodexClient+Item.swift`
- `CodexClient+MCP.swift`
- `CodexClient+Tools.swift`
- `CodexClient+Command.swift`

Those files matter as context, but they are not the primary client-method surface discussed here.

### Explicitly Adjacent But Separate

- `CodexConnection`
  - generic JSON-RPC requests, notifications, correlation, and response decoding
- `CodaxOrchestrator`
  - app-facing state, connect/login/thread workflow, and future policy decisions
- inbound notification and request routing
  - client-adjacent semantics built on top of `Connection`, but not the main focus of this report

That separation matters because the `Client` layer should stay the home of typed client-initiated API, not generic transport/runtime orchestration.

## Source Of Truth

This report was grounded in three sources.

### 1. Local Generated Schemas

Primary schema roots:

- `~/Workspace/codex-schemas/v0.111.0/ClientRequest.ts`
- `~/Workspace/codex-schemas/v0.111.0/ClientNotification.ts`
- `~/Workspace/codex-schemas/v0.111.0/InitializeParams.ts`
- `~/Workspace/codex-schemas/v0.111.0/InitializeResponse.ts`
- `~/Workspace/codex-schemas/v0.111.0/InitializeCapabilities.ts`
- the relevant `v2/*Params.ts` and `v2/*Response.ts` files for currently modeled methods

For the current Swift slice, the most relevant `v2` roots include:

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

### 2. Official Codex App-Server Documentation

- [developers.openai.com/codex/app-server](https://developers.openai.com/codex/app-server/)

This is the clearest source for protocol rules that affect client correctness but are not just a method inventory:

- `initialize` then `initialized`
- pre-initialization rejection behavior
- omitted `"jsonrpc":"2.0"` on the wire
- stdio JSONL framing as the protocol environment
- retry expectations around `-32001`

### 3. Upstream App-Server README

- [github.com/openai/codex/codex-rs/app-server/README.md](https://github.com/openai/codex/blob/main/codex-rs%2Fapp-server%2FREADME.md)

The upstream README reinforces the official docs and helps anchor client-relevant behavior such as:

- initialization sequencing
- overload behavior and retry context
- websocket being experimental and unsupported

## Current Client Contract In The Schemas

### 1. `ClientRequest.ts` Is The Main Client Surface

`ClientRequest.ts` is the main source of truth for the client method surface.

The current Swift `CodexClient` implements this subset:

- `initialize`
- `thread/start`
- `thread/resume`
- `thread/read`
- `turn/start`
- `turn/interrupt`
- `account/read`
- `account/login/start`
- `account/login/cancel`

That subset is enough to support the current first client slice:

- session establishment
- thread entry and resume flows
- turn start and interruption
- account and login bootstrap

### 2. `ClientNotification.ts` Is Much Smaller

`ClientNotification.ts` currently defines:

- `initialized`

That matters because `sendInitialized()` is a real part of the client surface, but it is not a `ClientRequest.ts` method. It is a client notification required by the protocol handshake.

### 3. The Full Schema Surface Is Broader Than The Current Swift Slice

The rest of `ClientRequest.ts` is significantly broader than the current Swift implementation.

Important uncovered request groups include:

- thread management and metadata
  - fork, archive, unsubscribe, naming, metadata updates, unarchive, compact, rollback, list
- skills, apps, plugins, and MCP status
  - skills list/read/write, app list, plugin install, MCP OAuth/login/status
- model and feature listing
  - model list, experimental feature list
- config and external-agent flows
  - config read/write/batch, external-agent detect/import, config requirements, MCP reload
- review, feedback, command execution, and utility endpoints
  - review start, feedback upload, command execution, auth status, conversation summary, git diff, fuzzy file search

For this repo, the right interpretation is:

- the client layer is not missing generic request plumbing
- it is intentionally selective about which app-server methods it has turned into first-class Swift API

## Current Swift Client Ownership

### 1. `CodexClient.swift`

**File**

- `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient.swift`

**Responsibility**

- expose typed client methods over the generic `CodexConnection`
- keep request sending small and predictable
- avoid owning JSON-RPC mechanics directly

**Current methods**

- `initialize(_:)`
- `sendInitialized()`
- `startThread(_:)`
- `resumeThread(_:)`
- `readThread(_:)`
- `startTurn(_:)`
- `interruptTurn(_:)`
- `readAccount(_:)`
- `startLogin(_:)`
- `cancelLogin(_:)`

This is a clean first-pass facade. Each method delegates to `CodexConnection` without duplicating transport or response-correlation logic.

### 2. `CodexClient+Initialize.swift`

**Responsibility**

- startup and handshake DTOs

**Current alignment**

- `ClientInfo`
- `InitializeCapabilities`
- `InitializeParams`
- `InitializeResponse`

This is one of the strongest-aligned client files in the current tree. The types are small, directly tied to the schema, and clearly placed.

### 3. `CodexClient+Thread.swift`

**Responsibility**

- thread-facing client DTOs

**Current alignment**

- request params for `thread/start`, `thread/resume`, and `thread/read`
- response DTOs for those methods
- thread notification seed types like `ThreadStartedNotification`

This file already carries a meaningful first slice of the thread surface, but several fields are still schema-thin:

- `status: JSONValue`
- `source: JSONValue?`
- `gitInfo: JSONValue?`
- `approvalPolicy: AskForApproval`
- `sandbox: SandboxPolicy`

Those are structurally acceptable placeholders for now, but they are not endpoint-complete modeling.

### 4. `CodexClient+Turn.swift`

**Responsibility**

- turn-facing client DTOs

**Current alignment**

- request params for `turn/start` and `turn/interrupt`
- response DTOs for those methods
- turn lifecycle notification seed types

This file is also structurally sound, but still schema-thin in several places:

- `input: [JSONValue]`
- `summary: JSONValue?`
- `outputSchema: JSONValue?`
- `items: [ThreadItem]`
- `codexErrorInfo: JSONValue?`

### 5. `CodexClient+Account.swift`

**Responsibility in theory**

- account-facing client DTOs

**Current reality**

- the file exists, but it is empty

This is the clearest client-ownership gap in the current tree. The public account/login methods exist on `CodexClient`, but their params and responses are not owned by the `Client` layer yet.

### 6. `AuthCoordinator+Types.swift` Currently Owns Account/Login DTOs

**File**

- `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/AuthCoordinator+Types.swift`

**Current reality**

The following client method DTOs currently live under `Orchestration` instead of `Client`:

- `GetAccountParams`
- `GetAccountResponse`
- `LoginAccountParams`
- `LoginAccountResponse`
- `CancelLoginAccountParams`
- `CancelLoginAccountResponse`

This works today, but it is a genuine layer-boundary smell:

- `CodexClient` is depending on `Orchestration` types for its own public request surface
- `CodexClient+Account.swift` exists but does not yet own the account/login DTOs it implies

That ownership drift should be called out explicitly in this report because it affects how trustworthy the current file layout is as a guide to the client contract.

## Schema-To-Swift Mapping For The Current Slice

| Swift API | Wire Method | Primary Schema Root |
| --- | --- | --- |
| `initialize(_:)` | `"initialize"` | `ClientRequest.ts`, `InitializeParams.ts`, `InitializeResponse.ts` |
| `sendInitialized()` | `"initialized"` | `ClientNotification.ts` |
| `startThread(_:)` | `"thread/start"` | `ClientRequest.ts`, `v2/ThreadStartParams.ts`, `v2/ThreadStartResponse.ts` |
| `resumeThread(_:)` | `"thread/resume"` | `ClientRequest.ts`, `v2/ThreadResumeParams.ts`, `v2/ThreadResumeResponse.ts` |
| `readThread(_:)` | `"thread/read"` | `ClientRequest.ts`, `v2/ThreadReadParams.ts`, `v2/ThreadReadResponse.ts` |
| `startTurn(_:)` | `"turn/start"` | `ClientRequest.ts`, `v2/TurnStartParams.ts`, `v2/TurnStartResponse.ts` |
| `interruptTurn(_:)` | `"turn/interrupt"` | `ClientRequest.ts`, `v2/TurnInterruptParams.ts`, `v2/TurnInterruptResponse.ts` |
| `readAccount(_:)` | `"account/read"` | `ClientRequest.ts`, `v2/GetAccountParams.ts`, `v2/GetAccountResponse.ts` |
| `startLogin(_:)` | `"account/login/start"` | `ClientRequest.ts`, `v2/LoginAccountParams.ts`, `v2/LoginAccountResponse.ts` |
| `cancelLogin(_:)` | `"account/login/cancel"` | `ClientRequest.ts`, `v2/CancelLoginAccountParams.ts`, `v2/CancelLoginAccountResponse.ts` |

This mapping is the real current `Client`-layer contract in Swift.

## Protocol Rules That Affect The Client Layer

The generated schemas define the method and payload inventory, but a few client-relevant rules come from the docs and upstream README rather than from `ClientRequest.ts` alone.

### 1. `initialize` Then `initialized`

Each connection must begin with:

1. `initialize`
2. receive the response
3. `initialized`

That is why the current Swift client surface models both:

- `initialize(_:)`
- `sendInitialized()`

### 2. Requests Before Initialization Are Rejected

The docs and README both make clear that requests issued before the required handshake are rejected by the server.

That rule is not client-specific in implementation ownership, but it directly affects client correctness because the typed client surface is what higher layers actually call.

### 3. `initialized` Is A Notification, Not A Request

This matters enough to state explicitly:

- `initialize` belongs to `ClientRequest.ts`
- `initialized` belongs to `ClientNotification.ts`

The current Swift split models that correctly.

### 4. `-32001` Matters Indirectly To The Client Layer

The docs and README both describe `-32001` as a retryable overload error.

Retry policy is now implemented in the current connection layer, and it is not fundamentally a `Client`-layer responsibility. It still matters to the client report because typed client methods are the API surface most likely to surface that behavior to higher layers today, even though the retry logic lives underneath them.

### 5. The Client Layer Sits On The Same Protocol Environment

Even though transport and connection own the mechanics, the client layer still sits on top of:

- stdio JSONL framing
- omitted `jsonrpc`
- request/response/error JSON-RPC semantics

Those are not re-owned by `CodexClient`, but they shape how the client surface should be understood.

## Current Alignment

### What Is Already Strong

- `CodexClient` is a clean, generic request wrapper over `CodexConnection`
- `initialize` and `initialized` are modeled distinctly and correctly
- thread/turn/account/login flows are enough for the current first client slice
- request params and response DTOs are already split into sensible domain files for initialize, thread, and turn work
- the current method surface aligns directly with Milestone 3’s first-pass goals

### What Is Intentionally Partial

- the current Swift `Client` layer covers only a small subset of `ClientRequest.ts`
- most of the broader app-server method surface is not yet represented by typed Swift methods
- several domain files exist only as placeholders or partial placeholders:
  - `CodexClient+Account.swift`
  - `CodexClient+Command.swift`

### Where Typing Is Still Thin

The current client layer still relies on `JSONValue`-based placeholders in several important places:

- `AskForApproval`
- `SandboxMode`
- `SandboxPolicy`
- `Personality`
- `CollaborationMode`
- `ThreadItem`
- `DynamicToolCallOutputContentItem`
- nested fields in `Thread`
- nested fields in `Turn`
- nested fields in approval/tool-related DTOs

This is acceptable for a first slice, but the report should treat these as temporary typing, not as stable endpoint-complete modeling.

### Where Ownership Is Misaligned

The most notable ownership issue is account/login DTO placement:

- `CodexClient+Account.swift` is empty
- the actual account/login request and response types live under `AuthCoordinator+Types.swift`

That means the public client-facing API is partially modeled outside the `Client` layer, which weakens the clarity of the current file organization.

## Remaining Gaps And Future Coverage

The current `Client` layer is structurally sound, but it is not yet a trustworthy typed facade for the full app-server surface.

The primary remaining Milestone 3 work is:

- validate current DTOs against real app-server payloads
- add broader typed method coverage
- reduce generic `JSONValue` placeholders

More concretely, that means:

- move account/login DTO ownership fully into the `Client` layer
- flesh out currently empty or placeholder client files where they represent real method domains
- decide which uncovered `ClientRequest.ts` groups are next priorities
- refine nested thread/turn/tool/config payloads away from `JSONValue` where the schema is already stable enough to model directly

## Public Client Interfaces Currently Exposed

The current public client-facing types and their current ownership are:

- `CodexClient`
  - `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient.swift`
- `ClientInfo`
- `InitializeCapabilities`
- `InitializeParams`
- `InitializeResponse`
  - `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+Initialize.swift`
- `ThreadStartParams`
- `ThreadResumeParams`
- `ThreadReadParams`
- `ThreadStartResponse`
- `ThreadReadResponse`
  - `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+Thread.swift`
- `TurnStartParams`
- `TurnInterruptParams`
- `TurnStartResponse`
- `TurnInterruptResponse`
  - `/Users/galew/Workspace/Codax/Codax/Controllers/Client/CodexClient+Turn.swift`
- `GetAccountParams`
- `GetAccountResponse`
- `LoginAccountParams`
- `LoginAccountResponse`
- `CancelLoginAccountParams`
- `CancelLoginAccountResponse`
  - currently in `/Users/galew/Workspace/Codax/Codax/Controllers/Orchestration/AuthCoordinator+Types.swift`

This ownership list is important because it shows both:

- the stable first client slice already represented as public Swift API
- the account/login ownership leak that still needs to be corrected later

## Conclusion

The current `Client` layer is in good shape for a first implementation slice.

It already does the most important architectural job correctly:

- keep typed client API separate from generic `Connection`
- keep transport mechanics out of the client facade
- expose a small set of real app-server methods through straightforward Swift API

What remains is not a redesign. It is disciplined broadening and refinement:

- more method coverage
- better DTO fidelity
- cleaner ownership, especially for account/login types

That matches the roadmap exactly. The `Client` layer is no longer conceptual scaffolding, but it is still intentionally incomplete.

## Validation Checklist

- every method documented above exists on `CodexClient`
- every request-style method documented above maps to a real `ClientRequest.ts` variant
- `sendInitialized()` is correctly treated as `ClientNotification.ts`, not `ClientRequest.ts`
- `CodexClient+Account.swift` and `CodexClient+Command.swift` are accurately described as empty placeholders
- `AuthCoordinator+Types.swift` is accurately identified as the current home of account/login DTOs
- `JSONValue`-based placeholder typing is explicitly called out where it materially affects the current client layer
- layer boundaries stay consistent with `/Users/galew/Workspace/Codax/Docs/TRANSPORT_SCHEMA_REPORT.md`
- layer boundaries stay consistent with `/Users/galew/Workspace/Codax/Docs/CONNECTION_SCHEMA_REPORT.md`
- remaining-work conclusions match Milestone 3 in `/Users/galew/Workspace/Codax/ROADMAP.md`
