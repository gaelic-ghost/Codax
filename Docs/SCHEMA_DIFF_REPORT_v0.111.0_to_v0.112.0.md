# Schema Diff Report: `v0.111.0` to `v0.112.0`

## Summary

This report compares the full schema bundles at `../codex-schemas/v0.111.0` and `../codex-schemas/v0.112.0`, then filters that raw diff through Codax's current architecture and code usage.

The main conclusion is:

- the schema diff from `v0.111.0` to `v0.112.0` is small
- the core wire roots currently most important to Codax are unchanged:
  - `ClientRequest.ts`
  - `ClientNotification.ts`
  - `ServerNotification.ts`
  - `ServerRequest.ts`
  - `InitializeParams.ts`
  - `InitializeResponse.ts`
  - `InitializeCapabilities.ts`
- the changed files are concentrated in:
  - macOS permission/profile modeling
  - `v2/AppInfo.ts`
- there is no current evidence that the `v0.112.0` update blocks transport, connection, client, or the planned orchestration slice
- the most likely future follow-up area is app/plugin/macOS-permission modeling, not the current wire-facing foundation

## Diff Scope And Sources

### Primary Comparison Base

This report uses the existing repo-adjacent schema location as the source of truth:

- `../codex-schemas/v0.111.0`
- `../codex-schemas/v0.112.0`

That choice matches the current Xcode project reference and the existing transport, connection, and client reports.

### Duplicate Bundle Check

The repo also has duplicate schema bundles under:

- `../resources/codex-schemas/v0.111.0`
- `../resources/codex-schemas/v0.112.0`

Those duplicate bundles matched the `../codex-schemas` contents in the comparison pass, so they were treated as duplicate context only rather than as an independent source of truth.

### Comparison Method

This diff pass used:

- full directory comparison
- diff stat
- focused file diffs for all changed files
- targeted repo searches for references to changed schema types

The goal was not just to catalog changed files. The goal was to determine whether those changes materially affect Codax's current implementation or the next planned slice.

## Bundle-Level Diff Summary

### 1. File Count

Both bundles currently contain the same number of files:

- `v0.111.0`: 466 files
- `v0.112.0`: 466 files

So this is not a broad expansion or contraction of the generated schema surface. It is a narrow revision of a small subset of files.

### 2. Changed Files

The changed surface is currently limited to these files:

- `PermissionProfile.ts`
- `index.ts`
- `v2/AdditionalMacOsPermissions.ts`
- `v2/AppInfo.ts`
- renamed or replaced macOS permission files:
  - `MacOsAutomationValue.ts` -> `MacOsAutomationPermission.ts`
  - `MacOsPreferencesValue.ts` -> `MacOsPreferencesPermission.ts`
  - `MacOsPermissions.ts` -> `MacOsSeatbeltProfileExtensions.ts`

### 3. Unchanged Roots

The wire roots and initialization roots most central to Codax's current reports and implementation were unchanged between `v0.111.0` and `v0.112.0`:

- `ClientRequest.ts`
- `ClientNotification.ts`
- `ServerNotification.ts`
- `ServerRequest.ts`
- `InitializeParams.ts`
- `InitializeResponse.ts`
- `InitializeCapabilities.ts`

That is the single most important fact in this diff for current Codax work.

### 4. Diff Stat Shape

The aggregate diff is small:

- 8 files changed
- 18 insertions
- 18 deletions

This is a narrow schema revision, not a new protocol slice.

## Codax-Relevant Changes

### 1. Core Wire Contract: No Material Change

For Codax's current transport, connection, and client layers, the most important schema files are unchanged.

That means:

- current request and notification method unions did not drift
- initialization modeling did not drift
- the app-server wire contract already documented in the existing reports remains stable across this version bump

For current lower-layer work, this is effectively a no-blocker result.

### 2. `v2/AppInfo.ts` Grew `pluginDisplayNames`

`v2/AppInfo.ts` changed from:

- `isEnabled: boolean`

to:

- `isEnabled: boolean`
- `pluginDisplayNames: Array<string>`

This is the most obviously product-facing schema change in the bundle because it extends a domain payload rather than just renaming supporting types.

Current relevance to Codax:

- there are no current repo references to `AppInfo`
- the current client layer does not expose app/plugin list behavior yet
- this does not block current transport, connection, client, or orchestration work

Future relevance:

- if Codax adds app/plugin listing or settings surfaces, `pluginDisplayNames` will need to be reflected in future DTO modeling

### 3. macOS Permission Modeling Was Renamed And Tightened

The permission-related changes are more structural:

- `PermissionProfile.ts`
  - switched from `MacOsPermissions` to `MacOsSeatbeltProfileExtensions`
- `v2/AdditionalMacOsPermissions.ts`
  - switched from nullable `MacOsAutomationValue` and `MacOsPreferencesValue`
  - to non-null `MacOsAutomationPermission` and `MacOsPreferencesPermission`
  - `accessibility` and `calendar` also shifted from nullable booleans to required booleans
- `index.ts`
  - now exports the new permission types instead of the older `*Value` and aggregate `MacOsPermissions` shapes

This indicates a modeling cleanup or semantic tightening around macOS permission representation.

Current relevance to Codax:

- there are no current repo references to:
  - `PermissionProfile`
  - `AdditionalMacOsPermissions`
  - `MacOsAutomationPermission`
  - `MacOsPreferencesPermission`
  - `MacOsSeatbeltProfileExtensions`
  - `MacOsPermissions`
- none of the current lower-layer Swift code appears to consume these schema roots directly
- this does not currently block the wire-facing foundation or Milestone 5 orchestration work

Future relevance:

- this may matter if Codax later exposes richer app/plugin/system-permission surfaces
- it may also matter if future approval or tool-request flows start surfacing richer macOS permission metadata into the UI

### 4. Existing Reports Remain Behaviorally Valid

Because the main wire roots did not change, the current report set remains behaviorally valid for the current implementation:

- `TRANSPORT_SCHEMA_REPORT.md`
- `CONNECTION_SCHEMA_REPORT.md`
- `CLIENT_SCHEMA_REPORT.md`
- `ORCHESTRATION_SCHEMA_REPORT.md`

They are still pinned to `v0.111.0`, so they are not version-current. But the current diff does not show evidence that they are now materially wrong about the protocol slice Codax currently uses.

## No-Impact / Deferred Changes

### 1. No Current Code References

Targeted repo searches found no current references to the changed schema types inside:

- `Codax/`
- `Docs/`
- `README.md`
- `ROADMAP.md`

That means the current implementation is not directly coupled to the changed schema nodes.

### 2. No Current Orchestration Blocker

The upcoming orchestration work depends primarily on:

- process launch
- initialization
- account/login bootstrap
- thread and turn methods
- server notification application

None of those central areas changed in the `v0.112.0` schema bundle.

So the version bump does not currently block planning or implementing the next orchestration slice.

### 3. No Immediate Swift Migration Needed

Because no currently consumed wire roots changed, there is no immediate need in this pass to:

- update Swift DTOs
- move schema references
- rewrite the current layer reports
- change roadmap sequencing

That does not mean `v0.112.0` should be ignored permanently. It means the right next move is documentation and awareness, not urgent code churn.

## Recommended Follow-Up

### 1. No Action Needed Now

- keep current lower-layer implementation work moving
- do not block orchestration on this schema bump alone
- do not force a broad migration just to retarget the version number

### 2. Docs Retarget Later

At an appropriate documentation cleanup point, the existing layer reports should be retargeted from `v0.111.0` to `v0.112.0`.

Based on the current diff, that retargeting is likely to be mostly editorial for:

- transport
- connection
- orchestration

It may require a small substantive note in the client or future app/plugin-oriented docs if `AppInfo` starts being modeled.

### 3. Code Follow-Up Needed Before A Future Feature Slice

Before implementing any future feature slice that touches:

- app/plugin metadata
- macOS permission modeling
- permission-profile presentation

Codax should:

- validate the `v0.112.0` schema nodes directly
- model the renamed permission types rather than the older `v0.111.0` shapes
- include `pluginDisplayNames` if `AppInfo` becomes part of a typed client surface

## Conclusion

The `v0.111.0` to `v0.112.0` schema diff is real but narrow.

For current Codax work, the important result is not the existence of changed files. It is that the files most central to the app-server wire contract currently used by Codax did not change. That keeps the transport, connection, client, and near-term orchestration work on stable ground.

The changed surface is concentrated in:

- app/plugin metadata via `v2/AppInfo.ts`
- macOS permission/profile modeling

Those changes should be treated as future-facing follow-up areas rather than immediate blockers. The repo should remain aware of the version bump, but it does not need to interrupt the current implementation sequence to absorb `v0.112.0`.
