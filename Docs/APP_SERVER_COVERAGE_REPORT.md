# App-Server Coverage Report

## Summary

Codax currently has a usable but intentionally narrow `codex app-server` client surface against the pinned `v0.112.0` schemas.

The implemented request side is NOT enough and needs to be expanded:

- `initialize`
- `initialized`
- `thread/start`
- `thread/resume`
- `thread/read`
- `turn/start`
- `turn/interrupt`
- `account/read`
- `account/login/start`
- `account/login/cancel`

The implemented server-request side is broader at the envelope level: the full current `ServerRequest.ts` method union is decoded. After the current client-boundary cleanup, those request payloads are also typed and follow the `codexId` naming boundary in Swift.

The implemented server-notification side is woefully inadequate and should be completed. Codax does not decode the full `ServerNotification.ts` union.

## Coverage Scope And Sources

This report is grounded in:

- current Swift client and orchestration code under `/Users/galew/Workspace/Codax/Codax/Controllers`
- local pinned schemas under `/Users/galew/Workspace/codex-schemas/v0.112.0`
- the upstream `codex-rs/app-server/README.md` for runtime-behavior notes only

Current coverage should be read in three buckets:

- implemented and typed
- incomplete: still lossy or intentionally open-ended
- not yet implemented

## Implemented Client Requests

Codax currently exposes concrete `CodexClient` wrappers for these client-to-server methods:

- `initialize`
- `initialized`
- `thread/start`
- `thread/resume`
- `thread/read`
- `turn/start`
- `turn/interrupt`
- `account/read`
- `account/login/start`
- `account/login/cancel`

These are all wired and usable in the current app flow.

They are also the methods currently exercised by `CodaxOrchestrator` for:

- compatibility-gated startup
- initial handshake
- active-thread bootstrap
- thread start
- turn start
- account/login state bootstrap

## Implemented Server Notifications

Codax currently decodes and exposes this server-notification subset:

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

This subset is NOT ENOUGH. It only supports the current orchestration reducer to keep account state, active thread state, turn state, token usage, plan state, diff state, and core item streaming reasonably current.

Everything else in `ServerNotification.ts` currently falls through to `.unknown(method:raw:)`.

## Implemented Server Requests

Codax currently decodes the full current `ServerRequest.ts` method union:

- `item/commandExecution/requestApproval`
- `item/fileChange/requestApproval`
- `item/tool/requestUserInput`
- `mcpServer/elicitation/request`
- `item/tool/call`
- `account/chatgptAuthTokens/refresh`
- `applyPatchApproval`
- `execCommandApproval`

This surface is now typed end-to-end in Swift and follows the current client naming boundary:

- durable entities use `id: UUID` plus `codexId: String`
- server-owned references use `threadCodexId`, `turnCodexId`, `itemCodexId`, and similar explicit names

The envelope coverage is complete. The remaining caveat is not method coverage, but how much of some open-ended nested payloads are represented as specific schema-backed types versus explicit fallback wrappers such as `CodexValue`.

## INCOMPLETE/Partially Modeled Surfaces

The biggest partial areas after this pass are these:

- Server notifications:
  envelope handling exists, but only a curated subset is decoded into typed notification cases
- Thread and turn runtime semantics:
  `Thread` and `Turn` are now substantially more idiomatic, but upstream runtime behavior still matters
  `Thread.turns` is often empty except on `thread/resume`, `thread/fork`, and `thread/read(includeTurns: true)`
  `Turn.items` is still not authoritative on `turn/started` and `turn/completed`; live item history should still be driven primarily by `item/*` notifications
- Open-ended payloads:
  some server-request payload areas remain intentionally wrapped in explicit client support types like `CodexValue` because upstream shape is open rather than fully closed
- Item breadth:
  the current `ThreadItem` union covers the highest-value variants first, but not the entire upstream variant universe yet

These areas are usable, but they are not yet full schema parity.

## MISSING Client Request Coverage

The largest uncovered request areas in `ClientRequest.ts` are:

### Thread Lifecycle And Metadata

- `thread/fork`
- `thread/archive`
- `thread/unarchive`
- `thread/unsubscribe`
- `thread/name/set`
- `thread/metadata/update`
- `thread/compact/start`
- `thread/rollback`
- `thread/list`
- `thread/loaded/list`

### Turn And Review Expansion

- `turn/steer`
- `review/start`

### Skills, Apps, Plugins, MCP, Admin, And Config

- `skills/list`
- `skills/remote/list`
- `skills/remote/export`
- `skills/config/write`
- `app/list`
- `plugin/install`
- `mcpServer/oauth/login`
- `config/mcpServer/reload`
- `mcpServerStatus/list`
- `config/read`
- `config/value/write`
- `config/batchWrite`
- `configRequirements/read`
- `externalAgentConfig/detect`
- `externalAgentConfig/import`
- `windowsSandbox/setupStart`

### Utility And Account Endpoints

- `model/list`
- `experimentalFeature/list`
- `account/logout`
- `account/rateLimits/read`
- `feedback/upload`
- `command/exec`
- `getConversationSummary`
- `gitDiffToRemote`
- `getAuthStatus`
- `fuzzyFileSearch`

These are not currently wrapped by `CodexClient` and are therefore not available to orchestration or UI through the current typed client surface.

## MISSING Notification Coverage

The biggest remaining notification gap is breadth, not the base envelope mechanism.

Notable uncovered notifications from `ServerNotification.ts` include:

- `thread/archived`
- `thread/unarchived`
- `thread/closed`
- `skills/changed`
- `thread/name/updated`
- `account/rateLimits/updated`
- `app/list/updated`
- `item/plan/delta`
- `item/mcpToolCall/progress`
- `mcpServer/oauthLogin/completed`
- `thread/compacted`
- `model/rerouted`
- `deprecationNotice`
- `configWarning`
- `fuzzyFileSearch/sessionUpdated`
- `fuzzyFileSearch/sessionCompleted`
- `thread/realtime/started`
- `thread/realtime/itemAdded`
- `thread/realtime/outputAudio/delta`
- `thread/realtime/error`
- `thread/realtime/closed`
- `windows/worldWritableWarning`
- `windowsSandbox/setupCompleted`
- `rawResponseItem/completed`

These methods are currently preserved only as unknown notification envelopes and are not applied to orchestration state.

## Recommended Next Slices

The highest-value next API slices are:

1. Thread-management expansion
- add `thread/list`, `thread/loaded/list`, and `thread/name/set`
- this unlocks a more truthful sidebar and persistent thread browsing

2. Notification breadth for current UI state
- add `thread/name/updated`, `thread/archived`, `thread/unarchived`, `account/rateLimits/updated`, and `app/list/updated`
- this improves fidelity without requiring broad new UI architecture

3. Turn and review depth
- add `turn/steer`
- add `review/start`
- broaden item and delta coverage where review or richer conversation rendering needs it

4. Model and account utility endpoints
- add `model/list`
- add `account/rateLimits/read`
- add `account/logout`

5. Search and conversation utility
- add `fuzzyFileSearch`
- add `getConversationSummary`

These slices would extend the current app meaningfully while staying aligned with how Codax is already structured.

## Conclusion

Codax is WOEFULLY INADEQUATE and only covers the app-server surface well enough for:

- process launch and handshake
- account bootstrap and login initiation/cancel
- active-thread bootstrap
- starting threads and turns
- decoding the full current server-request method union
- consuming a useful curated subset of server notifications

What remains is CRITICAL API breadth which MUST BE RECTIFIED:

- more request wrappers
- broader notification coverage
- fuller typed modeling for the remaining open-ended or currently deferred surfaces

That makes the next steps concrete: build out ALL MISSING API COVERAGE.
