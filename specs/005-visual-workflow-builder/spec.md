# Feature Specification: Visual Workflow Builder (VWB)

**Feature Branch**: `005-visual-workflow-builder`  
**Created**: 2026-05-03  
**Status**: Draft  
**Input**: User description: "Create a visual workflow builder (VWB) for the visual desktop automation (VDA) app specified as part of @specs/001-visual-desktop-automation/spec.md. The VWB allows to organize the actions created by the VDA as a graph. The actions are automation steps that can be chained together, executed in sequence or repeatedly, based on the result of the automation steps or user-defined conditions."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Chaining Sequential Actions (Priority: P1)

As an automation user, I want to visually link multiple automation steps in a sequence so that I can automate complex multi-step UI tasks like logging into a website or navigating a menu system.

**Why this priority**: Chaining is the fundamental requirement for any workflow beyond a single isolated action. It provides the base value for complex automation.

**Independent Test**: Can be tested by creating a workflow with three sequential clicks (e.g., File -> New -> Text Document) and verifying they execute in order.

**Acceptance Scenarios**:

1. **Given** a set of predefined VDA actions, **When** I link them sequentially in the VWB, **Then** the system executes them one after another in the specified order.
2. **Given** a sequential workflow, **When** a middle step fails (element not found), **Then** the execution stops and reports the failure at that specific step.

---

### User Story 2 - Conditional Branching (Priority: P2)

As a power user, I want to define branches in my workflow based on the success or failure of an automation step, so that the tool can handle different UI states dynamically.

**Why this priority**: Enables robust automation that can recover from errors or handle "forks" in the application logic (e.g., "If Update dialog appears, click Close; otherwise, continue").

**Independent Test**: Create a workflow where an action looks for an "Optional Message". If found, click "OK"; if not found, continue to the final step.

**Acceptance Scenarios**:

1. **Given** an "If-Else" node linked to a VDA action, **When** the action succeeds, **Then** the workflow follows the "Success" path.
2. **Given** an "If-Else" node linked to a VDA action, **When** the action fails (timeout), **Then** the workflow follows the "Failure" path.

---

### User Story 3 - Iterative/Repetitive Execution (Priority: P3)

As a data processing user, I want to repeat a sequence of actions until a specific visual element appears or disappears, so that I can automate repetitive batch tasks.

**Why this priority**: Automates high-volume tasks that would otherwise require manual intervention or complex scripting.

**Independent Test**: Create a loop that clicks a "Next Page" button repeatedly until the "End of Results" icon is detected.

**Acceptance Scenarios**:

1. **Given** a "Loop" node containing a sub-sequence of actions, **When** the loop condition (e.g., "Element X is visible") is met, **Then** the sub-sequence repeats.
2. **Given** a loop, **When** the termination condition is met, **Then** the workflow exits the loop and continues to the next node.

---

### Edge Cases

- **Circular Dependencies**: What happens if a user accidentally creates an infinite loop without a termination condition? The system SHOULD detect potential infinite loops or provide a "max iterations" safety limit.
- **Workflow Interruption**: How does the system handle a user manually stopping a workflow mid-execution? It MUST leave the desktop in its current state and log the last completed action.
- **Missing Assets**: If a workflow references a reference image that has been deleted from the scripts folder, how is it displayed in the graph?
- **Concurrent Execution**: Can multiple workflows run at the same time? (Initial assumption: No, only one active workflow to avoid input conflicts).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a visual canvas for creating and editing workflows as a directed graph.
- **FR-002**: Users MUST be able to browse and drag-and-drop actions from the **Commands Registry** (persisted VDA tasks) onto the canvas as nodes.
- **FR-003**: System MUST support drawing directional connections (edges) between nodes to define execution flow.
- **FR-004**: System MUST support specialized control flow nodes: **Sequence** (default), **Conditional** (with multiple output ports per outcome), and **Loop** (While/Repeat).
- **FR-009**: System MUST provide a **Visual Check** node that verifies the existence of a screenshot on the desktop without performing an interaction, providing "Found" and "Not Found" output ports.
- **FR-005**: Users MUST be able to configure node-specific parameters (e.g., timeout, confidence threshold) directly within the VWB.
- **FR-006**: System MUST continuously persist the current workflow state to the VDA's local storage to prevent data loss during the building process.
- **FR-010**: System MUST provide a "Manual Save" option to explicitly commit the current state.
- **FR-011**: System MUST provide an "Export" option to save the current workflow as a `.swflow` file to a user-specified location.
- **FR-012**: System MUST provide "Reset" and "New Workflow" options to clear the canvas or start a fresh project.
- **FR-013**: System MUST provide **Undo/Redo** functionality for all graph modifications (adding/removing nodes, moving nodes, creating/deleting connections).
- **FR-007**: System MUST provide a "Run" mode that highlights the currently executing node in the visual graph.
- **FR-017**: System MUST automatically persist the current workflow state to local storage when the "Run" action is triggered, ensuring the execution matches the latest visual state.
- **FR-014**: System MUST provide a "Stop" action to immediately terminate a running workflow.
- **FR-015**: System MUST track and display the total elapsed time of a running workflow (session-based, resets on workflow reload).
- **FR-016**: System MUST track and display the execution count for each node in the workflow for statistical purposes (session-based, resets on workflow reload).
- FR-008: System MUST support user-defined conditions based on internal variables, external file state, and custom script exit codes, allowing for complex non-visual logic within the workflow.

### Key Entities

- **Workflow**: The top-level entity representing the entire graph structure and its metadata.
- **Node**: An atomic unit of the workflow. Can be a **VDA Action Node** (referencing a reference image) or a **Control Node** (Logic).
- **Edge**: A directed link between two nodes, optionally carrying a condition (e.g., "on success").
- **Workflow State**: The runtime information of a running workflow (current node, variable values, execution log).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can create a 5-step sequential workflow in under 60 seconds using the visual builder.
- **SC-002**: The VWB successfully executes 100% of workflows containing at least one conditional branch and one loop without runtime errors.
- **SC-003**: Real-time visual feedback (active node highlighting) has a latency of less than 100ms relative to the actual execution state.
- **SC-004**: Workflows with up to 50 nodes can be rendered and panned/zoomed smoothly at 60 FPS.

## Assumptions

- **Integration with VDA Engine**: The VWB uses the same underlying execution engine defined in spec 001 for individual action execution.
- **Desktop Environment**: The VWB itself is a desktop application (likely Flutter, as seen in the `ui/` directory) and shares the same OS permissions as the VDA tool.
- **Static Assets**: Reference images for VDA actions are managed in the same central repository/folder.
- **Single Actor**: Only one user interacts with the VWB and the desktop at a time.
ed in spec 001 for individual action execution.
- **Desktop Environment**: The VWB itself is a desktop application (likely Flutter, as seen in the `ui/` directory) and shares the same OS permissions as the VDA tool.
- **Static Assets**: Reference images for VDA actions are managed in the same central repository/folder.
- **Single Actor**: Only one user interacts with the VWB and the desktop at a time.
