# Client Thread / Turn / Item Audit

## Summary

The thread, turn, and item slice is materially stronger than it was when this audit was first written.

Current headline state:

- `Thread` and `Turn` are real typed models, not thin placeholder wrappers
- `ThreadItem` is a tagged union with explicit known cases plus `.unknown(raw: CodexValue)`
- known item variants now encode with their discriminator, so typed items round-trip cleanly
- open-ended nested payloads still use `CodexValue` where upstream shape remains broad or not yet worth hardening

## Current Strong Areas

### Thread

`Thread` now has typed ownership for important fields such as:

- `status: ThreadStatus`
- `source: SessionSource?`
- `gitInfo: GitInfo?`
- `approvalPolicy: AskForApproval`
- `sandbox: SandboxPolicy`

This is no longer a generic JSON bucket.

### Turn

`Turn` now has meaningful typed structure for:

- `status: TurnStatus`
- `items: [ThreadItem]`
- `error: TurnError?`

Some nested fields still intentionally remain open-ended:

- `summary`
- `outputSchema`
- other schema-shaped payloads that are not yet stable enough to justify more DTOs

### ThreadItem

`ThreadItem` is now the key discriminated union for orchestration-suitable item payloads.

Known cases encode and decode through explicit `"type"` discriminators.

Unknown or future variants preserve raw payloads through:

- `.unknown(raw: CodexValue)`

That is the right boundary between strong typing and forward compatibility.

## Current Use Of `CodexValue`

The relevant remaining `CodexValue` usage is intentional.

It is still appropriate for:

- unknown item payloads
- some broader nested request/response fields
- schema-shaped blobs where the current app does not yet need stronger modeling

This is no longer a duplicate or transport-only JSON tree. `CodexValue` is the canonical arbitrary-JSON representation in the client layer.

## Current Gaps

The main remaining gaps in this slice are:

- more item variant coverage
- deeper reduction of item streaming deltas into app-visible state
- stronger typing for a few still-open nested payload fields where upstream shape has proven stable enough

These are real modeling improvements, but they are no longer foundational cleanup problems.

## Practical Conclusion

This area should now be treated as an incremental modeling surface, not a structural architecture problem.

The next work here should be driven by UI and orchestration needs:

- add item variants the UI actually needs
- tighten nested payload types where that buys clarity
- keep `CodexValue` only for genuinely open or future-facing payloads
