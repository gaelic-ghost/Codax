# UI App-Server Coverage

## Summary

This tracker covers the user-facing app-server surface in two lanes:

- `pinned`: present in `codex-schemas/v0.112.0` and therefore available in the generated connection/runtime surface today
- `upstream-delta`: present in the current upstream app-server README at [openai/codex app-server README](https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md) but not in the pinned schema contract yet

Ownership rules for the current app:

- durable user-facing read models live in SwiftData and are written only through `CodaxPersistenceBridge`
- live session state, approvals, pending login, alerts, hydration progress, plan, and diff state stay in `CodaxViewModel`
- views read durable thread state through `@Query` and send user actions upward into the view model

Current app-level implementation baseline:

- durable thread summaries: implemented
- selected-thread durable hydration: implemented
- selected-plus-recent background hydration: implemented
- pending server-request prompts: implemented as transient view-model state
- approval execution UX: not started beyond prompt surfacing
- upstream README delta surfaces: blocked by contract until the pinned schema catches up

## Client Requests

| Feature Area | Method | Spec Basis | Durable Owner | Live Owner | Current App Status | Priority |
| --- | --- | --- | --- | --- | --- | --- |
| Session / bootstrap | `initialize` | pinned | none | ViewModel | implemented | high |
| Session / bootstrap | `initialized` | pinned | none | ViewModel | implemented | high |
| Thread history | `thread/start` | pinned | SwiftData | ViewModel | implemented | high |
| Thread history | `thread/resume` | pinned | SwiftData | ViewModel | mapped | medium |
| Thread history | `thread/fork` | pinned | SwiftData | ViewModel | mapped | medium |
| Thread history | `thread/archive` | pinned | SwiftData | ViewModel | mapped | medium |
| Thread history | `thread/unsubscribe` | pinned | none | ViewModel | mapped | low |
| Thread history | `thread/name/set` | pinned | SwiftData | ViewModel | mapped | medium |
| Thread history | `thread/metadata/update` | pinned | SwiftData | ViewModel | mapped | medium |
| Thread history | `thread/unarchive` | pinned | SwiftData | ViewModel | mapped | medium |
| Thread history | `thread/compact/start` | pinned | SwiftData | ViewModel | mapped | medium |
| Thread history | `thread/rollback` | pinned | SwiftData | ViewModel | mapped | medium |
| Thread history | `thread/list` | pinned | SwiftData | ViewModel | durable list only | high |
| Thread history | `thread/loaded/list` | pinned | SwiftData | ViewModel | mapped | low |
| Thread history | `thread/read` | pinned | SwiftData | ViewModel | hydrated detail | high |
| Skills / apps | `skills/list` | pinned | none | ViewModel | mapped | medium |
| Skills / apps | `skills/remote/list` | pinned | none | ViewModel | mapped | low |
| Skills / apps | `skills/remote/export` | pinned | none | ViewModel | mapped | low |
| Skills / apps | `app/list` | pinned | none | ViewModel | mapped | medium |
| Skills / apps | `skills/config/write` | pinned | none | ViewModel | mapped | low |
| Skills / apps | `plugin/install` | pinned | none | ViewModel | mapped | medium |
| Active conversation | `turn/start` | pinned | SwiftData | ViewModel | implemented | high |
| Active conversation | `turn/steer` | pinned | none | ViewModel | mapped | medium |
| Active conversation | `turn/interrupt` | pinned | none | ViewModel | mapped | medium |
| Review | `review/start` | pinned | none | ViewModel | mapped | medium |
| Models / features | `model/list` | pinned | none | ViewModel | mapped | medium |
| Models / features | `experimentalFeature/list` | pinned | none | ViewModel | mapped | low |
| MCP / auth | `mcpServer/oauth/login` | pinned | none | ViewModel | mapped | medium |
| MCP / auth | `config/mcpServer/reload` | pinned | none | ViewModel | mapped | low |
| MCP / auth | `mcpServer/status/list` | pinned | none | ViewModel | mapped | medium |
| Platform-specific | `windowsSandbox/setup/start` | pinned | none | none | macOS N/A | low |
| Account / auth | `account/login/start` | pinned | none | ViewModel | implemented | high |
| Account / auth | `account/login/cancel` | pinned | none | ViewModel | mapped | medium |
| Account / auth | `account/logout` | pinned | none | ViewModel | mapped | medium |
| Account / auth | `account/rateLimits/read` | pinned | none | ViewModel | mapped | medium |
| Feedback | `feedback/upload` | pinned | none | ViewModel | mapped | low |
| Command execution | `command/exec` | pinned | none | ViewModel | mapped | medium |
| Config | `config/read` | pinned | none | ViewModel | mapped | medium |
| Config | `externalAgentConfig/detect` | pinned | none | ViewModel | mapped | low |
| Config | `externalAgentConfig/import` | pinned | none | ViewModel | mapped | low |
| Config | `config/value/write` | pinned | none | ViewModel | mapped | medium |
| Config | `config/batch/write` | pinned | none | ViewModel | mapped | medium |
| Config | `config/requirements/read` | pinned | none | ViewModel | mapped | medium |
| Account / auth | `account/read` | pinned | none | ViewModel | implemented | high |
| Search / summaries | `conversationSummary/get` | pinned | none | ViewModel | mapped | medium |
| Search / summaries | `gitDiffToRemote` | pinned | none | ViewModel | mapped | medium |
| Account / auth | `authStatus/get` | pinned | none | ViewModel | mapped | medium |
| Search / summaries | `fuzzyFileSearch` | pinned | none | ViewModel | mapped | medium |

## Notifications

| Feature Area | Notification | Spec Basis | Durable Owner | Live Owner | Current App Status | Priority |
| --- | --- | --- | --- | --- | --- | --- |
| Active conversation | `error` | pinned | none | ViewModel | implemented | high |
| Thread history | `thread/started` | pinned | SwiftData | ViewModel | implemented | high |
| Thread history | `thread/status/changed` | pinned | SwiftData | ViewModel | implemented | high |
| Thread history | `thread/archived` | pinned | SwiftData | ViewModel | implemented | medium |
| Thread history | `thread/unarchived` | pinned | SwiftData | ViewModel | implemented | medium |
| Thread history | `thread/closed` | pinned | SwiftData | ViewModel | implemented | medium |
| Skills / apps | `skills/changed` | pinned | none | ViewModel | mapped | medium |
| Thread history | `thread/name/updated` | pinned | SwiftData | ViewModel | implemented | medium |
| Thread history | `thread/tokenUsage/updated` | pinned | SwiftData | ViewModel | implemented | high |
| Active conversation | `turn/started` | pinned | SwiftData | ViewModel | implemented | high |
| Active conversation | `turn/completed` | pinned | SwiftData | ViewModel | implemented | high |
| Active conversation | `turn/diff/updated` | pinned | none | ViewModel | implemented | high |
| Active conversation | `turn/plan/updated` | pinned | none | ViewModel | implemented | high |
| Active conversation | `item/started` | pinned | none | ViewModel | mapped | medium |
| Active conversation | `item/completed` | pinned | none | ViewModel | mapped | medium |
| Active conversation | `rawResponseItem/completed` | pinned | none | ViewModel | mapped | low |
| Active conversation | `item/agentMessage/delta` | pinned | none | ViewModel | mapped | medium |
| Active conversation | `item/plan/delta` | pinned | none | ViewModel | mapped | medium |
| Command execution | `item/commandExecution/outputDelta` | pinned | none | ViewModel | mapped | medium |
| Command execution | `item/commandExecution/terminalInteraction` | pinned | none | ViewModel | mapped | medium |
| Active conversation | `item/fileChange/outputDelta` | pinned | none | ViewModel | mapped | medium |
| Approvals / prompts | `serverRequest/resolved` | pinned | none | ViewModel | implemented | high |
| MCP / tools | `item/mcpToolCall/progress` | pinned | none | ViewModel | mapped | medium |
| MCP / auth | `mcpServer/oauthLogin/completed` | pinned | none | ViewModel | mapped | medium |
| Account / auth | `account/updated` | pinned | none | ViewModel | implemented | high |
| Account / auth | `account/rateLimits/updated` | pinned | none | ViewModel | mapped | medium |
| Skills / apps | `app/list/updated` | pinned | none | ViewModel | mapped | medium |
| Active conversation | `item/reasoning/summaryTextDelta` | pinned | none | ViewModel | mapped | low |
| Active conversation | `item/reasoning/summaryPartAdded` | pinned | none | ViewModel | mapped | low |
| Active conversation | `item/reasoning/textDelta` | pinned | none | ViewModel | mapped | low |
| Thread history | `thread/compacted` | pinned | SwiftData | ViewModel | mapped | medium |
| Models / features | `model/rerouted` | pinned | none | ViewModel | mapped | medium |
| Session / bootstrap | `deprecationNotice` | pinned | none | ViewModel | mapped | low |
| Config | `configWarning` | pinned | none | ViewModel | mapped | medium |
| Search / summaries | `fuzzyFileSearch/sessionUpdated` | pinned | none | ViewModel | mapped | medium |
| Search / summaries | `fuzzyFileSearch/sessionCompleted` | pinned | none | ViewModel | mapped | medium |
| Realtime / audio | `thread/realtime/started` | pinned | none | ViewModel | mapped | low |
| Realtime / audio | `thread/realtime/itemAdded` | pinned | none | ViewModel | mapped | low |
| Realtime / audio | `thread/realtime/outputAudio/delta` | pinned | none | ViewModel | mapped | low |
| Realtime / audio | `thread/realtime/error` | pinned | none | ViewModel | mapped | low |
| Realtime / audio | `thread/realtime/closed` | pinned | none | ViewModel | mapped | low |
| Platform-specific | `windows/worldWritableWarning` | pinned | none | none | macOS N/A | low |
| Platform-specific | `windowsSandbox/setupCompleted` | pinned | none | none | macOS N/A | low |
| Account / auth | `account/login/completed` | pinned | none | ViewModel | implemented | high |

## Server Requests

| Feature Area | Server Request | Spec Basis | Durable Owner | Live Owner | Current App Status | Priority |
| --- | --- | --- | --- | --- | --- | --- |
| Approvals / prompts | `item/commandExecution/requestApproval` | pinned | none | ViewModel | ephemeral only | high |
| Approvals / prompts | `item/fileChange/requestApproval` | pinned | none | ViewModel | ephemeral only | high |
| Approvals / prompts | `item/tool/requestUserInput` | pinned | none | ViewModel | ephemeral only | high |
| Approvals / prompts | `mcpServer/elicitation/request` | pinned | none | ViewModel | ephemeral only | high |
| Approvals / prompts | `item/tool/call` | pinned | none | ViewModel | ephemeral only | high |
| Account / auth | `account/chatgptAuthTokens/refresh` | pinned | none | ViewModel | ephemeral only | high |
| Approvals / prompts | `applyPatchApproval` | pinned | none | ViewModel | ephemeral only | high |
| Approvals / prompts | `execCommandApproval` | pinned | none | ViewModel | ephemeral only | high |

## Upstream README Delta

| Feature Area | Surface | Direction | Spec Basis | Durable Owner | Live Owner | Current App Status | Priority |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Models / features | `collaborationMode/list` | client request | upstream-delta | none | ViewModel | blocked by contract | medium |
| Skills / apps | `plugin/list` | client request | upstream-delta | none | ViewModel | blocked by contract | medium |
| Skills / apps | `plugin/uninstall` | client request | upstream-delta | none | ViewModel | blocked by contract | medium |
| Thread history | `thread/backgroundTerminals/clean` | client request | upstream-delta | none | ViewModel | blocked by contract | low |
| Realtime / audio | `thread/realtime/start` | client request | upstream-delta | none | ViewModel | blocked by contract | medium |
| Realtime / audio | `thread/realtime/appendAudio` | client request | upstream-delta | none | ViewModel | blocked by contract | medium |
| Realtime / audio | `thread/realtime/appendText` | client request | upstream-delta | none | ViewModel | blocked by contract | medium |
| Realtime / audio | `thread/realtime/stop` | client request | upstream-delta | none | ViewModel | blocked by contract | medium |
| Command execution | `command/exec/write` | client request | upstream-delta | none | ViewModel | blocked by contract | medium |
| Command execution | `command/exec/resize` | client request | upstream-delta | none | ViewModel | blocked by contract | medium |
| Command execution | `command/exec/terminate` | client request | upstream-delta | none | ViewModel | blocked by contract | medium |
| Approvals / prompts | `tool/requestUserInput` | client request | upstream-delta | none | ViewModel | blocked by contract | medium |

## Practical Split

- SwiftData should stay the source of truth for durable thread summaries, hydrated thread detail, and persisted turn history.
- `CodaxViewModel` should stay the source of truth for connection state, pending login, pending approvals, alerts, in-flight plan/diff state, and hydration coordination.
- Views should fetch durable models through `@Query`, but still drive user actions and transient prompts through the view model.
