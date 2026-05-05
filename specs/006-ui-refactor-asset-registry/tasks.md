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

- [ ] T001 Add `desktop_drop`, `watcher`, `uuid`, and `path_provider` dependencies to `ui/pubspec.yaml`
- [ ] T002 Create directory structure for the assets feature in `ui/lib/features/assets/`
- [ ] T003 [P] Configure project-wide constants for asset storage in `ui/lib/core/constants.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 Define `Asset` and `AssetStatus` models in `ui/lib/features/assets/models/asset.dart`
- [ ] T005 Implement `AssetStorageService` for local file I/O and `.assets.json` management in `ui/lib/features/assets/services/asset_storage_service.dart`
- [ ] T006 Implement `AssetViewModel` (ChangeNotifier) to manage state and monitoring in `ui/lib/features/assets/view_models/asset_view_model.dart`
- [ ] T007 Initialize `DirectoryWatcher` within `AssetStorageService` to monitor external changes
- [ ] T008 [P] Implement unit tests for `AssetStorageService` in `ui/test/features/assets/asset_storage_service_test.dart`
- [ ] T009 [P] Implement unit tests for `AssetViewModel` in `ui/test/features/assets/asset_view_model_test.dart`

**Checkpoint**: Foundation ready - asset management logic is verified and ready for UI integration.

---

## Phase 3: User Story 1 - VWB as Main Entry (Priority: P1) 🎯 MVP

**Goal**: Set the Visual Workflow Builder (VWB) as the default screen upon application startup.

**Independent Test**: Launch the app and confirm the VWB screen (not TaskMonitor) is displayed first.

### Implementation for User Story 1

- [ ] T010 [US1] Update `ui/lib/main.dart` to use `WorkflowScreen` as the home widget
- [ ] T011 [US1] Ensure `MultiProvider` in `main.dart` includes `AssetViewModel` at the root level
- [ ] T012 [US1] Refactor `WorkflowScreen.show` to handle navigation/initialization if launched as home in `ui/lib/features/workflow/workflow_screen.dart`

**Checkpoint**: VDA now defaults to the VWB workspace.

---

## Phase 4: User Story 3 - Asset Registration via Drag and Drop (Priority: P1)

**Goal**: Allow users to import image assets by dragging files from the OS into the registry.

**Independent Test**: Drag a PNG file into the expanded Asset Registry panel and verify it is copied to the assets folder and listed.

### Implementation for User Story 3

- [ ] T013 [US3] Create `AssetRegistryPanel` (base container) in `ui/lib/features/assets/widgets/asset_registry_panel.dart`
- [ ] T014 [US3] Implement `DragAndDropOverlay` using `desktop_drop` in `ui/lib/features/assets/widgets/drag_and_drop_overlay.dart`
- [ ] T015 [US3] Implement `AssetStorageService.importAsset` logic to handle persistence and ID assignment
- [ ] T016 [US3] Add "Duplicate Handling" prompt (Overwrite/Rename/Skip) in `ui/lib/features/assets/widgets/duplicate_dialog.dart`

**Checkpoint**: Users can now import assets via drag-and-drop.

---

## Phase 5: User Story 2 - Side Panel Management (Priority: P2)

**Goal**: Divide the left sidebar into collapsible "Command Registry" and "Asset Registry" sections.

**Independent Test**: Click toggles for both registries and verify vertical space is shared or collapsed correctly.

### Implementation for User Story 2

- [ ] T017 [US2] Update `_WorkflowScreenBody` to include both `CommandRegistryPanel` and `AssetRegistryPanel` in `ui/lib/features/workflow/workflow_screen.dart`
- [ ] T018 [US2] Implement a shared `SidebarViewModel` or update `WorkflowViewModel` to track expansion states in `ui/lib/features/workflow/view_models/workflow_view_model.dart`
- [ ] T019 [US2] Create an `ExpandablePanel` wrapper widget in `ui/lib/features/workflow/widgets/expandable_panel.dart` for the registries
- [ ] T020 [US2] Refactor `CommandRegistryPanel` to fit within the new collapsible layout in `ui/lib/features/workflow/widgets/command_registry_panel.dart`

**Checkpoint**: Side panel management is functional, allowing users to toggle between registries.

---

## Phase 6: User Story 5 - Asset Renaming (Priority: P2)

**Goal**: Allow in-UI renaming of assets without breaking workflow references.

**Independent Test**: Rename an asset and verify disk change + workflow node still works.

### Implementation for User Story 5

- [ ] T021 [US5] Implement `AssetViewModel.renameAsset` logic to update disk name and metadata while preserving UUID
- [ ] T022 [US5] Add inline renaming or a dialog in `ui/lib/features/assets/widgets/asset_item_tile.dart`
- [ ] T023 [US5] Update `VdaActionNode` to store `assetId` instead of `path` in `ui/lib/features/workflow/models/workflow_models.dart`
- [ ] T024 [US5] Update node parameter resolution to look up path via ID in `ui/lib/features/workflow/widgets/node_parameter_panel.dart`
- [ ] T030 [US5] Implement deletion confirmation dialog and logic for assets in `ui/lib/features/assets/widgets/delete_dialog.dart`

**Checkpoint**: Assets can be safely managed (renamed/deleted) while maintaining workflow integrity.

---

## Phase 7: User Story 4 - Flexible Asset Browsing (Priority: P3)

**Goal**: Switch between Grid and List views for assets.

**Independent Test**: Toggle the layout icon and verify assets switch between thumbnail grid and list-with-filename.

### Implementation for User Story 4

- [ ] T025 [P] [US4] Implement `AssetGridView` in `ui/lib/features/assets/widgets/asset_grid_view.dart`
- [ ] T026 [P] [US4] Implement `AssetListView` in `ui/lib/features/assets/widgets/asset_list_view.dart`
- [ ] T027 [US4] Add a toolbar with layout switcher to `AssetRegistryPanel` in `ui/lib/features/assets/widgets/asset_registry_panel.dart`
- [ ] T028 [US4] Add "Missing" status indicator/icon to asset items in `ui/lib/features/assets/widgets/asset_item_tile.dart`
- [ ] T028b [US4] Implement "Re-link" and "Remove Missing" UI and logic in `ui/lib/features/assets/widgets/asset_item_tile.dart`

**Checkpoint**: Asset browsing experience is complete with flexible layouts, status detection, and reconciliation tools.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [ ] T029 [P] Update `quickstart.md` with final screenshots or instructions
- [ ] T031 Optimize thumbnail loading performance using `Image.file` cache
- [ ] T032 Verify all `const` widget optimizations per Flutter constitution
- [ ] T033 [P] Add integration test to verify SC-002 (100% persistence) and SC-004 (Renaming performance) in `ui/test/integration/asset_persistence_test.dart`

---

## Dependencies & Execution Order

### Phase Dependencies
- **Phase 1 & 2**: MUST be completed first.
- **Phase 3 & 4**: Can be worked on in parallel once Phase 2 is done.
- **Phase 5**: Depends on Phase 4 (needs the Asset Registry panel to exist).
- **Phase 6**: Depends on Phase 2 & 4.
- **Phase 7**: Depends on Phase 4 & 6.

### Parallel Opportunities
- T008 and T009 (Testing) can run alongside T004-T007.
- US1 (T010-T012) can be implemented while US3 logic (T015) is being developed.
- Grid/List view widgets (T025, T026) can be built in parallel.

---

## Implementation Strategy

### MVP First (User Story 1 & 3)
1. Setup dependencies and core `AssetStorageService`.
2. Set VWB as default view.
3. Implement basic Asset Registry with Drag & Drop.
4. **Validation**: Can I open the app and drop an image?

### Incremental Delivery
1. Add Side Panel management (US2).
2. Add Renaming and ID mapping (US5) to ensure safety.
3. Add Layout switcher and Polish (US4).

---

## Notes
- `AssetStorageService` is the source of truth for all ID-to-Path mapping.
- The `watcher` package will trigger `AssetViewModel` updates automatically for external OS changes.
- Ensure all Flutter UI code follows the decomposition and Provider standards from the project constitution.
