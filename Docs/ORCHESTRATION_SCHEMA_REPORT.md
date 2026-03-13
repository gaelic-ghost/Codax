# Orchestration Schema Report

## Summary

This report is intentionally reality-first.

The checked-in repo no longer supports documenting `CodaxViewModel` as the active orchestration layer without qualification. [`CodaxApp.swift`](/Users/galew/Workspace/Codax/Codax/CodaxApp.swift) now instantiates `CodaxOrchestrator`, but the surrounding views, tests, and older narrative docs have not fully caught up.

## Current Relationship

- `CodexConnection`
  - complete typed schema boundary
- `CodexRuntimeCoordinator`
  - sole typed runtime/session boundary
- `CodaxOrchestrator`
  - current checked-in app-facing observable object
- SwiftUI views
  - partially migrated consumers; some files still use placeholders or stale `CodaxViewModel` references
- older orchestration tests
  - still target `CodaxViewModel`

## What Is Verifiably True Now

- the connection layer has complete schema coverage against the pinned `v0.114.0` schema tree
- runtime constructs `LocalCodexTransport`, injects `CodexConnection`, exposes typed request forwarding, and forwards typed notifications and server requests
- `CodaxOrchestrator` owns a `CodexRuntimeCoordinator` and forwards typed request calls through extension files under `Codax/Controllers/Orchestration`
- `CodaxApp` stores a `CodaxOrchestrator` in `@State` and injects it into the app environment
- `CodaxOrchestrator` already owns app-facing observable state such as account, status, project listings, selected thread state, and pending server requests

## What Is Not Safe To Claim Yet

- that SwiftUI views are uniformly migrated to `CodaxOrchestrator`
- that the checked-in app already provides the full SwiftData-backed `@Query` architecture described by earlier docs
- that sidebar project navigation, detail inspector navigation, and toolbar behavior are complete app features rather than partial migration targets
- that the orchestration layer has one settled design across code, tests, and docs

## Practical Conclusion

The orchestration layer is in transition rather than blocked. The repo has a newer top-level orchestrator shape, but the view tree, tests, and prior documentation still expose the older `CodaxViewModel` architecture. Any future cleanup should update code, tests, and narrative docs in the same pass so the repo stops describing two different app layers at once.
