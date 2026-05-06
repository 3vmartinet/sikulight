# Implementation Plan: Asset Workflow Nodes

**Branch**: `007-asset-nodes-vwb` | **Date**: Dienstag, 5. Mai 2026 | **Spec**: [specs/007-asset-nodes-vwb/spec.md](spec.md)
**Input**: Feature specification from `specs/007-asset-nodes-vwb/spec.md`

## Summary

This feature adds support for "Asset Nodes" to the Visual Workflow Builder. Asset Nodes are created by dragging image assets from the Asset Registry and allow users to define specific mouse actions (e.g., CLICK, RIGHT_CLICK) to perform on the identified image. The nodes support success/failure ports and a configurable "Ignore Error" flag for resilient automation.

## Technical Context

**Language/Version**: Flutter (Dart) / Python 3.10+ (FastAPI)  
**Primary Dependencies**: Provider (Flutter), FastAPI (Python server)  
**Storage**: JSON-based workflow persistence  
**Testing**: TDD using `pytest` (Server) and `flutter_test` (Client)  
**Target Platform**: Desktop (macOS/Linux)  
**Project Type**: Desktop automation GUI + Python engine  
**Performance Goals**: Image recognition < 2 seconds, UI responsiveness < 100ms. Search timeout: 5s default.  
**Constraints**: Zero hardcoded magic numbers, must follow Provider pattern  
**Scale/Scope**: Automated workflow orchestration

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] UI/Logic Separation: ViewModels for AssetNode configuration.
- [x] Test-First: Mandatory TDD for new feature logic.
- [x] Zero Duplication: Constants defined in `constants.dart`.
- [x] Observability: Structured logging included.

## Project Structure

### Documentation (this feature)

```text
specs/007-asset-nodes-vwb/
├── plan.md              
├── research.md          
├── data-model.md        
├── quickstart.md        
├── contracts/           
└── tasks.md             
```

### Source Code

```text
ui/lib/features/workflow/
├── models/             # AssetNode configuration
├── services/           # Workflow engine execution
├── view_models/        # Sidebar VM for node config
└── widgets/            # AssetNode canvas widget

engine/src/core/
├── executor.py         # Workflow execution logic
└── recognition.py      # Image asset recognition
```

**Structure Decision**: Selected structure utilizes existing feature-based organization in `ui/` and core service-based organization in `engine/`.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A       | N/A        | N/A                                 |
