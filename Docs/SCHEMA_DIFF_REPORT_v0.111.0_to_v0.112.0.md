# Schema Diff Report: `v0.111.0` to `v0.112.0`

## Current Relevance

This report is retained only as version-history context.

The important current-state fact is no longer whether the old client layer exposed a subset of the schema. The important fact is that the connection layer now generates and verifies the full `v0.112.0` export set.

## Current Conclusion

- Codax is pinned to `codex-schemas/v0.112.0`
- the connection layer now represents every exported schema in that bundle
- any future schema diff work should be evaluated against the connection generator and verifier, not against a hand-maintained client DTO subset

## Practical Follow-Up

When the schema bundle changes again, the expected workflow is:

1. update the pinned schema bundle
2. run `node Tools/generate_connection_schema.js`
3. run `node Tools/update_connection_schema_progress.js --verify`
4. fix generator gaps until the verifier passes again
