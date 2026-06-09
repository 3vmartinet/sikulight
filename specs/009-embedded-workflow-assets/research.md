# Research: Embedded Workflow Assets

## Decision: Portable Format (.macaque)

The feature uses a unified ZIP-based container called `.macaque` for all workflows. This format ensures that every workflow always carries its dependencies (image assets), making sharing and storage inherently portable.

### Rationale:
- **Portability by Default**: Eliminates the "missing asset" problem when moving files between machines or directories.
- **Simplified Asset Management**: Decouples active workflow assets from the local global registry during execution.
- **Selective Startup Cleanup**: Balances safety (restoring previous sessions) with disk maintenance by removing orphaned temporary folders that don't match open tabs.

### Technical Implementation:
- **Unified Format**: `WorkflowPersistence` will use `.macaque` for all save/load operations.
- **Isolation Strategy**: Every open workflow has a unique `workflowId`. Assets are extracted to `${tempDir}/macaque_imports/${workflowId}/assets/`.
- **Startup Cleanup**: `WorkspaceViewModel.restoreSession` will trigger a cleanup pass that deletes any directory in `macaque_imports` whose ID is not present in the restored session's `openFilePaths`.
- **No Hard Limits**: The system will allow any total asset size, relying on Dart's `File` and `Directory` APIs to handle standard OS errors (e.g., Disk Full) gracefully.

### Alternatives Considered:
- **Aggressive Startup Cleanup**: Rejected as it would break the ability to restore tabs from a previous session that crashed or was closed abnormally.

## NEEDS CLARIFICATION Resolved:
- **Format Relationship**: `.macaque` is the sole format.
- **Large Assets**: No hard limits; handle errors gracefully.
- **Startup Cleanup**: Selective pass based on session restoration.
- **UI Tabs**: Distinct "Local Assets" and "Workflow Assets" views in Asset Manager.
