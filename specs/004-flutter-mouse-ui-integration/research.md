# Research: Flutter Mouse Event UI Integration

## Findings

### Research Task 1: UI Extension Strategy
- **Decision**: Extend `_TaskFormFields` with a conditional field for `scrollMagnitude`.
- **Rationale**: Keeps UI logic encapsulated within `task_create_view.dart`.

### Research Task 2: State Management
- **Decision**: Use existing `TaskCommand` / `TaskProfile` and extend if needed.
- **Rationale**: Avoids refactoring existing provider logic.
EOF
