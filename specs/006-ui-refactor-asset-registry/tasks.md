# Tasks: UI Refactor and Asset Registry

**Input**: Design documents from `/specs/006-ui-refactor-asset-registry/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Add `desktop_drop`, `watcher`, `uuid`, `path_provider`, and `image` dependencies to `ui/pubspec.yaml`
- [x] T002 Create directory structure for the assets feature in `ui/lib/features/assets/` and `ui/lib/core/utils/`
- [x] T003 [P] Configure project-wide constants for asset storage and paths in `ui/lib/core/constants.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure and performance utilities that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Implement `IsolateProcessorService` for offloading heavy I/O and image tasks in `ui/lib/core/utils/isolate_processor_service.dart`
- [x] T005 Define `Asset` and `AssetStatus` models in `ui/lib/features/assets/models/asset.dart`
- [x] T006 Implement `AssetStorageService` for metadata and file persistence (using `IsolateProcessorService`) in `ui/lib/features/assets/services/asset_storage_service.dart`
- [x] T007 Implement `AssetViewModel` (ChangeNotifier) for state management and directory monitoring in `ui/lib/features/assets/view_models/asset_view_model.dart`
- [x] T008 [P] Implement unit tests for `IsolateProcessorService` in `ui/test/core/utils/isolate_processor_service_test.dart`
- [x] T009 [P] Implement unit tests for `AssetStorageService` in `ui/test/features/assets/asset_storage_service_test.dart`
- [x] T010 [P] Implement unit tests for `AssetViewModel` in `ui/test/features/assets/asset_view_model_test.dart`

**Checkpoint**: Foundation ready - heavy task offloading and asset logic are verified.

---

## Phase 3: User Story 1 - VWB as Main Entry (Priority: P1) 🎯 MVP

**Goal**: Set the Visual Workflow Builder (VWB) as the default screen upon application startup.

**Independent Test**: Launch the app and confirm the VWB screen (not TaskMonitor) is displayed first.

### Implementation for User Story 1

- [x] T011 [US1] Update `ui/lib/main.dart` to use `WorkflowScreen` as the home widget and load most recent draft (FR-015)
- [x] T012 [US1] Ensure `MultiProvider` in `main.dart` includes `AssetViewModel` and `IsolateProcessorService` at the root level
- [x] T013 [US1] Refactor `WorkflowScreen.show` to support direct launch as the root view in `ui/lib/features/workflow/workflow_screen.dart`

**Checkpoint**: VDA now defaults to the VWB workspace.

---

## Phase 4: User Story 3 - Asset Registration via Drag and Drop (Priority: P1)

**Goal**: Allow users to import image assets by dragging files from the OS into the registry.

**Independent Test**: Drag a PNG file into the expanded Asset Registry panel and verify it is copied to the assets folder and listed.

### Implementation for User Story 3

- [x] T014 [US3] Create `AssetRegistryPanel` (base container) in `ui/lib/features/assets/widgets/asset_registry_panel.dart`
- [x] T015 [US3] Implement `DragAndDropOverlay` using `desktop_drop` in `ui/lib/features/assets/widgets/drag_and_drop_overlay.dart`
- [x] T016 [US3] Implement `AssetStorageService.importAsset` with isolate-based thumbnail generation (FR-010)
- [x] T017 [US3] Add "Duplicate Handling" prompt (Overwrite/Rename/Skip) in `ui/lib/features/assets/widgets/duplicate_dialog.dart`

**Checkpoint**: Users can now import assets via drag-and-drop.

---

## Phase 5: User Story 2 - Side Panel Management (Priority: P2)

**Goal**: Divide the left sidebar into collapsible "Command Registry" and "Asset Registry" sections.

**Independent Test**: Click toggles for both registries and verify vertical space is shared or collapsed correctly.

### Implementation for User Story 2

- [x] T018 [US2] Update `_WorkflowScreenBody` to include both `CommandRegistryPanel` and `AssetRegistryPanel` in `ui/lib/features/workflow/workflow_screen.dart`
- [x] T019 [US2] Implement a shared `SidebarViewModel` or update `WorkflowViewModel` to track expansion states in `ui/lib/features/workflow/view_models/sidebar_view_model.dart`
- [x] T020 [US2] Create an `ExpandablePanel` wrapper widget supporting the 50px collapsed state (FR-002) in `ui/lib/features/workflow/widgets/expandable_panel.dart`
- [x] T021 [US2] Refactor `CommandRegistryPanel` to fit within the new collapsible layout in `ui/lib/features/workflow/widgets/command_registry_panel.dart`

**Checkpoint**: Side panel management is functional, allowing users to toggle between registries.

---

## Phase 6: User Story 5 - Asset Renaming (Priority: P2)

**Goal**: Allow in-UI renaming of assets without breaking workflow references.

**Independent Test**: Rename an asset and verify disk change + workflow node still works.

### Implementation for User Story 5

- [x] T022 [US5] Implement `AssetViewModel.renameAsset` logic to update disk name while preserving UUID (FR-012)
- [x] T023 [US5] Add inline renaming UI or a dialog in `ui/lib/features/assets/widgets/asset_item_tile.dart`
- [x] T024 [US5] Update `VdaActionNode` to store `assetId` instead of `path` in `ui/lib/features/workflow/models/workflow_models.dart`
- [x] T025 [US5] Update node parameter resolution to look up path via ID in `ui/lib/features/workflow/widgets/node_parameter_panel.dart`
- [x] T026 [US5] Implement asset deletion with confirmation and missing file detection (FR-008) in `ui/lib/features/assets/widgets/delete_dialog.dart`

**Checkpoint**: Assets can be safely managed (renamed/deleted) while maintaining workflow integrity.

---

## Phase 7: User Story 4 - Flexible Asset Browsing (Priority: P3)

**Goal**: Switch between Grid and List views for assets.

**Independent Test**: Toggle the layout icon and verify assets switch between thumbnail grid and list-with-filename.

### Implementation for User Story 4

- [x] T027 [P] [US4] Implement `AssetGridView` and `AssetListView` in `ui/lib/features/assets/widgets/asset_views.dart`
- [x] T028 [US4] Add a toolbar with layout switcher to `AssetRegistryPanel` in `ui/lib/features/assets/widgets/asset_registry_panel.dart`
- [x] T029 [US4] Add "Missing" status indicator/icon with re-linking UI (FR-013, FR-014) in `ui/lib/features/assets/widgets/asset_item_tile.dart`
- [x] T029b [US4] Implement metadata corruption recovery UI prompt (FR-016) in `ui/lib/features/assets/widgets/asset_registry_panel.dart`

**Checkpoint**: Asset browsing experience is complete with flexible layouts, status detection, and reconciliation tools.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [x] T030 [P] Update `quickstart.md` with final documentation
- [x] T031 Optimize thumbnail loading using `IsolateProcessorService` for on-demand generation
- [x] T032 Verify all `const` widget optimizations per Flutter constitution
- [x] T033 [P] Add integration test for asset persistence (SC-002) and performance (SC-001, SC-004) in `ui/test/integration/asset_performance_test.dart`

---

## Dependencies & Execution Order

### Phase Dependencies
- **Phase 1 & 2**: MUST be completed first (Setup & Foundation).
- **Phase 3 & 4**: Can be worked on in parallel once Phase 2 is done.
- **Phase 5**: Depends on Phase 4 (needs the Asset Registry panel widget).
- **Phase 6**: Depends on Phase 2 & 4.
- **Phase 7**: Depends on Phase 4 & 6.

### Parallel Opportunities
- Foundational testing (T008-T010) can run alongside core service development.
- VWB Entry (US1) can be implemented while Asset Import (US3) logic is being built.
- Layout switcher in US4 can be built in parallel.

---

## Implementation Strategy

### MVP First (User Story 1 & 3)
1. Setup dependencies and the `IsolateProcessorService` for safety.
2. Set VWB as default view.
3. Implement basic Asset Registry with Drag & Drop.

### Incremental Delivery
1. Add Sidebar expansion/collapse management (US2).
2. Add Renaming and ID mapping (US5).
3. Add Layout switcher and Reconciliation (US4).

---

## Notes
- `IsolateProcessorService` is the mandatory bottleneck for any operation > 16ms (Image resizing, JSON parsing).
- `AssetStorageService` uses the Isolate service for all persistence and metadata updates.
- Ensure all Flutter UI code follows the decomposition and Provider standards from the project constitution.
