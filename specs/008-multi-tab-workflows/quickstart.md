# Quickstart: Multi-tab Workflows

## Prerequisites
- Flutter SDK (latest stable)
- Sikulight Engine running locally (for workflow execution)

## Implementation Steps

### 1. Define Models
Create `ui/lib/features/workflow/models/workspace_models.dart` with `WorkspaceSession` and `TabMetadata`.

### 2. Create WorkspaceViewModel
Implement `WorkspaceViewModel` in `ui/lib/features/workflow/view_models/workspace_view_model.dart`.
- Manage `List<TabMetadata>`.
- Handle `openWorkflow(String path)`, `closeTab(String id)`, `reorderTabs(int oldIndex, int newIndex)`.
- Persist state to `session_history.json`.

### 3. Update WorkflowViewModel
Refactor `WorkflowViewModel` to:
- Accept a `String? filePath` in constructor.
- Add an `isModified` getter.
- Update `saveDraft` to `saveToFile()` using the specific file path.

### 4. Build UI Components
- `WorkflowTabBar`: Scrollable list of `WorkflowTab`.
- `WorkflowTab`: Individual tab with title, modified indicator, and close button.
- `EmptyWorkspaceView`: Big "Open Workflow" button and "Recent Files" list.

### 5. Integration in main.dart
- Wrap the app in `ChangeNotifierProvider<WorkspaceViewModel>`.
- Replace `WorkflowScreen` content with a `Column` containing `WorkflowTabBar` and a `Stack` of workflow editors.
