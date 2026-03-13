# Contributing to Codax

Thanks for taking an interest in Codax.

Codax is a public early-alpha project. Contributions are welcome, but the repo is still in a stage where protocol and architecture work are moving faster than the app shell and UI. The most helpful contributions right now are small, scoped, and aligned with the current roadmap.

## Current Project State

Codax is currently a native macOS Codex client under active development.

What is already real in the checked-in code:

- transport and process-launch hardening
- a JSON-RPC `CodexConnection` layer
- a full generated connection-owned schema boundary
- a runtime layer centered on `CodexRuntimeCoordinator`
- a checked-in `CodaxOrchestrator` used by the app entrypoint
- initial compatibility gating for Codex CLI `0.114.x`
- layer reports grounded in the current `v0.114.0` schema baseline

What is still visibly in transition:

- several docs still refer to the older `CodaxViewModel` architecture
- orchestration tests still target `CodaxViewModel`
- some SwiftUI views are placeholders or still reference older app-layer types
- the current app shell should not be treated as proof that SwiftData `@Query`, inspector navigation, and toolbar behavior are fully migrated

Version-support policy while `codex` is still pre-`v1`:

- Codax aims to support the latest released `codex app-server` schema version, not a wide matrix of `0.x` releases
- when the CLI is still pre-`v1`, treat the newest upstream schema release as the intended target for generator, docs, and protocol audit work
- the in-repo compatibility gate may remain pinned to the currently verified CLI build while that latest-version work is being landed

Please do not assume unfinished layers are stable just because the repo is public.

## Before You Start

Small, focused contributions are easiest to review and merge.

You can usually go straight to a pull request for:

- typo fixes
- documentation cleanup
- narrowly scoped tests
- small bug fixes that do not change architecture or roadmap direction

Please open an issue first, or otherwise coordinate before investing implementation time, if your change is any of the following:

- a new feature
- an architecture or layering change
- a roadmap-expanding proposal
- a change that cuts across multiple subsystems
- a UI direction change with significant product impact

For this repo in particular, that applies strongly to work spanning `Transport`, `Connection`, `Runtime`, `Orchestration`, and the current split-view UI shell.

## Good First Contribution Areas

The highest-value contribution areas right now are:

- schema and report alignment
- connection and runtime refinement
- migration cleanup between `CodaxViewModel` leftovers and `CodaxOrchestrator`
- SwiftUI shell cleanup
- accessibility-first UI groundwork
- documentation cleanup and consistency fixes

If you want deeper implementation context before changing protocol-facing code, start with:

- [ROADMAP.md](/Users/galew/Workspace/Codax/ROADMAP.md)
- [TRANSPORT_SCHEMA_REPORT.md](/Users/galew/Workspace/Codax/Docs/TRANSPORT_SCHEMA_REPORT.md)
- [CONNECTION_SCHEMA_REPORT.md](/Users/galew/Workspace/Codax/Docs/CONNECTION_SCHEMA_REPORT.md)
- [ORCHESTRATION_SCHEMA_REPORT.md](/Users/galew/Workspace/Codax/Docs/ORCHESTRATION_SCHEMA_REPORT.md)

## Development Workflow

Keep the workflow lightweight:

1. Branch from `main`.
2. Keep the change focused.
3. Align the change with the current roadmap and architecture slices.
4. Update docs when behavior, architecture boundaries, or repo layout change.
5. Regenerate the connection schema surface when changing `codex-schemas` or the schema generator.

A few practical expectations:

- prefer small PRs over broad mixed changes
- keep naming and terminology aligned with the current checked-in layers: `Transport`, `Connection`, `Runtime`, and `Orchestration`
- if your change crosses layer boundaries, explain why that boundary shift is necessary
- keep docs aligned with current roadmap milestones, layer boundaries, schema-version framing, and the repo's transition state
- if you change `codex-schemas` or either generator script, regenerate the checked-in connection surface before build/test
- if your change touches stale `CodaxViewModel` references, either update the full affected slice or clearly document why the migration is still partial
- treat accessibility regressions, protocol drift, and untested behavior changes as high-risk

## Checks Before Opening a PR

Run the checks that are intended to matter in this repo:

```bash
node Tools/generate_connection_schema.js
node Tools/update_connection_schema_progress.js --verify
xcodebuild -project Codax.xcodeproj -scheme Codax -sdk macosx build
xcodebuild -project Codax.xcodeproj -scheme Codax -destination 'platform=macOS' test
```

The default `Codax` scheme test workflow uses the repo's `Codax.xctestplan`, with target-level parallelization disabled for the `CodaxTests` target.

This contribution guide does not restate a passing test count because the app-layer migration is still in flight and verification should be confirmed against the current checkout.

This repo does not currently have documented CI workflows, issue templates, or PR templates. Please do not assume hidden automation is going to catch missing verification for you.

## Pull Request Expectations

`main` is protected. Pull requests are required to merge.

Current GitHub review and merge behavior:

- one approving review is required
- conversation resolution is required
- squash merge is enabled
- merge commits are disabled
- rebase merges are disabled
- head branches are deleted on merge

Please keep PR descriptions concise and useful. A good PR description should say:

- what changed
- why it changed
- what you verified locally

If your change is architecture-sensitive, explain the boundary decisions clearly.

## Issues and Discussion

If you are looking for a place to start, the current label set includes:

- `bug`
- `documentation`
- `enhancement`
- `good first issue`
- `help wanted`
- `question`

Please prefer issues, or other explicit discussion with the maintainer, before starting work on larger feature ideas or roadmap-sized changes.

## Licensing

Codax is licensed under Apache License 2.0. See [LICENSE](/Users/galew/Workspace/Codax/LICENSE).

Unless explicitly stated otherwise, contributions submitted to this repository are expected to be compatible with that license. This guide does not introduce a separate CLA, DCO, or copyright assignment policy.

## Notes

- This contribution guide will evolve as the project gains CI, templates, and a more mature review workflow.
- The repo is public, but still intentionally early.
- A contribution being technically possible does not automatically mean it is aligned with the current roadmap or review bandwidth.
