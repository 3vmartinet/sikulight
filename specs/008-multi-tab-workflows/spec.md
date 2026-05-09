# Feature Specification: Multi-tab Workflows

**Feature Branch**: `008-multi-tab-workflows`  
**Created**: 2026-05-08  
**Status**: Draft  
**Input**: User description: "The VDA application shall permit to open multiple workflow files. Each workflow is shown in a tab, like a Web Browser shows web pages in tabs. On start, the VDA always shows at least 1 tab, with the last used workflow file. If no workflow can be found, the VDA shows no tabs, but a menu to open a worklfow file from the filesystem."

## Clarifications

### Session 2026-05-08
- Q: Duplicate File Handling → A: Focus Existing: Attempting to open an already open file simply switches focus to the existing tab.
- Q: Tab Reordering → A: Drag-and-Drop: Users can click and drag tabs to reorder them horizontally.
- Q: Active Tab Selection after Closing → A: Previous Active: Focus the tab that was active immediately before the current one was selected.
- Q: Context Menu Actions → A: Full Context Menu: Right-clicking a tab provides "Close", "Close Others", "Close Tabs to the Right", and "Copy File Path".
- Q: Persistence of Open Tabs (non-active) → A: Persist All: The application remembers which files were open in tabs, but only opens the last active one on start (others appear as history items).
- Q: Visual Indication of Modified State → A: Indicator: Show a small dot or asterisk (e.g., `*`) next to the filename in the tab when there are unsaved changes.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Multiple Open Workflows (Priority: P1)

As an automation developer, I want to open multiple workflow files simultaneously so that I can compare them or copy-paste components between them easily.

**Why this priority**: Core value of the feature; enables multi-tasking and efficient workflow development.

**Independent Test**: Open two different `.swflow` files. Verify that two distinct tabs appear in the tab bar and switching between them updates the workspace content correctly.

**Acceptance Scenarios**:

1. **Given** the application is open with one workflow, **When** I open a second workflow file from the menu, **Then** a new tab is created and focused, showing the content of the second file.
2. **Given** multiple tabs are open, **When** I click on a non-focused tab, **Then** that tab becomes active and the workspace reflects its content immediately.

---

### User Story 2 - Startup Persistence (Priority: P1)

As a returning user, I want the application to automatically reload my last-worked workflow so that I can resume my work immediately without manual navigation.

**Why this priority**: Essential for a professional desktop application experience; reduces friction on startup.

**Independent Test**: Open a workflow, close the application, and restart it. Verify the same workflow is automatically loaded in a tab.

**Acceptance Scenarios**:

1. **Given** I was working on "workflow_A.swflow" before closing the app, **When** I restart the VDA, **Then** "workflow_A.swflow" is automatically opened in a tab.
2. **Given** multiple tabs were open in the previous session, **When** I restart the app, **Then** only the single most recently active workflow is restored in a tab.

---

### User Story 3 - Empty State and First Run (Priority: P2)

As a new user or someone with no recent history, I want a clear way to start working when no workflows are automatically loaded.

**Why this priority**: Ensures the application is usable even when the "last used" logic fails or doesn't apply.

**Independent Test**: Clear the application history/state and launch it. Verify that no tabs are shown and an "Open Workflow" menu is visible.

**Acceptance Scenarios**:

1. **Given** no previous workflow history exists, **When** I start the application, **Then** no tabs are displayed in the workspace.
2. **Given** no tabs are open, **When** the application starts, **Then** a prominent menu or action is displayed to open a workflow from the filesystem.

---

### Edge Cases

- **Missing Files**: What happens when the "last used" workflow file has been moved or deleted from the filesystem? (Assumption: Fallback to the empty state/menu).
- **Tab Overflow**: How does the tab bar handle 10+ open workflows on a small screen? (Assumption: Scrollable tab bar).
- **Unsaved Changes**: The system will automatically save all changes to the workflow file when its tab is closed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a horizontal tab bar at the top of the workspace.
- **FR-002**: System MUST support opening at least 10 concurrent workflow tabs.
- **FR-003**: System MUST persist the file path of the most recently used workflow.
- **FR-004**: System MUST automatically load the most recently used workflow into a tab on application startup.
- **FR-005**: System MUST display a "File Open" interface (menu or button) when no tabs are currently open.
- **FR-006**: System MUST update the tab title to match the filename of the loaded workflow.
- **FR-007**: System MUST allow users to close individual tabs via an "X" button or similar interaction.
- **FR-008**: System MUST automatically save all changes to the workflow file before closing its tab.
- **FR-009**: System MUST prevent opening the same workflow file in multiple tabs; if a file is already open, the system MUST focus its existing tab.
- **FR-010**: System MUST allow users to reorder tabs via drag-and-drop interactions.
- **FR-011**: System MUST focus the previously active tab when the current tab is closed; if no previous tab history exists, it MUST focus the right neighbor (or left if no right neighbor exists) or show the empty state.
- **FR-012**: System MUST provide a context menu on tabs with actions: "Close", "Close Others", "Close Tabs to the Right", and "Copy File Path".
- **FR-013**: System MUST persist the list of all open files across sessions; while only the active one is restored as a tab on startup, others MUST be available in a "Recently Open" or "Session History" menu.
- **FR-014**: System MUST provide a visual indicator (e.g., a dot or asterisk) on the tab when the workflow has unsaved changes.

### Key Entities *(include if feature involves data)*

- **WorkspaceSession**: Represents the current state of the UI, including open tabs and the currently active tab.
- **TabMetadata**: Contains information about an open tab (file path, display name, modification status).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can switch between any two open workflows in under 200ms.
- **SC-002**: Application startup time (to first interactive tab) is under 2 seconds when restoring a standard workflow.
- **SC-003**: 100% of the time, the application correctly identifies and attempts to load the last used file on launch.
- **SC-004**: Users can close all tabs and return to the "Open File" menu state without restarting the app.

## Assumptions

- **File-based**: Workflows are stored as individual files on the local filesystem.
- **Single Instance**: The application runs as a single instance where multiple files are managed via tabs rather than multiple windows.
- **Standard UI**: Tab behavior will follow standard OS/Browser conventions (active tab highlighting, close buttons on hover or always visible).
n hover or always visible).
