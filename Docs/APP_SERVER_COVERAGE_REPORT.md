# App-Server Coverage Report

## Summary

Codax now has a coherent runtime and wire-model architecture, but its app-server coverage is still intentionally partial.

What is in good shape:

- local process launch and stdio transport
- JSON-RPC request/response handling
- retry handling for retryable overloads
- typed request wrappers for the current startup/thread/turn/account slice
- complete typed coverage of the current known server-request method union
- a useful curated notification subset for the current UI

What is still missing:

- broader request coverage
- broader notification coverage
- real responder behavior for approvals, elicitation, and auth refresh
- richer UI use of the item and delta stream

## Implemented Client Requests

The current typed client request surface is:

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

These are the methods currently used by the app-facing startup and thread flows.

## Implemented Server Notifications

The currently typed notification subset is:

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

Everything else still falls back to `.unknown(method:raw:)`.

That is enough for the current orchestrator to maintain active thread, turn, diff, plan, token-usage, and core account state, but it is still nowhere near full notification parity.

## Implemented Server Requests

The current typed server-request envelope covers:

- `item/commandExecution/requestApproval`
- `item/fileChange/requestApproval`
- `item/tool/requestUserInput`
- `mcpServer/elicitation/request`
- `item/tool/call`
- `account/chatgptAuthTokens/refresh`
- `applyPatchApproval`
- `execCommandApproval`

Coverage of the request-method union is effectively complete for the currently known schema surface.

The gap is behavioral, not envelope coverage:

- the runtime now surfaces every request on `serverRequests()`
- the default `CodexServerRequestResponder` still returns `.unhandled`
- Codax therefore still lacks real response policy for approvals, elicitation, and auth refresh

## Partially Modeled Areas

The biggest partial areas are:

- notification breadth
- some open-ended nested payloads that still use `CodexValue`
- broader item variant coverage
- UI reduction of item-level streaming data

These are acceptable for the current slice, but they are still the main areas where the code intentionally stops short of full schema parity.

## Biggest Missing Request Areas

The highest-value uncovered request groups remain:

- thread lifecycle and metadata methods such as list, archive, unarchive, naming, and metadata updates
- turn and review expansion such as `turn/steer` and `review/start`
- model/account utility methods such as model listing, rate-limit reads, and logout
- config, MCP, skills, and app-management methods
- search and conversation utility methods such as `fuzzyFileSearch` and summary helpers

The client architecture is ready for these. They are missing because the app has not implemented them yet, not because the lower layers are blocked.

## Biggest Missing Notification Areas

The most obvious uncovered notification groups are:

- thread archive/unarchive/name/closure changes
- account rate-limit changes
- skills/app-list changes
- realtime thread notifications
- fuzzy-file-search session updates
- more MCP and tool-progress notifications
- platform warning and deprecation notifications

These currently survive only as unknown notification payloads.

## Conclusion

Codax is no longer blocked by transport or connection architecture. The architecture is in decent shape.

The real coverage debt is now higher-level:

- more request wrappers
- more notification variants
- real server-request response behavior
- richer orchestration and UI use of the protocol data already available
