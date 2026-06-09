# Tasks: Embedded Workflow Assets

**Input**: Design documents from `/specs/009-embedded-workflow-assets/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Tests are INCLUDED as per Constitution III (Test-First).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- Flutter client: `sikulite/lib/`, `sikulite/test/`
- Python engine: `engine/src/`, `engine/tests/`

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 Verify `archive` package in `sikulite/pubspec.yaml` and run `flutter pub get`
- [X] T002 Create directory `sikulite/lib/features/workflow/services/` for archive logic
- [X] T003 [P] Configure structured logging for ZIP operations in `sikulite/lib/core/logger.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Implement `ArchiveService` skeleton in `sikulite/lib/features/workflow/services/archive_service.dart`
- [X] T005 Create `IsolatedAssetStore` helper class for path management in `sikulite/lib/features/workflow/models/isolated_asset_store.dart`
- [X] T006 [P] Update `AssetViewModel` to support isolated asset sources in `sikulite/lib/features/assets/view_models/asset_view_model.dart`

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Save and Load Portable Workflow (Priority: P1) 🎯 MVP

**Goal**: Bundle assets into `.macaque` (ZIP) on save and extract to isolated temporary folder on load, with robust error handling.

**Independent Test**: Save a workflow with assets and verify the `.macaque` ZIP contains all referenced files. Load the file and verify assets are extracted to the temporary isolated store.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T007 [P] [US1] Add unit tests for `.macaque` ZIP creation and extraction in `sikulite/test/features/workflow/services/archive_service_test.dart`, including a "Local Registry Integrity" scenario to verify global assets remain untouched.

### Implementation for User Story 1

- [X] T008 [US1] Implement `ArchiveService.bundleWorkflow` bundling logic in `sikulite/lib/features/workflow/services/archive_service.dart`
- [X] T009 [US1] Implement `ArchiveService.extractWorkflow` extraction logic in `sikulite/lib/features/workflow/services/archive_service.dart`
- [X] T010 [US1] Implement graceful filesystem error handling and user notifications (Error Dialogs) in `sikulite/lib/features/workflow/services/archive_service.dart`, ensuring styling consistency with other system dialogs.
- [X] T011 [US1] Refactor `WorkflowPersistence.saveWorkflow` to bundle assets into `.macaque` in `sikulite/lib/features/workflow/services/workflow_persistence.dart`
- [X] T012 [US1] Refactor `WorkflowPersistence.loadWorkflow` to extract assets from `.macaque` in `sikulite/lib/features/workflow/services/workflow_persistence.dart`
- [X] T013 [US1] Update `WorkflowViewModel` to manage `IsolatedAssetStore` session lifecycle and implement immediate UI updates for Tab title, Header, and Asset Registry on rename in `sikulite/lib/features/workflow/view_models/workflow_view_model.dart`

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Share Portable Workflow (Priority: P1)

**Goal**: Ensure assets from imported workflows are available in a dedicated "Workflow Assets" tab.

**Independent Test**: Open a `.macaque` file and verify that the Asset Manager displays a "Workflow Assets" tab containing the bundled images.

### Tests for User Story 2

- [X] T014 [P] [US2] Add widget test for Asset Manager tab switching in `sikulite/test/features/assets/widgets/asset_registry_panel_test.dart`

### Implementation for User Story 2

- [X] T015 [US2] Refactor `AssetRegistryPanel` to include a TabController for "Local Assets" and "Workflow Assets" in `sikulite/lib/features/assets/widgets/asset_registry_panel.dart`
- [X] T016 [US2] Implement `WorkflowAssetsTab` widget to display isolated assets in `sikulite/lib/features/assets/widgets/workflow_assets_tab.dart`

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Temporary Asset Cleanup (Priority: P2)

**Goal**: Delete temporary folders upon tab closure and perform selective cleanup on application startup.

**Independent Test**: Close a workflow tab and verify its temporary directory is deleted. Start the application with orphaned directories and verify they are purged only after session restoration.

### Tests for User Story 3

- [X] T017 [P] [US3] Add unit tests for cleanup lifecycle and selective startup purge in `sikulite/test/features/workflow/services/cleanup_test.dart`

### Implementation for User Story 3

- [X] T018 [US3] Implement `ArchiveService.deleteIsolatedStore` recursive deletion in `sikulite/lib/features/workflow/services/archive_service.dart`
- [X] T019 [US3] Hook cleanup logic into tab closure events in `sikulite/lib/features/workflow/view_models/workspace_view_model.dart`
- [X] T020 [US3] Implement selective startup cleanup logic in `WorkspaceViewModel.restoreSession` (ensuring success confirmation) in `sikulite/lib/features/workflow/view_models/workspace_view_model.dart`

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [X] T021 [P] Performance validation: verify Load/Save < 2s for 10 assets in `sikulite/test/features/workflow/performance_test.dart`
- [X] T022 [P] Implement UI warning for missing assets during bundling in `sikulite/lib/features/workflow/widgets/save_warning_dialog.dart`, ensuring styling consistency with filesystem error dialogs.
- [X] T023 [P] Update `README.md` and user documentation to reflect the new `.macaque` primary format

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - US1 is the MVP and should be completed before US2 and US3.
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Foundation for saving/loading.
- **User Story 2 (P1)**: Depends on US1 extraction logic.
- **User Story 3 (P2)**: Depends on US1 isolation strategy.

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Service logic before UI integration
- Story complete before moving to next priority

### Parallel Opportunities

- T003 (Logging configuration)
- T006 (ViewModel updates)
- T007 (Unit tests)
- T014 (Widget tests)
- T017 (Cleanup tests)
- All Phase 6 Polish tasks

---

## Parallel Example: User Story 1

```bash
# Launch unit tests for US1:
Task: "T007 [P] [US1] Add unit tests for .macaque ZIP creation and extraction in sikulite/test/features/workflow/services/archive_service_test.dart"

# While implementing the service:
Task: "T008 [US1] Implement ArchiveService.bundleWorkflow bundling logic in sikulite/lib/features/workflow/services/archive_service.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Verify saving/loading works with assets.

### Incremental Delivery

1. Foundation ready.
2. Add US1 → Test independently → MVP!
3. Add US2 → Test Asset Manager integration.
4. Add US3 → Test cleanup logic.

---

## Notes

- Use the `archive` package for all ZIP operations.
- Ensure `workflowId` stability during renames.
- Selective startup cleanup must not purge active session folders.
ers.
