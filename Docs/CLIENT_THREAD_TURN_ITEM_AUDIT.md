# Thread / Turn / Item Audit

## Summary

This audit is now connection-owned, not client-owned.

`Thread`, `Turn`, `ThreadItem`, and related protocol models now come from the generated connection schema graph in `Codax/Controllers/Connection/CodexSchema.generated.swift`.

## Current State

- the app-server model graph is generated from the pinned schema set
- public arbitrary-JSON client-layer escape hatches are gone
- `JSONValue` is the connection-owned schema representation for JSON-shaped fields
- thread, turn, and item protocol typing now follows the pinned schema contract rather than hand-curated client models

## Important Constraint

The generated protocol models are now schema-first. Higher app layers that still expect deleted convenience wrappers or renamed fields need to adapt to the generated model graph instead of reintroducing parallel DTOs.

## Practical Conclusion

This is no longer a client-model cleanup area. It is now an app-adaptation area above a completed connection-owned schema boundary.
