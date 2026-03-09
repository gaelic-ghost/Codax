# Codax

An accessibility-forward native macOS Codex client that uses your locally installed `codex` & subscription via `codex app-server`.

Codax is in early alpha. The protocol and architecture layers are already taking shape, but the app shell and UI are placeholder at best. This repo is best read today (March 8, 2026) as an active construction site. More "in-development contributor-facing project" than "polished end-user app". But hey, it's day two of development, we'll get there pretty soon at this pace.

## Table of Contents

- [What Codax Is](#what-codax-is)
- [Current Status](#current-status)
- [Why This Project Exists](#why-this-project-exists)
- [Architecture At A Glance](#architecture-at-a-glance)
- [Repository Layout](#repository-layout)
- [Requirements](#requirements)
- [Getting Started](#getting-started)
- [Project Documentation](#project-documentation)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [Notes](#notes)

## What Codax Is

Codax is a native macOS client for the Codex app-server protocol. It is being built to work with your existing local Codex installation rather than replacing that tooling with a separate hosted interface or a closed workflow.

The project is explicitly accessibility-forward. The long-term goal is a usable, native, multi-pane Codex desktop app that is workable with assistive technology, and feels best-in-class for anyone's 'day-to-day engineering workflow on macOS. Maybe even on iOS~

## Current Status

The repository already has real protocol-facing work in place:

- transport and process-launch foundations
- an actor-based JSON-RPC connection layer with request and response correlation plus tested retry handling for retryable overloads
- initial typed client wrappers for current app-server methods
- transport and connection schema reports grounded in pinned Codex schema dumps

The app-facing layers are still early:

- orchestration is not complete yet
- the `NavigationSplitView` shell is still planned work. The design is locked down, implementation is roadmapped after completing the orchestration layer.
- the current SwiftUI app launches from a minimal placeholder view
- compatibility detection, UX polish, and the full accessibility pass are still in progress, or roadmapped for the near future.

## Why This Project Exists

Codax exists to make agentic coding more accessible and less confining. The project is aimed at developers who want a native desktop client that respects their existing tools, local workflows, and project environments instead of forcing them into a simplified or walled-garden experience.

Just as important, the project is being shaped around accessibility from the start. I know *very well* that the only way to get it right is to bake it in from day-one. I don't just want to put Codex in a working UI that performs well and looks nice. I don't just want to add high-value features that I'm tired of waiting for in the big names' products. I want to bring Codex (and many other tools, stay tuned~) to everyone like me who gets left behind by tech advancements year after year. Decade after decade. I want people such as myself to have great tools that don't exclude them, slow them down, frustrate them, or cause them physical pain.

## Architecture At A Glance

The codebase is currently organized into a small set of explicit layers:

- `Transport`
  - `CodexTransport` defines raw transport behavior as a protocol.
  - `CodexTransport+Stdio` is the current actor-based stdio transport implementation.
  - `CodexProcess` launches the local `codex app-server` process.

- `Connection`
  - `CodexConnection` owns actor-based JSON-RPC framing, request correlation, retry handling, and inbound routing.
- `Client`
  - `CodexClient` provides typed wrappers over the generic connection layer.
- `Orchestration`
  - `CodaxOrchestrator` and `AuthCoordinator` are intended to become the app-facing session and auth coordination layer.
- `Views`
  - SwiftUI views currently exist as a minimal shell and will later become the multi-pane desktop interface.

`CodaxTests` exists as the baseline test target, though meaningful transport and client coverage still needs to be expanded.

## Repository Layout

The main areas of the repository are:

- `Codax/Controllers/Transport`
  - transport protocols, stdio transport, websocket placeholder support, and process-launch types
- `Codax/Controllers/Connection`
  - JSON-RPC message types, connection state, and request-routing behavior
- `Codax/Controllers/Client`
  - typed request wrappers, inbound message lifting, and server-request handling
- `Codax/Controllers/Orchestration`
  - early orchestration and auth coordination types
- `Codax/Views`
  - the current SwiftUI shell
- `CodaxTests`
  - baseline test target
- `Docs`
  - schema and protocol reports used to ground the implementation

## Requirements

Codax currently assumes:

- macOS
- Xcode
- `codex` CLI installed locally to run the app-server over stdio

The repository does not currently present itself as a packaged or stable released app.

## Getting Started

1. Open in Xcode.
2. Build the `Codax` app target.
3. Run the app from Xcode.

Current expectations:

- the app launches as a minimal SwiftUI shell
- protocol-facing layers are ahead of the UI
- some end-to-end app flows are still incomplete

If you are contributing to protocol work, the schema reports and roadmap are the best starting points after opening the project.

## Project Documentation

Project docs currently worth reading first:

- [ROADMAP.md](/Users/galew/Workspace/Codax/ROADMAP.md)
- [TRANSPORT_SCHEMA_REPORT.md](/Users/galew/Workspace/Codax/Docs/TRANSPORT_SCHEMA_REPORT.md)
- [CONNECTION_SCHEMA_REPORT.md](/Users/galew/Workspace/Codax/Docs/CONNECTION_SCHEMA_REPORT.md)

These documents describe the intended milestone sequencing, the transport and connection contracts, and the current implementation gaps still being closed.

## Roadmap

The roadmap is maintained in [ROADMAP.md]().

At a high level, the project is moving in bounded slices:

- transport
- connection
- client
- orchestration
- UI shell
- accessibility and UX refinement

Later milestones cover compatibility management, thread and code summarization features, and performance work.

## Contributing

Contribution guidance lives in [CONTRIBUTING.md]().

The most useful contributions right now are likely to be in:

- transport and connection test coverage
- orchestrator implementation
- the planned `NavigationSplitView` shell
- accessibility-first UI and interaction work
- compatibility detection and protocol hardening

## Notes

- Codax is currently an early, pre-alpha project.
- The API is initially being built around Codex 0.111.0
- Local Codex version and compatibility handling is still being built out.
- The repository does not yet document a polished release or distribution workflow.
- The current README is intentionally contributor-first because the architecture is further along than the end-user product surface.
