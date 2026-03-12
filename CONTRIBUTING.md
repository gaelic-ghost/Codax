# Contributing to Codax

Thanks for taking an interest in Codax.

Codax is a public early-alpha project. Contributions are welcome, but the repo is still in a stage where protocol and architecture work are moving faster than the app shell and UI. The most helpful contributions right now are small, scoped, and aligned with the current roadmap.

## Current Project State

Codax is currently a native macOS Codex client under active development.

What is already real:

- transport and process-launch hardening
- a JSON-RPC `Connection` layer
- a full generated connection-owned schema boundary
- a SwiftData-backed durable thread read model
- a dedicated persistence bridge between runtime types and SwiftData
- initial compatibility gating for Codex CLI `0.114.x`
- a `NavigationSplitView` shell whose sidebar is a project-rooted `NavigationStack` backed by SwiftData `@Query` reads
- a compact detail inspector rail backed by a detail-local `NavigationStack`
- app-shell toolbar actions for project import, thread creation, and inspector visibility
- layer reports grounded in the current `v0.114.0` schema baseline

What is still early or incomplete:

- the current `NavigationSplitView` shell still needs broader pane behavior, polish, and accessibility work
- broader UX polish
- the full accessibility pass
- broader reduction of the full typed schema surface into polished app behavior

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
- broader notification and app-behavior coverage
- runtime and view-model refinement
- SwiftData bridge and durable projection refinement
- SwiftUI shell and pane-state cleanup
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
- keep naming and terminology aligned with the existing `Transport`, `Connection`, `Runtime`, and `ViewModel` vocabulary
- if your change crosses layer boundaries, explain why that boundary shift is necessary
- keep docs aligned with current roadmap milestones, layer boundaries, and schema-version framing
- if you change `codex-schemas` or either generator script, regenerate the checked-in connection surface before build/test
- if you change the durable projection mapping, keep the `@Query` views, `CodaxPersistenceBridge`, and SwiftData models aligned in the same pass
- treat accessibility regressions, protocol drift, and untested behavior changes as high-risk

## Checks Before Opening a PR

Run the checks that are real today:

```bash
node Tools/generate_connection_schema.js
node Tools/update_connection_schema_progress.js --verify
xcodebuild -project Codax.xcodeproj -scheme Codax -sdk macosx build
xcodebuild -project Codax.xcodeproj -scheme Codax -destination 'platform=macOS' test
```

The default `Codax` scheme test workflow uses the repo's `Codax.xctestplan`, with target-level parallelization disabled for the `CodaxTests` target.

Current baseline verification is `90` passing tests in `10` suites.

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
