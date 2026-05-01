# Tasks: Mouse Wheel and Scroll Support

**Input**: Design documents from `/specs/003-mouse-events-support/`
**Prerequisites**: plan.md, spec.md, data-model.md

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project environment and initial structure

- [ ] T001 [P] Validate current directory structure against plan.md
- [ ] T002 Update dependencies in engine/requirements.txt (if new ones needed)
- [ ] T003 [P] Ensure logging and error handling structures are available

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure updates that MUST be complete before mouse events can be implemented.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Extend `StandardAction` enum in engine/src/models/task.py to include MIDDLE_CLICK and SCROLL
- [X] T004a [P] [US1] Create unit tests for StandardAction enum extension in tests/unit/test_tasks.py
- [X] T005 [P] Update existing `simulate_click` logic in engine/src/core/input.py to support button mapping and validation
- [X] T005a [P] [US1] Create integration tests for input handling in tests/integration/test_input.py
- [X] T006 Extend API routes in engine/src/api/routes.py to handle new action types

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Perform Mouse Scroll (Priority: P1) 🎯 MVP

**Goal**: Enable vertical and horizontal scrolling through automation.

**Independent Test**: Trigger a scroll action on a scrollable window and verify content movement.

### Implementation for User Story 1

- [X] T007 [US1] Add `scroll` implementation in engine/src/core/input.py using `pyautogui.scroll`
- [X] T008 [US1] Expose scroll functionality via existing API endpoint in engine/src/api/routes.py
- [X] T009 [US1] Add validation for scroll amount in engine/src/api/routes.py

**Checkpoint**: User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Perform Mouse Wheel Click (Priority: P2)

**Goal**: Enable middle-click functionality.

**Independent Test**: Perform a middle-click on a clickable element and verify reaction.

### Implementation for User Story 2

- [X] T010 [US2] Extend `simulate_click` or add dedicated `simulate_middle_click` in engine/src/core/input.py using `pyautogui.click(button='middle')`
- [X] T011 [US2] Update API routes to accept MIDDLE_CLICK action

**Checkpoint**: User Stories 1 AND 2 should both work independently

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Cleanup, validation, and documentation.

- [X] T012 [P] Update documentation in engine/README.md
- [X] T013 Verify implementation against quickstart.md scenarios
- [X] T014 Run existing unit tests in tests/unit/ to ensure no regressions
- [X] T015 [P] Validate latency requirements (FR-005) under test conditions

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies
- **Foundational (Phase 2)**: Depends on Phase 1 - BLOCKS all stories
- **User Stories (Phase 3+)**: All depend on Phase 2
- **Polish (Phase 5)**: Depends on all user stories

### Parallel Opportunities

- T001, T003, T005, T006, T012 can be run in parallel where independent.

---

## Implementation Strategy

### MVP First (User Story 1)

1. Complete Setup + Foundational
2. Implement Scroll (US1)
3. Validate independently
4. Demo/Deploy

### Incremental Delivery

1. Foundation ready
2. Scroll support (US1) complete
3. Middle-click support (US2) complete
4. Final polish (Phase 5)

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Verify tests fail before implementing
- Commit after each task or logical group
