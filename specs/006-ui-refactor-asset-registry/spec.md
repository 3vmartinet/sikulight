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

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The application MUST default to the Visual Workflow Builder (VWB) screen upon startup.
- **FR-002**: The left sidebar MUST be divided into two collapsible sections: "Command Registry" and "Asset Registry".
- **FR-003**: The Asset Registry MUST monitor and display image files (PNG, JPG) located in a designated local storage directory.
- **FR-004**: The Asset Registry MUST support receiving image files via drag-and-drop from the host operating system.
- **FR-005**: Dropped files MUST be persisted (copied) into the local assets storage directory.
- **FR-006**: The Asset Registry MUST provide a layout switcher for "Grid" and "List" views.
- **FR-007**: The "List" view MUST display the image thumbnail preview alongside the filename.

### Key Entities *(include if feature involves data)*

- **Asset**: Represents a visual pattern or reference image used in automation. Key attributes include filename, local path, and thumbnail preview.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can drag and drop an asset and see it reflected in the registry in under 500ms.
- **SC-002**: 100% of image files added via drag-and-drop are correctly persisted to the local file system.
- **SC-003**: UI transitions (collapsing panels, switching layouts) are smooth and occur without visible lag.

## Assumptions

- [Asset storage location]: Assets are stored in a standard subfolder within the application's data directory (e.g., `~/Documents/Sikulight/Assets`).
- [Supported formats]: Initially only PNG and JPG are supported for assets.
- [Duplicate handling]: Dropping a file with an existing name will overwrite the existing asset (default behavior).
- [File System Monitoring]: The app uses a file watcher to automatically update the registry if files are changed externally in the local directory.
