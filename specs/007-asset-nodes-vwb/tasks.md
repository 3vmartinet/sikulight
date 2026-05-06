- [X] T001 Initialize feature-specific assets and UI components in ui/lib/features/workflow/
# Implementation Tasks: Asset Workflow Nodes

## Summary
Tasks are organized to support the incremental development of Asset Workflow Nodes, starting with core node creation, followed by configuration, and finally engine execution.

## Dependency Graph
[Setup] -> [Foundational] -> [US1: Click Action] -> [US2: Config & Error Handling] -> [US3: Workflow Failure Logic]

## Phase 1: Setup
- [X] T001 Initialize feature-specific assets and UI components in ui/lib/features/workflow/

## Phase 2: Foundational
- [X] T002 [P] Define `AssetNode` model in ui/lib/features/workflow/models/asset_node.dart
- [X] T003 [P] Add `AssetNode` creation logic to `WorkflowViewModel` in ui/lib/features/workflow/view_models/workflow_view_model.dart

## Phase 3: User Story 1 - Click Action
*Goal: Drag asset, create node, execute click.*
*Test: Drag asset to canvas, verify success on click.*

- [X] T004 [P] [US1] Implement drag-and-drop handler for AssetRegistry to VWB in ui/lib/features/workflow/widgets/workflow_canvas.dart
- [X] T005 [P] [US1] Create `AssetNodeWidget` with thumbnail display in ui/lib/features/workflow/widgets/asset_node_widget.dart
- [X] T006 [US1] Implement execution call for AssetNode in `WorkflowEngine` in ui/lib/features/workflow/services/workflow_engine.dart

## Phase 4: User Story 2 - Node Config & Error Handling
*Goal: Change action and error flag via right pane.*
*Test: Update action dropdown/checkbox and verify engine reflects changes.*

- [X] T007 [P] [US2] Create node configuration UI in `NodeParameterPanel` in ui/lib/features/workflow/widgets/node_parameter_panel.dart
- [X] T008 [P] [US2] Update `WorkflowViewModel` to handle action change and Ignore Error flag in ui/lib/features/workflow/view_models/workflow_view_model.dart
- [X] T009 [US2] Implement node-specific execution params in `WorkflowEngine` in ui/lib/features/workflow/services/workflow_engine.dart

## Phase 5: User Story 3 - Workflow Stop on Failure
*Goal: Ensure workflow stops when asset missing.*
*Test: Run workflow with missing asset and verify engine halts.*

- [X] T010 [US3] Implement logic for Success/Failure port triggering in `WorkflowEngine` in ui/lib/features/workflow/services/workflow_engine.dart
- [X] T011 [US3] Implement execution halt logic when Ignore Error is false in `WorkflowEngine` in ui/lib/features/workflow/services/workflow_engine.dart
- [X] T012 [US3] Add validation for missing assets before startup in `WorkflowViewModel` in ui/lib/features/workflow/view_models/workflow_view_model.dart

## Phase 6: Polish & Cross-Cutting
- [X] T013 [P] Implement retry logic (3 times) for server timeouts in `WorkflowEngine` in ui/lib/features/workflow/services/workflow_engine.dart
- [X] T014 [P] Add retry logging for observability in `engine/src/core/logger.py`

## Parallel Execution Opportunities
- T002, T003 (Models/VM setup)
- T004, T005 (UI components)
- T007, T008 (Configuration UI)
- T013, T014 (Retry logic)

## MVP Scope
User Story 1: Adding and Running a Click Action is sufficient for MVP.
