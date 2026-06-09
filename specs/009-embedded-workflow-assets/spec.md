# Feature Specification: Embedded Workflow Assets

**Feature Branch**: `009-embedded-workflow-assets`  
**Created**: 2026-06-08  
**Status**: Draft  
**Input**: User description: "The workflow file that can be exported from the export action shall embed all asset files that are referenced by this workflow, so that workflow files can be shared while including all depending resources they require."

## Clarifications

### Session 2026-06-08
- Q: When importing a portable workflow, if an asset filename already exists in the local registry but has different content (hash), how should the system resolve the collision? → A: The assets of a workflow file shall be imported into a dedicated temporary folder, so that there is no collision with the existing assets. The Asset Manager shall display tabs : one shows the local assets, the other shows the assets from the imported workflow.
- Q: When should these "temporary" isolated assets and their corresponding folders be cleaned up/deleted? → A: Delete the temporary folder when the specific workflow tab is closed.
- Q: Should there be a hard limit on bundled assets size, or a warning threshold? → A: No Limit. Allow any size; handle filesystem errors gracefully.
- Q: How should orphans be identified and cleaned up at startup? → A: Selective. On startup, delete any folder in `macaque_imports` that does not match a `workflowId` in the restored session's open tabs.
- Q: Is .macaque a full replacement for .swflow or for export only? → A: .macaque is the primary and only workflow format. All workflows are saved locally as .macaque (ZIP) to always include assets.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Save and Load Portable Workflow (Priority: P1)

A user creates a new workflow and adds nodes with local image assets. When they save the workflow, it is stored as a `.macaque` file containing both the JSON structure and the binary images. When reopened, the assets are extracted to a temporary store for execution.

**Why this priority**: Core requirement. Ensures all workflows are portable by default.

**Independent Test**: Can be tested by creating a workflow, saving it, and verifying the `.macaque` ZIP contains all referenced assets.

**Acceptance Scenarios**:

1. **Given** a workflow with nodes referencing local assets, **When** the user saves, **Then** a single `.macaque` file is produced containing assets.
2. **Given** a saved `.macaque` file, **When** opened, **Then** it must extract assets to isolated temporary storage and display them correctly.

---

### User Story 2 - Share Portable Workflow (Priority: P1)

A user wants to share a complex workflow with a colleague. They provide the `.macaque` file. The colleague opens it in their Macaque instance, and all assets are immediately available in the "Workflow Assets" tab.

**Why this priority**: Key value proposition of the portable format.

**Independent Test**: Can be fully tested by opening a `.macaque` file on a clean Macaque instance.

**Acceptance Scenarios**:

1. **Given** a `.macaque` file from another source, **When** the user opens it, **Then** all nodes display their correct reference images and assets are isolated from local ones.

---

### User Story 3 - Temporary Asset Cleanup (Priority: P2)

When a user closes a workflow tab, the system should automatically clean up the extracted assets from the temporary store.

**Why this priority**: Prevents long-term disk bloat from open workflows.

**Independent Test**: Can be tested by opening a workflow, verifying the temporary folder creation, closing the tab, and verifying deletion.

**Acceptance Scenarios**:

1. **Given** an active workflow tab, **When** the user closes the tab, **Then** the associated temporary asset folder is deleted.

---

### Edge Cases

- **Large Assets**: No hard size limit imposed; system handles large archives by allowing any size and responding to standard filesystem errors (e.g., Disk Full).
- **Name Collisions**: Resolved by isolation in a dedicated temporary folder per active workflow.
- **Unreferenced Assets**: Saved archives include only those assets referenced by the specific workflow.
- **Abnormal Shutdown**: On application startup, the system identifies and deletes any folder in the `macaque_imports` directory that does not correspond to an active tab restored in the current session.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST bundle all referenced image assets into the `.macaque` (ZIP) workflow file.
- FR-002: The `.macaque` format MUST be the primary and sole format for all workflows. The application MUST filter for only `.macaque` extensions in all Open and Save dialogs.
- FR-003: The system MUST extract embedded assets to a dedicated temporary folder unique to each active workflow session.
- FR-004: The system MUST map node references to the extracted temporary assets upon loading.
- FR-005: The system MUST verify asset existence before embedding during save.
- FR-006: The Asset Manager MUST display tabs to distinguish between "Local Assets" and "Workflow Assets" (from the active workflow).
- FR-007: The system MUST delete the temporary asset folder when the corresponding workflow tab is closed.
- FR-008: The system MUST NOT impose a hard limit on the total size of bundled assets. Filesystem errors (e.g., Disk Full) MUST be handled gracefully via Error Dialogs.
- FR-009: On application startup, the system MUST perform a selective cleanup of orphaned folders in the `macaque_imports` directory only AFTER session restoration is confirmed successful.
- FR-010: Renaming a workflow MUST update the UI immediately (Tab title, Header, Asset Registry); the underlying `.macaque` file SHOULD only be renamed on the next Save. The `workflowId` (and temp folder ID) MUST remain stable for the duration of the session.

### Key Entities *(include if feature involves data)*

- **Workflow Package (.macaque)**: The single-file ZIP container representing the saved workflow and its dependencies.
- **Embedded Asset**: A binary asset (e.g., image) stored within the Workflow Package.
- **IsolatedAssetStore**: A temporary directory structure for assets extracted from an active workflow.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of workflows saved with this feature can be successfully run on a different Macaque installation without additional file transfers.
- **SC-002**: Loading a portable workflow takes less than 2 seconds for a package containing 10 assets (measuring from file selection to all nodes being rendered in the UI, excluding decompression/copy time).
- **SC-003**: 0% chance of local asset corruption during load due to isolation logic.
- **SC-004**: 100% of temporary asset folders are cleaned up upon successful tab closure or next startup.

## Assumptions

- **Packaging Format**: The system will use a standard container format (like ZIP) with the `.macaque` extension.
- **Scope**: Only assets explicitly referenced by nodes in the workflow are included.
- **Asset Persistence**: Extracted assets are kept in temporary storage and are NOT automatically merged into the user's permanent local registry.
age and are NOT automatically merged into the user's permanent local registry.
