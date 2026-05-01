# Tasks: Flutter Mouse Event UI Integration

**Input**: Design documents from `/specs/004-flutter-mouse-ui-integration/`
**Prerequisites**: plan.md, spec.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project environment and initial checks

- [X] T001 [P] Validate current directory structure against plan.md
- [X] T002 [P] Verify access to `ui/lib/features/tasks/task_create_view.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core UI/State infrastructure preparation.

- [X] T003 Extend `TaskCommand` model in ui/lib/features/tasks/task_command.dart to hold `scrollMagnitude`
- [X] T004 [P] Update `TaskCreateSheet` state in ui/lib/features/tasks/task_create_view.dart to manage new action types

**Checkpoint**: Foundation ready - UI updates can now begin.

---

## Phase 3: User Story 1 - Add Mouse Wheel/Scroll Commands (Priority: P1) 🎯 MVP

**Goal**: Update the UI to include 'Scroll' and 'Middle-Click' actions and parameters.

**Independent Test**: Verify that 'Scroll' and 'Middle-Click' appear in the action dropdown and persist their state.

### Implementation for User Story 1

- [X] T005 [US1] Update `_TaskFormFields` in ui/lib/features/tasks/task_create_view.dart to add 'Scroll' and 'Middle-Click' to dropdown items
- [X] T006 [US1] Implement conditional visibility for scroll magnitude input in ui/lib/features/tasks/task_create_view.dart
- [X] T007 [US1] Add validator to ensure scroll magnitude is numeric in ui/lib/features/tasks/task_create_view.dart
- [X] T008 [US1] Update `_buildTask` in ui/lib/features/tasks/task_create_view.dart to include new fields in `TaskCommand`

**Checkpoint**: User Story 1 should be fully functional and testable independently

---

## Phase 4: Polish & Cross-Cutting Concerns

**Purpose**: Cleanup and validation.

- [X] T009 [P] Verify implementation against quickstart.md scenarios
- [X] T010 Run existing UI unit tests in ui/test/

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies
- **Foundational (Phase 2)**: Depends on Phase 1 - BLOCKS all stories
- **User Story 1 (Phase 3)**: Depends on Phase 2
- **Polish (Phase 4)**: Depends on Phase 3

### Parallel Opportunities

- T001, T002, T009, T010 can be run in parallel where independent.

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Verify tests pass before finalizing
- Commit after each task or logical group
