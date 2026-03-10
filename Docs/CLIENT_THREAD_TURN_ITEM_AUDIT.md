# Client Thread / Turn / Item Audit

## Summary

This audit compares the current Swift client models for `Thread`, `Turn`, and `Item` against:

- the local `v0.112.0` schemas in `../codex-schemas`
- the upstream app-server README at [codex-rs/app-server/README.md](https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md)

The conclusion is:

- Codax did not tack extra custom fields onto `Thread` or `Turn`.
- The real issue was under-modeling, especially around `Thread.status`, `Turn.status`, and `ThreadItem`.
- The README adds one important runtime constraint beyond raw schema shape: live item history should still be treated as notification-driven because `turn/started` and `turn/completed` often carry empty `items`.

## Thread

| Field / Area | Current Swift | Schema Grounding | Status |
| --- | --- | --- | --- |
| Base field list (`id`, `preview`, `ephemeral`, `modelProvider`, timestamps, paths, turns) | Present | `v2/Thread.ts` | Aligned |
| `status` | `ThreadStatus` | `v2/ThreadStatus.ts` | Added now |
| `source` | `SessionSource?` | `v2/Thread.ts`, `SessionSource.ts` | Added now, still optional in Swift |
| `gitInfo` | `GitInfo?` | `v2/Thread.ts`, `GitInfo.ts` | Added now |
| `approvalPolicy`, `sandbox` on thread start/resume responses | `JSONValue` aliases | schema is broader and nested | Lossy but acceptable for now |

Notes:

- `Thread.turns` remains valid, but callers should remember the schema only guarantees populated turns on `thread/read(includeTurns: true)`, `thread/resume`, `thread/fork`, and related read-style flows.

## Turn

| Field / Area | Current Swift | Schema Grounding | Status |
| --- | --- | --- | --- |
| Base field list (`id`, `items`, `status`, `error`) | Present | `v2/Turn.ts` | Aligned |
| `status` | `TurnStatus` enum | `v2/TurnStatus.ts` | Added now |
| `error` | `TurnError` | `v2/TurnError.ts` | Aligned |
| `input`, `summary`, `outputSchema`, `codexErrorInfo` | still use `JSONValue` in places | nested schema detail is broader | Lossy but acceptable for now |

README note:

- `turn/started` and `turn/completed` should not be treated as reliable populated-item snapshots yet. Current app-server behavior still makes `item/*` notifications the canonical live item stream.

## Item

| Area | Current Swift | Schema Grounding | Status |
| --- | --- | --- | --- |
| Base item type | `ThreadItem` tagged enum | `v2/ThreadItem.ts` | Added now |
| `item/started` and `item/completed` notifications | typed with `ThreadItem` | `v2/ItemStartedNotification.ts`, `v2/ItemCompletedNotification.ts` | Added now |
| Supported variants in this slice | `userMessage`, `agentMessage`, `plan`, `reasoning`, `commandExecution`, `fileChange`, `mcpToolCall`, `dynamicToolCall`, `webSearch`, `imageView`, `enteredReviewMode`, `exitedReviewMode`, `contextCompaction` | `v2/ThreadItem.ts` | Added now |
| Remaining variants | not yet modeled as first-class Swift cases | `v2/ThreadItem.ts` union is broader | Intentionally deferred |
| Unknown future variants | preserved as raw payload | forward compatibility | Added now |

## Missing But Intentionally Deferred

- full `ThreadItem` parity for every current upstream variant
- deeper typed modeling for nested command/tool payloads
- broader thread management methods such as list/fork/archive/rollback
- typed policy/config DTO cleanup beyond the `Thread` and `Turn` base shapes

## Conclusion

The client models are now grounded in the `v0.112.0` schema baseline for the `Thread` and `Turn` base contracts, and the biggest missing piece, `ThreadItem`, now exists as a real tagged union instead of a raw JSON placeholder.

What remains missing is mostly depth, not shape:

- more `ThreadItem` variants
- deeper nested payload typing
- broader client surface coverage outside the current thread/turn slice
