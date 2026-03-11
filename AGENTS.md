# Codax Agent Policy

## Apple Docs Gate

- For any task involving Swift, any Apple framework, any Apple platform, or any project that uses `.xcodeproj` or `.xcworkspace`, read the relevant Apple documentation first before planning, proposing, or making changes.
- This rule applies to SwiftUI, SwiftData, Observation, AppKit, UIKit, Foundation-on-Apple, Xcode tooling, build settings, project structure, and Apple platform runtime behavior.
- Use Dash or Xcode documentation tools first. Use official Apple documentation next when local docs are insufficient.
- Before proposing an approach or making a change, state the specific documented API behavior, lifecycle rule, or workflow requirement being relied on.
- Do not rely on memory, habit, or analogy as the primary source when Apple documentation exists.
- If the current code conflicts with Apple documentation, stop and report the conflict before continuing.
- If no relevant Apple documentation can be found, say that explicitly before proceeding.

## Repo Defaults

- Follow the global `AGENTS.md` for general workflow and tool policy unless this repository overrides it explicitly.
- For Apple-platform work in this repository, the Apple Docs Gate above is mandatory and takes precedence over convenience or prior patterns.

