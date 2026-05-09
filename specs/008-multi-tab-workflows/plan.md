# Implementation Plan: Multi-tab Workflows

**Branch**: `008-multi-tab-workflows` | **Date**: 2026-05-08 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/008-multi-tab-workflows/spec.md`

## Summary

Implement a browser-like tabbed navigation system in the Sikulight Flutter UI to allow multiple workflows to be open simultaneously. This includes persistent session management (last active file restoration), a horizontal tab bar with reordering (drag-and-drop), and a context menu for tab operations. All changes will be auto-saved on tab close.

## Technical Context

**Language/Version**: Flutter (Dart) 3.x, Python 3.10+ (Engine)
**Primary Dependencies**: Provider (State Management), path_provider (for session storage)
**Storage**: Local JSON file for `WorkspaceSession` metadata.
**Testing**: Flutter Widget Tests (for tab interactions), Unit Tests (for SessionViewModel).
**Target Platform**: Desktop (Windows/macOS/Linux).
**Project Type**: Desktop-app.
**Performance Goals**: < 200ms tab switching latency, < 2s application startup.
**Constraints**: Zero hardcoded literals (Constants strategy), UI/Logic separation (Provider).
**Scale/Scope**: Support 10+ concurrent tabs.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Implementation Strategy |
|-----------|--------|-------------------------|
| I. UI/Logic Separation | ✅ | Use `WorkspaceViewModel` to manage tab state. |
| II. Python Standards | ✅ | Engine updates (if any) will follow PEP 8. |
| III. Test-First | ✅ | TDD for `WorkspaceViewModel` and Widget tests for `TabBar`. |
| IV. Observability | ✅ | Structured logging for tab open/close/save events. |
| V. Simplicity & YAGNI | ✅ | Start with basic tab management before adding advanced session restore. |

## Project Structure

### Documentation (this feature)

```text
specs/008-multi-tab-workflows/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── checklists/          # Feature checklists
    └── requirements.md
```

### Source Code (repository root)

```text
ui/lib/
├── core/
│   └── constants.dart         # UI Constants (colors, dimensions)
├── features/
│   └── workflow/
│       ├── models/            # TabMetadata, WorkspaceSession
│       ├── view_models/       # WorkspaceViewModel
│       ├── services/          # SessionPersistenceService
│       └── widgets/           # WorkflowTabBar, WorkflowTab, EmptyWorkspaceView
```

**Structure Decision**: Integrated into existing `ui/lib/features/workflow` directory.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

*(No violations detected)*
