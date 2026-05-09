# Data Model: Multi-tab Workflows

## Entities

### WorkspaceSession
Represents the persistent state of the application's workspace across launches.

- **activeWorkflowPath**: `String?` (Path to the workflow that was active when the app closed)
- **openFilePaths**: `List<String>` (Paths of all workflows that were open in tabs)
- **lastUpdated**: `DateTime`

### TabMetadata
In-memory representation of an open tab.

- **id**: `String` (Unique ID for the tab instance)
- **name**: `String` (Display name, usually the filename without extension)
- **filePath**: `String?` (Filesystem path, null for new unsaved workflows)
- **isModified**: `bool` (True if there are unsaved changes relative to the disk)
- **viewModel**: `WorkflowViewModel` (The logic controller for this specific tab)

## State Transitions

1. **App Startup**:
   - Load `WorkspaceSession`.
   - If `activeWorkflowPath` exists and file is valid -> Open tab with this file.
   - If no `activeWorkflowPath` -> Check `openFilePaths` (per FR-013) but don't open them as tabs (show in "Recent" menu).
   - If completely empty -> Show `EmptyWorkspaceView` (FR-005).

2. **Opening a Workflow**:
   - Check if `filePath` is already in `TabMetadata.filePath` of any open tab.
   - If yes -> Focus existing tab (FR-009).
   - If no -> Create new `TabMetadata` and `WorkflowViewModel`, add to `WorkspaceViewModel`.

3. **Closing a Tab**:
   - Trigger `WorkflowViewModel.save()`.
   - Remove from `WorkspaceViewModel.tabs`.
   - Update `WorkspaceSession`.
   - Shift focus to the previously active tab (FR-011).
