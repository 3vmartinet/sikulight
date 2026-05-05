# Implementation Plan: UI Refactor and Asset Registry

**Branch**: `006-ui-refactor-asset-registry` | **Date**: 2026-05-05 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/006-ui-refactor-asset-registry/spec.md`

## Summary

Refactor the VDA main UI to set the Visual Workflow Builder (VWB) as the default entry point. Implement a dual-registry side panel on the left containing the existing Command Registry and a new Asset Registry. The Asset Registry will manage image assets (PNG/JPG) using a local directory, supporting drag-and-drop import, in-UI renaming, deletion, and "missing" state detection. Assets will be tracked via internal unique IDs to ensure workflow references remain intact during renames.

## Technical Context

**Language/Version**: Flutter (Dart ^3.11.5), Python (3.10+)  
**Primary Dependencies**: `provider`, `path_provider`, `uuid`, `vyuh_node_flow` (Flutter); `fastapi`, `pydantic` (Python)  
**Storage**: Local file system (images), JSON metadata (`.assets.json`) for ID-to-path mapping.  
**Testing**: `flutter_test` (unit/widget), `pytest` (engine integration)  
**Target Platform**: macOS (Darwin) - based on current environment.  
**Project Type**: Desktop Application (Flutter) with Local Engine (Python).  
**Performance Goals**: Drag-and-drop reflection < 500ms; UI transitions (layout/collapse) < 200ms.  
**Constraints**: Zero hardcoded UI strings; strict UI/Logic separation (Provider).  
**Scale/Scope**: Support for hundreds of image assets; single-user local automation.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Flutter UI/Logic Separation**: Business logic will reside in `AssetViewModel`. UI widgets will be decomposed.
- [x] **Python Server Standards**: Any engine-side updates (permissions, storage access) will follow PEP 8 and FastAPI/Pydantic patterns.
- [x] **Test-First**: TDD will be applied to `AssetViewModel` and ID mapping logic.
- [x] **Observability**: Structured logging using `debugPrint` in Flutter.
- [x] **Simplicity & YAGNI**: No database; using simple JSON metadata file for asset tracking.

## Project Structure

### Documentation (this feature)

```text
specs/006-ui-refactor-asset-registry/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── checklists/
    └── requirements.md  # Quality checklist
```

### Source Code (repository root)

```text
ui/lib/
├── features/
│   ├── workflow/        # Existing VWB (startup refactor)
│   └── assets/          # NEW: Asset Registry feature
│       ├── models/      # Asset entity
│       ├── view_models/ # AssetViewModel (ChangeNotifier)
│       ├── widgets/     # AssetRegistryPanel, Layouts, DragAndDropOverlay
│       └── services/    # AssetStorageService (I/O, Watcher)
engine/src/
├── core/
│   └── storage.py       # Potential engine-side asset path management
```

**Structure Decision**: Standard feature-based structure for Flutter; adding a new `assets` feature module.

## Complexity Tracking

*No constitution violations identified.*
