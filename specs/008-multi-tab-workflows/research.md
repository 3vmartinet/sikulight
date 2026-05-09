# Research: Multi-tab Workflows

## Decision: Workspace Management Pattern
Use a composite ViewModel pattern. `WorkspaceViewModel` acts as the root coordinator for the entire application workspace, while multiple `WorkflowViewModel` instances represent individual open workflows.

### Rationale
- **Isolation**: Each tab has its own undo/redo history (planned), its own `NodeFlowController`, and its own file association.
- **Scalability**: Easily supports 10+ tabs without cross-contamination of state.
- **Alignment**: Directly follows the "UI/Logic Separation" constitution principle.

## Decision: Tab UI Implementation
Custom horizontal `Scrollable` row for the tab bar to support many tabs. Each tab will be a `StatelessWidget` observing `TabMetadata`.

### Rationale
- **Browser-like**: Standard `TabBar` is often too rigid for dynamic desktop-style tabs with close buttons and drag-and-drop.
- **Flexibility**: Easier to implement custom context menus and drag-and-drop reordering.

## Decision: Session Persistence Strategy
A central `session_history.json` file in the application's document directory.

### Rationale
- **Last Used Restoration**: Stores the `filePath` of the active workflow to restore it on next start (FR-004).
- **History Memory**: Stores the list of previously open tabs to populate the "Recently Open" menu (FR-013).

## Decision: Auto-save Implementation
Inject the target `File` or `filePath` into `WorkflowViewModel`. The existing `_onGraphChanged` listener will be updated to save directly to that file instead of a global draft.

### Rationale
- **Compliance**: Fulfills FR-008 (Auto-save on close).
- **Simplicity**: Leverages existing reactive save logic in `WorkflowViewModel`.

## Alternatives Considered
- **Single ViewModel with switchable data**: Rejected because `NodeFlowController` is complex to "swap" out while maintaining UI state (scroll positions, selection).
- **Full Session Restore**: Rejected as per User Choice (Q1: A - Restore only last active).
