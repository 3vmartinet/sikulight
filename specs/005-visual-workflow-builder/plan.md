# Implementation Plan: Visual Workflow Builder (VWB)

**Branch**: `005-visual-workflow-builder` | **Date**: 2026-05-03 | **Spec**: [specs/005-visual-workflow-builder/spec.md](spec.md)
**Input**: Feature specification from `/specs/005-visual-workflow-builder/spec.md`

## Summary

Implement a Visual Workflow Builder (VWB) using the `vyuh_node_flow` Flutter package. The VWB will allow users to visually compose Visual Desktop Automation (VDA) tasks into complex graphs with sequential, conditional, and repetitive logic. A new Workflow Engine (WE) in the Flutter app will manage execution state and communicate with the Python engine via existing API contracts.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x (Client), Python 3.10+ (Server)  
**Primary Dependencies**: `vyuh_node_flow`, `value_notifier_tools`, `provider`, `http` (Dart); `fastapi`, `pydantic` (Python)  
**Storage**: Local filesystem (Workflow files saved as JSON)  
**Testing**: `flutter_test` (Unit/Widget), `pytest` (Integration with Engine)  
**Target Platform**: macOS, Linux  
**Project Type**: Desktop Application (Flutter GUI) + Backend Service (Python API)  
**Performance Goals**: 60 FPS graph rendering, <100ms execution state updates  
**Constraints**: Offline execution, restricted script paths, single active workflow  

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Requirement | Compliance Plan |
|-----------|-------------|-----------------|
| **UI/Logic Separation** | Use Provider + ViewModels | Implement `WorkflowViewModel` and `WorkflowEngine` (Service). UI widgets will be stateless/const. |
| **Python Standards** | PEP 8, Pydantic, Service classes | Ensure any new API endpoints or engine logic follow established Python patterns. |
| **Test-First** | TDD mandatory | Define test cases for graph-to-engine command translation before implementation. |
| **Observability** | Structured logging | Use `debugPrint` in Flutter and `logging` in Python for all workflow transitions. |
| **Simplicity** | YAGNI | Focus on core `vyuh_node_flow` integration first before adding advanced debugging features. |

## Project Structure

### Documentation (this feature)

```text
specs/005-visual-workflow-builder/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output
```

### Source Code (repository root)

```text
engine/
├── src/
│   ├── api/             # API routes for workflow execution
│   └── core/            # Execution logic
└── tests/

ui/
├── lib/
│   ├── core/            # API client updates
│   └── features/
│       └── workflow/    # VWB feature (ViewModels, Widgets, Engine)
└── test/
    └── features/
        └── workflow/    # Workflow-specific tests
```

**Structure Decision**: Extending the existing decoupled Flutter/Python structure. The VWB logic will live in a new `workflow` feature folder in the Flutter app.

## Complexity Tracking

*No current violations. The use of `vyuh_node_flow` is justified as it provides the necessary graph management primitives.*
