# UI App-Server Coverage

## Summary

This tracker remains useful as a protocol-facing inventory, but its previous app-status claims had drifted ahead of the checked-in UI.

It covers the user-facing app-server surface in two lanes:

- `pinned`: present in `codex-schemas/v0.114.0` and therefore available in the generated connection/runtime surface today
- `upstream-delta`: present in the current upstream app-server README at [openai/codex app-server README](https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md) but not in the pinned schema contract yet

## Transition Note

Use this file as a contract-and-coverage tracker, not as proof that the current SwiftUI app has finished adopting every mapped surface.

The checked-in repo currently shows all of the following at once:

- a strong typed connection/runtime boundary
- a newer `CodaxOrchestrator` app object in the app entrypoint
- older tests and some views that still reference `CodaxViewModel`
- placeholder UI files that mean several previously documented app behaviors are still aspirational

## Ownership Guidance

Current reality-first ownership guidance:

- generated request, notification, and server-request coverage lives in the connection/runtime layer
- durable models live under `Codax/SwiftData`, but the repo should not currently claim a finished SwiftUI `@Query` architecture without qualification
- live app state is in transition between older `CodaxViewModel` expectations and newer `CodaxOrchestrator` code
- views should be assumed incomplete unless the checked-in implementation demonstrates the behavior directly

## Current Coverage Reading

Interpret status labels this way during the migration:

- `implemented`: safe only for protocol-layer mapping or for app behavior that is clearly present in checked-in source
- `mapped`: the typed surface exists, but the end-user UI may still be partial or absent
- `ephemeral only`: surfaced in transient state, without claiming a polished or complete UX
- `blocked by contract`: visible upstream but not available in the pinned schema contract

## Current App-Level Baseline

What this repo can safely claim today:

- the pinned `v0.114.0` request, notification, and server-request surface is represented in the generated connection/runtime boundary
- inbound server requests are routed through typed envelopes
- the app is actively migrating its UI and orchestration layer above that protocol boundary

What this repo should not currently claim as finished:

- fully migrated project-rooted sidebar navigation
- fully migrated inspector rail behavior
- fully migrated toolbar flows
- uniformly durable SwiftData-backed view reads through `@Query`

## Client Requests

| Feature Area | Method | Spec Basis | Current Status | Notes |
| --- | --- | --- | --- | --- |
| Session / bootstrap | `initialize` | pinned | implemented | typed runtime/orchestrator path exists |
| Session / bootstrap | `initialized` | pinned | implemented | typed runtime/orchestrator path exists |
| Thread history | `thread/start` | pinned | mapped | typed surface exists; UI adoption is still in flux |
| Thread history | `thread/resume` | pinned | mapped | typed surface exists |
| Thread history | `thread/fork` | pinned | mapped | typed surface exists |
| Thread history | `thread/archive` | pinned | mapped | typed surface exists |
| Thread history | `thread/unsubscribe` | pinned | mapped | typed surface exists |
| Thread history | `thread/name/set` | pinned | mapped | typed surface exists |
| Thread history | `thread/metadata/update` | pinned | mapped | typed surface exists |
| Thread history | `thread/unarchive` | pinned | mapped | typed surface exists |
| Thread history | `thread/compact/start` | pinned | mapped | typed surface exists |
| Thread history | `thread/rollback` | pinned | mapped | typed surface exists |
| Thread history | `thread/list` | pinned | mapped | typed surface exists; do not infer finished durable UI |
| Thread history | `thread/loaded/list` | pinned | mapped | typed surface exists |
| Thread history | `thread/read` | pinned | mapped | typed surface exists |
| Skills / apps | `skills/list` | pinned | mapped | typed surface exists |
| Skills / apps | `skills/remote/list` | pinned | mapped | typed surface exists |
| Skills / apps | `skills/remote/export` | pinned | mapped | typed surface exists |
| Skills / apps | `app/list` | pinned | mapped | typed surface exists |
| Skills / apps | `skills/config/write` | pinned | mapped | typed surface exists |
| Skills / apps | `plugin/list` | pinned | mapped | typed surface exists |
| Skills / apps | `plugin/install` | pinned | mapped | typed surface exists |
| Skills / apps | `plugin/uninstall` | pinned | mapped | typed surface exists |
| Active conversation | `turn/start` | pinned | mapped | typed surface exists; UI completion not claimed |
| Active conversation | `turn/steer` | pinned | mapped | typed surface exists |
| Active conversation | `turn/interrupt` | pinned | mapped | typed surface exists |
| Review | `review/start` | pinned | mapped | typed surface exists |
| Models / features | `model/list` | pinned | mapped | typed surface exists |
| Models / features | `experimentalFeature/list` | pinned | mapped | typed surface exists |
| MCP / auth | `mcpServer/oauth/login` | pinned | mapped | typed surface exists |
| MCP / auth | `config/mcpServer/reload` | pinned | mapped | typed surface exists |
| MCP / auth | `mcpServer/status/list` | pinned | mapped | typed surface exists |
| Platform-specific | `windowsSandbox/setup/start` | pinned | macOS N/A | present in schema, not a macOS app target |
| Account / auth | `account/login/start` | pinned | mapped | typed surface exists |
| Account / auth | `account/login/cancel` | pinned | mapped | typed surface exists |
| Account / auth | `account/logout` | pinned | mapped | typed surface exists |
| Account / auth | `account/rateLimits/read` | pinned | mapped | typed surface exists |
| Feedback | `feedback/upload` | pinned | mapped | typed surface exists |
| Command execution | `command/exec` | pinned | mapped | typed surface exists |
| Command execution | `command/exec/write` | pinned | mapped | typed surface exists |
| Command execution | `command/exec/resize` | pinned | mapped | typed surface exists |
| Command execution | `command/exec/terminate` | pinned | mapped | typed surface exists |
| Config | `config/read` | pinned | mapped | typed surface exists |
| Config | `externalAgentConfig/detect` | pinned | mapped | typed surface exists |
| Config | `externalAgentConfig/import` | pinned | mapped | typed surface exists |
| Config | `config/value/write` | pinned | mapped | typed surface exists |
| Config | `config/batch/write` | pinned | mapped | typed surface exists |
| Config | `config/requirements/read` | pinned | mapped | typed surface exists |
| Account / auth | `account/read` | pinned | mapped | typed surface exists |
| Search / summaries | `conversationSummary/get` | pinned | mapped | typed surface exists |
| Search / summaries | `gitDiffToRemote` | pinned | mapped | typed surface exists |
| Account / auth | `authStatus/get` | pinned | mapped | typed surface exists |
| Search / summaries | `fuzzyFileSearch` | pinned | mapped | typed surface exists |

## Notifications

All pinned server notifications are represented in the generated `ServerNotificationEnvelope`.

Reality-first interpretation:

- protocol coverage is implemented
- app-level UI handling is still partially migrated
- earlier doc claims that specific notification-driven UI was fully complete should not be relied on without checking current source

## Server Requests

All pinned server requests are represented in the generated `ServerRequestEnvelope` and corresponding response types.

Reality-first interpretation:

- typed routing exists
- some requests are surfaced into app-facing pending state
- the end-user approval, elicitation, and auth-refresh UX is still incomplete

## Upstream README Delta

Surfaces in this section remain blocked until the pinned schema contract catches up:

- `collaborationMode/list`
- `thread/backgroundTerminals/clean`
- realtime client requests such as `thread/realtime/start`, `thread/realtime/appendAudio`, `thread/realtime/appendText`, and `thread/realtime/stop`
- `tool/requestUserInput` as a client request surface

## Practical Conclusion

Use this document to answer, "Is the protocol surface typed and represented in the repo?" not, "Has the current UI finished shipping this feature?" Those are different questions in the current migration phase, and the first one is much farther along than the second.
