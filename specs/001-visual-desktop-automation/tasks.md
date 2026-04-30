# Tasks: Visual Desktop Automation Tool

**Input**: Design documents from `/specs/001-visual-desktop-automation/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Test-first approach requested in Principle III of plan.md.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 Create `engine/` and `ui/` project directories
- [X] T002 Initialize Python engine with dependencies in `engine/requirements.txt`
- [X] T003 Initialize Flutter UI project in `ui/`
- [X] T004 [P] Configure Python linting (Ruff) and formatting (Black)
- [X] T005 [P] Configure Flutter analysis options in `ui/analysis_options.yaml`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T006 Implement `AutomationTask` and `InteractionProfile` models in `engine/src/models/task.py`
- [X] T007 Implement `EngineStatus` model in `engine/src/models/status.py`
- [X] T008 [P] Setup FastAPI application and routing in `engine/src/api/app.py`
- [X] T009 [P] Implement base API client in `ui/lib/core/api_client.dart`
- [X] T010 Implement platform permission check utility in `engine/src/core/permissions.py`
- [X] T011 Configure logging and error handling in `engine/src/core/logger.py`

**Checkpoint**: Foundation ready - UI can talk to Engine, permissions can be checked.

---

## Phase 3: User Story 1 - Automate Button Click via Visual Recognition (Priority: P1) 🎯 MVP

**Goal**: Enable the tool to find a visual element and simulate a click.

**Independent Test**: Provide a screenshot of a button; verify the tool identifies it and performs a single click with visual feedback.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T012 [P] [US1] Unit test for OpenCV template matching in `engine/tests/unit/test_recognition.py`
- [X] T013 [P] [US1] Integration test for `/execute` endpoint in `engine/tests/integration/test_execute.py`

### Implementation for User Story 1

- [X] T014 [P] [US1] Implement screen capture logic in `engine/src/core/capture.py`
- [X] T015 [P] [US1] Implement OpenCV `matchTemplate` logic in `engine/src/core/recognition.py`
- [X] T016 [P] [US1] Implement PyAutoGUI click simulation in `engine/src/core/input.py`
- [X] T017 [US1] Implement visual feedback highlight overlay in `engine/src/core/overlay.py`
- [X] T018 [US1] Create Task creation UI in `ui/lib/features/tasks/task_create_view.dart`
- [X] T019 [US1] Implement execution trigger and monitoring in `ui/lib/features/tasks/task_monitor_view.dart`

**Checkpoint**: User Story 1 functional - MVP complete.

---

## Phase 4: User Story 2 - Delegated Command Invocation (Priority: P2)

**Goal**: Support executing custom scripts when a visual element is found.

**Independent Test**: Map an icon to a script in the "scripts" folder; verify script execution and security rejection of external paths.

### Tests for User Story 2

- [X] T020 [US2] Unit test for script path validation in `engine/tests/unit/test_security.py`

### Implementation for User Story 2

- [X] T021 [US2] Implement script path validation logic in `engine/src/core/security.py`
- [X] T022 [US2] Implement subprocess execution logic for delegated commands in `engine/src/core/executor.py`
- [X] T023 [US2] Update UI to support DELEGATED mode configuration in `ui/lib/features/tasks/task_create_view.dart`

**Checkpoint**: User Story 2 functional - Security and delegated mode verified.

---

## Phase 5: User Story 3 - Cross-Platform Automation (Priority: P3)

**Goal**: Ensure reliability on both Linux and macOS.

**Independent Test**: Run a task configuration on both OS; verify identical behavior and permission handling.

### Implementation for User Story 3

- [ ] T024 [US3] Implement Wayland-specific capture fallbacks in `engine/src/core/capture.py`
- [ ] T025 [US3] Refine platform-specific input simulation (X11 vs macOS) in `engine/src/core/input.py`
- [ ] T026 [US3] Implement permission request UI in `ui/lib/features/setup/permissions_view.dart`

**Checkpoint**: All user stories functional and cross-platform verified.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [ ] T027 [P] Performance optimization for high-DPI displays in `engine/src/core/recognition.py`
- [ ] T028 [P] Documentation updates in `specs/001-visual-desktop-automation/quickstart.md`
- [ ] T029 Add configuration for custom confidence thresholds in `ui/lib/features/settings/settings_view.dart`
- [ ] T030 Final validation of success criteria (SC-001 to SC-005)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies.
- **Foundational (Phase 2)**: Depends on Phase 1.
- **User Stories (Phase 3+)**: All depend on Phase 2.
- **Polish (Phase 6)**: Depends on all stories being complete.

### Parallel Opportunities

- T004, T005 (Formatting)
- T008, T009 (Engine API vs UI Client)
- T012, T013 (Tests for US1)
- T014, T015, T016 (Core engine components)

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Setup and Foundational phases.
2. Complete User Story 1.
3. Validate button click with visual feedback.

### Incremental Delivery

- Foundation -> MVP (US1) -> Advanced Modes (US2) -> Platform Robustness (US3) -> Polish.

---

## Notes

- Use `pytest` for Python tests and `flutter test` for UI.
- Ensure "scripts" directory exists before running US2 tasks.
