# Feature Specification: UI Refactor and Asset Registry

**Feature Branch**: `006-ui-refactor-asset-registry`  
**Created**: 2026-05-05  
**Status**: Draft  
**Input**: User description: "When the VDA starts, its main screen shall be the VWB view. The VWB's Command Registry view on the left side shall be collapsable so that a new section 'Asset Registry' can be added below it. The Asset Registry lists image assets that are found into the VDA's local storage directory for assets. When the Asset Registry view is expanded, it shall be possible to drag and drop images from the operating system into the Asset Registry, so that they are persisted into the VDA local storage, and listed in the Asset Registry. The Asset Registry provides different presentation layouts to display the image assets it contains: grid, list with image preview and filename."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - VWB as Main Entry (Priority: P1)

When the user starts the Visual Desktop Automation (VDA) tool, they are immediately presented with the Visual Workflow Builder (VWB) as the primary workspace, allowing them to start building or editing workflows without extra navigation.

**Why this priority**: Core UX improvement to make the most used feature the default entry point.

**Independent Test**: Launch the application and verify that the VWB canvas is the first screen visible.

**Acceptance Scenarios**:

1. **Given** the VDA is not running, **When** the user launches the VDA, **Then** the main window displays the Visual Workflow Builder view by default.

---

### User Story 2 - Side Panel Management (Priority: P2)

The user wants to manage their screen space by collapsing or expanding the Command Registry and the new Asset Registry in the left sidebar.

**Why this priority**: Essential for maintaining a clean workspace as the number of registries increases.

**Independent Test**: Click collapse/expand toggles for both Command and Asset registries and verify UI layout adjustments.

**Acceptance Scenarios**:

1. **Given** the VWB view is open, **When** the user clicks the collapse toggle for Command Registry, **Then** the Command Registry section hides, providing more vertical space for the Asset Registry.
2. **Given** both registries are visible, **When** the user collapses both, **Then** the left sidebar area is minimized to maximize the workflow canvas.

---

### User Story 3 - Asset Registration via Drag and Drop (Priority: P1)

The user wants to quickly add image assets (like target patterns for automation) by dragging files directly from their operating system's file explorer into the VDA Asset Registry.

**Why this priority**: Primary way of importing visual data for the automation engine.

**Independent Test**: Drag an image file from the desktop into the expanded Asset Registry section and verify it appears in the list and is saved to the local directory.

**Acceptance Scenarios**:

1. **Given** the Asset Registry is expanded, **When** the user drops an image file (PNG/JPG) into the registry area, **Then** the file is copied to the local VDA assets directory and displayed in the Asset Registry.
2. **Given** an image is dropped, **When** the user checks the local assets folder, **Then** the image file exists there.

---

### User Story 4 - Flexible Asset Browsing (Priority: P3)

The user wants to switch between different layouts (Grid, List) to better find and identify their assets.

**Why this priority**: UX enhancement for managing larger collections of assets.

**Independent Test**: Toggle between Grid and List views and verify the UI changes correctly.

**Acceptance Scenarios**:

1. **Given** the Asset Registry contains several items, **When** the user selects "Grid View", **Then** assets are shown as a grid of thumbnail previews.
2. **Given** the Asset Registry contains several items, **When** the user selects "List View", **Then** assets are shown in a vertical list with a small preview and the filename.

---

### User Story 5 - Asset Renaming (Priority: P2)

The user wants to rename assets to give them more descriptive names without breaking existing workflows that reference them.

**Why this priority**: Improves maintainability of large asset libraries and workflows.

**Independent Test**: Rename an asset in the UI and verify the filename on disk changes, while a workflow using that asset still functions correctly.

**Acceptance Scenarios**:

1. **Given** an asset named "IMG_01.png" is used in a workflow, **When** the user renames it to "Start_Button.png" in the Asset Registry, **Then** the file on disk is renamed, and the workflow still correctly identifies and uses the asset via its internal ID.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The application MUST default to the Visual Workflow Builder (VWB) screen upon startup.
- **FR-002**: The left sidebar MUST be divided into two collapsible sections: "Command Registry" and "Asset Registry".
- **FR-003**: The Asset Registry MUST monitor and display image files (PNG, JPG) located in a designated local storage directory.
- **FR-004**: The Asset Registry MUST support receiving image files via drag-and-drop from the host operating system.
- **FR-005**: Dropped files MUST be persisted (copied) into the local assets storage directory.
- **FR-006**: The Asset Registry MUST provide a layout switcher for "Grid" and "List" views.
- **FR-007**: The "List" view MUST display the image thumbnail preview alongside the filename.
- **FR-008**: The system MUST allow users to delete assets from the registry after a confirmation prompt, which removes the file from the local storage.
- **FR-009**: The system MUST automatically create the local asset storage directory on startup if it does not already exist.
- **FR-010**: The system MUST assign a unique internal ID to every asset upon creation/import.
- **FR-011**: The system MUST use the unique internal ID to reference assets within workflows (VWB).
- **FR-012**: The system MUST allow users to rename assets in the UI, which triggers a rename of the corresponding file on disk while preserving the internal ID.
- **FR-013**: The system MUST detect if an asset's file is missing on disk and display a "Missing" status/icon in the Asset Registry.
- **FR-014**: The system MUST allow users to either remove missing asset entries or re-link them to a new file, maintaining the internal ID.

### Key Entities *(include if feature involves data)*

- **Asset**: Represents a visual pattern or reference image used in automation.
    - **ID**: Internal unique identifier (UUID/string).
    - **Filename**: User-facing name and disk filename.
    - **Path**: Absolute or relative path to the file.
    - **Thumbnail**: Cached or generated preview of the image.
    - **Status**: Current state of the asset (e.g., Available, Missing).

## Success Criteria *(mandatory)*

## Clarifications

### Session 2026-05-05
- Q: How should the system handle a situation where a user drops an image with a filename that already exists in the local storage? → A: Prompt the user to Overwrite, Rename, or Skip.
- Q: Should users be able to delete assets directly from the Asset Registry UI, and what is the expected behavior? → A: Direct Deletion with confirmation.
- Q: What should happen if the designated asset storage directory does not exist when the application starts? → A: Create the directory silently if it's missing.
- Q: Should users be able to rename existing assets within the Asset Registry UI? → A: Yes, rename directly in UI. Renaming must not break functionality (use internal unique ID for references).
- Q: If a user manually renames or deletes an asset file directly in the OS file explorer, how should the system reconcile the internal ID mapping? → A: Mark as "Missing" in UI.

### Measurable Outcomes

- **SC-001**: Users can drag and drop an asset and see it reflected in the registry in under 500ms.
- **SC-002**: 100% of image files added via drag-and-drop are correctly persisted to the local file system.
- **SC-003**: UI transitions (collapsing panels, switching layouts) are smooth, maintaining 60 FPS (under 16.6ms per frame) and completing within 200ms.
- **SC-004**: Renaming an asset takes effect on disk and in UI in under 200ms without breaking workflow references.

## Assumptions

- [Asset storage location]: Assets are stored in a standard subfolder within the application's data directory (e.g., `~/Documents/Sikulight/Assets`).
- [Supported formats]: Initially only PNG and JPG are supported for assets.
- [Duplicate handling]: If a dropped file's name conflicts with an existing asset, the system MUST prompt the user to Overwrite, Rename, or Skip.
- [File System Monitoring]: The app uses a file watcher to detect changes; if a file is removed externally, the entry remains in the registry with a "Missing" status.
- [ID Mapping]: A small metadata file (e.g., `.assets.json`) is maintained in the asset directory to map internal IDs to filenames and other metadata.
