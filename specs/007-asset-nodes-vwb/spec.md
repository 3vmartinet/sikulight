# Feature Specification: Asset Workflow Nodes

**Feature Branch**: `007-asset-nodes-vwb`  
**Created**: Dienstag, 5. Mai 2026  
**Status**: Draft  
**Input**: User description: "An image asset from the Asset Registry (specified in @specs/006-ui-refactor-asset-registry/) can be dragged and dropped as a node onto the VWB (specified in @specs/005-visual-workflow-builder/). This node is called an Asset Node and has an action attach to it in addition to the image asset. The action is one of the actions defined earlier as part of @specs/002-command-persistence/spec.md, @specs/003-mouse-events-support/ and @specs/001-visual-desktop-automation/spec.md. By default, the pre-set action for this node is CLICK. The action can be changed in the right pane of the VWB that shows up when a node is selected. When the VWB execute an Asset Node, it tells the server to find the given image asset on the screen, and execute the dedicated action on it. The action selection is shown as a dropdown selector in the VWB right pane, as already done on the command creation bottom sheet. An Asset Node has two output ports : a success port for when the action is reported to have executed successfully, and a failure port for when the action failed to execute (e.g: the server did not find the image on the screen, or any other error). By default, when an Asset Node's failure port triggers, then the workflow execution shall stop, unless the Asset Node is configured with an ignore error flag. This flag, when activated, allows to continue the workflow execution as if the Asset Node executed successfully. This flag can be changed in the VWB right pane, and is shown as a check box."

## Clarifications

### Session 2026-05-05

- Q: How should the linked image asset be represented visually on the Asset Node? → A: Display a thumbnail of the linked image asset on the node
- Q: How should the VWB handle a node whose referenced asset has been deleted from the registry? → A: Mark node with an error state and prevent workflow start
- Q: How does the system handle a timeout from the server during image search? → A: Automatically retry the search 3 times before failing

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Adding and Running a Click Action (Priority: P1)

A user wants to automate a simple click on a button. They open the Asset Registry, find the button's image, and drag it onto the Visual Workflow Builder canvas. An Asset Node appears. They run the workflow, and the system finds the button on screen and clicks it.

**Why this priority**: Core functionality of the feature. Without this, the feature has no value.

**Independent Test**: Can be tested by dragging an asset, ensuring a node is created, and running the workflow to see if the success port triggers when the image is visible.

**Acceptance Scenarios**:

1. **Given** the VWB is open and the Asset Registry contains a "Submit Button" image, **When** the user drags "Submit Button" onto the VWB canvas, **Then** an Asset Node is created with "Submit Button" as its asset and "CLICK" as its default action.
2. **Given** an Asset Node for "Submit Button" with "CLICK" action, **When** the workflow is executed and the "Submit Button" is visible on screen, **Then** the server performs a click on the button and the Success port of the node triggers.

---

### User Story 2 - Configuring Node Action and Error Handling (Priority: P2)

A user wants to right-click an icon and continue even if it's not found (e.g., an optional popup closer). They drag the icon asset, select the node, change the action to "RIGHT_CLICK" in the right pane, and check "Ignore Error".

**Why this priority**: Provides the necessary flexibility for complex workflows.

**Independent Test**: Can be tested by changing node properties and verifying that the workflow continues even when the image search fails.

**Acceptance Scenarios**:

1. **Given** an Asset Node is selected in the VWB, **When** the user looks at the right pane, **Then** they see a dropdown for "Action" (defaulting to CLICK) and a checkbox for "Ignore Error" (defaulting to unchecked).
2. **Given** an Asset Node with "Ignore Error" enabled and "RIGHT_CLICK" action, **When** the workflow executes and the image is NOT found, **Then** the Failure port triggers but the workflow continues execution as if it were successful.

---

### User Story 3 - Workflow Stop on Failure (Priority: P1)

A user wants to ensure the workflow stops if a critical asset (like a "Confirm" dialog) is not found.

**Why this priority**: Safety and correctness of automation.

**Independent Test**: Can be tested by running a workflow where a critical image is missing and ensuring execution halts.

**Acceptance Scenarios**:

1. **Given** an Asset Node with "Ignore Error" disabled, **When** the workflow executes and the image is NOT found, **Then** the Failure port triggers and the workflow execution stops immediately.

---

### Edge Cases

- **Image found multiple times**: If the image asset is found multiple times on the screen, the system will execute the action on the first match found (top-left priority).
- **Asset deleted from registry**: If a referenced asset is deleted, the corresponding node enters an "Error" state, and the workflow engine MUST prevent execution from starting until the reference is fixed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The VWB MUST support drag-and-drop interactions from the Asset Registry.
- **FR-002**: Dropping an image asset onto the VWB MUST create an "Asset Node".
- **FR-003**: Asset Nodes MUST store the ID or reference of the associated image asset.
- **FR-004**: Asset Nodes MUST have the following configuration properties: `asset_id`, `action` (default: CLICK), `ignore_error` (default: false), and `thumbnail` (visual preview).
- **FR-005**: Asset Nodes MUST have exactly two output ports: "Success" and "Failure".
- **FR-006**: When an Asset Node is selected, the VWB right pane MUST display a dropdown for "Action" and a checkbox for "Ignore Error".
- **FR-007**: The Action dropdown MUST include all actions defined in @specs/001, @002, and @003 (CLICK, RIGHT_CLICK, DOUBLE_CLICK, MOUSE_MOVE, etc.).
- **FR-008**: An "Error" state MUST be triggered and visually displayed on the node when a referenced asset is missing or deleted.
- **FR-009**: Upon execution, the system MUST call the server to locate the image and perform the action.
- **FR-010**: If the server reports success, the "Success" port MUST trigger.
- **FR-011**: If the server reports failure (e.g., image not found, timeout), the "Failure" port MUST trigger.
- **FR-012**: If the "Failure" port triggers and "Ignore Error" is `false`, the workflow engine MUST stop execution.
- **FR-013**: If the "Failure" port triggers and "Ignore Error" is `true`, the workflow engine MUST continue execution.
- **FR-014**: The VWB MUST validate all Asset Node references before starting execution; if any asset is missing, it MUST prevent startup and highlight the erroneous nodes.
- **FR-015**: Upon a server timeout or transient network error, the system MUST automatically retry the request up to 3 times, with a 5s timeout per attempt.
- **FR-016**: On failure after all retries, the system MUST mark the node as 'Failed' but maintain workflow state to allow manual restart.
- **FR-017**: All retry attempts and failures MUST be logged and visible in the execution history.
- **FR-018**: Concurrent execution of the same workflow is prohibited; the engine MUST implement an atomic lock to prevent conflict.
- **FR-019**: Visual search for an asset MUST NOT block the UI for more than 2 seconds.
- **FR-020**: In zero-state or cancelled drag-and-drop scenarios, no node MUST be created.
- **FR-021**: The Python server API MUST support the required visual-action execution endpoints for all defined actions.

### Key Entities *(include if feature involves data)*

- **Asset Node**: A workflow node representing a visual-based interaction.
    - `asset_id`: Reference to the image asset.
    - `thumbnail`: Visual representation of the linked asset displayed on the node canvas.
    - `action`: The type of mouse action to perform.
    - `ignore_error`: Flag to control workflow flow on failure.
- **Workflow Engine**: The component responsible for executing nodes and managing the flow between ports.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can add and fully configure an Asset Node (action + error flag) in under 20 seconds.
- **SC-002**: 100% of Asset Nodes correctly route execution to Success or Failure ports based on server response.
- **SC-003**: 100% of workflows halt correctly on Failure when "Ignore Error" is off.
- **SC-004**: 100% of workflows continue correctly on Failure when "Ignore Error" is on.

## Assumptions

- **Existing Server API**: The server already has an endpoint or capability to receive an image and an action name, and return a success/failure status.
- **Asset Registry Compatibility**: The Asset Registry (from @specs/006) provides a standard drag-and-drop data format that the VWB can parse.
- **VWB Extensibility**: The VWB (from @specs/005) supports custom node types with multiple output ports and side-pane configuration.
- **Action List**: The list of valid actions is static and known (CLICK, DOUBLE_CLICK, etc.).
