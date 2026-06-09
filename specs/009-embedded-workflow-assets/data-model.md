# Data Model: Embedded Workflow Assets

## Entities

### WorkflowPackage (.macaque)
The primary ZIP-compressed container for Sikulite workflows.
- **workflow.json**: The serialized `Workflow` model.
- **assets/**: A directory containing all image assets referenced by the workflow.

### IsolatedAssetStore
A temporary local directory where assets are extracted for use during an active session.
- **Path**: `${tempDir}/sikulite_imports/${workflowId}/assets/`
- **Metadata**: Synchronized with the active `WorkflowViewModel` to track valid file references.
- **Lifecycle**: The `workflowId` and its associated path MUST remain stable even if the workflow is renamed during the session.

## Relationships
- **Workflow** (1) -> (N) **Asset**: References are maintained via `assetId`.
- **Active Workflow Tab** (1) -> (1) **IsolatedAssetStore**: Each tab manages its own isolated temporary storage.

## State Transitions
1. **Save**: 
   - Verify existence of all referenced assets in the source (Local Registry or current Isolated Store).
   - Bundle `workflow.json` + `assets/*` into `.macaque`.
2. **Open/Load**:
   - Generate/Retrieve `workflowId`.
   - Create `IsolatedAssetStore`.
   - Extract `.macaque` to store.
   - Map node references in the view model to the temporary extracted paths.
3. **Closure**:
   - Delete `IsolatedAssetStore` when the tab is closed.
4. **Startup**:
   - Scan `sikulite_imports` directory.
   - Delete any sub-directory whose name does not match an active `workflowId` in the restored session.
