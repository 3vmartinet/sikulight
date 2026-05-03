# Research: Visual Workflow Builder (VWB)

## Technology: vyuh_node_flow

The `vyuh_node_flow` package was evaluated for the visual canvas implementation.

### Key Findings
- **Controller-based Architecture**: Uses `NodeFlowController` to manage nodes and connections, which aligns well with the `Provider` pattern.
- **Type-Safe Data**: Supports generic type parameters for node data, allowing us to use a sealed class for different node types (Action, Logic, Start/End).
- **Serialization**: Built-in `toJson()` and `fromJson()` support for nodes and connections, making persistence straightforward.
- **Extensibility**: Custom `nodeBuilder` allows creating rich, interactive UI for each automation step.

### Decision
Use `vyuh_node_flow` for the VWB canvas. It provides the performance (60 FPS) and flexibility required for complex automation graphs.

---

## Workflow Engine (WE) Design

The Workflow Engine will be a dedicated service in the Flutter application responsible for graph traversal and state management.

### Execution State
The WE will maintain an internal state object during execution:
- `currentNodeId`: The ID of the node currently being executed.
- `variables`: A `Map<String, dynamic>` for storing user-defined variables and results from delegated scripts.
- `lastResult`: The success/failure result and output of the most recent action.
- **Metrics**:
  - `stopwatch`: A `Stopwatch` instance to track `elapsedTime`.
  - `executionCounter`: A `Map<String, int>` updated every time a node is entered.

### Execution Control
- **Run**: 
  1. **Persist**: Automatically saves the current graph state to local storage.
  2. **Reset**: Clears execution metrics and state.
  3. **Start**: Begins stopwatch and starts traversal from the `StartNode`.
- **Stop**: Immediately halts the traversal loop and stops the stopwatch.

### Node Types
| Node Type | Behavior |
|-----------|----------|
| **Start** | Initial entry point. |
| **VDA Action** | Triggers an automation step via `ApiClient.executeTask()`. |
| **Visual Check** | Verifies element existence without interaction; follows "Found" or "Not Found" ports. |
| **Branch (Multi-Output)** | Evaluates a condition and follows the port matching the specific outcome. |
| **Loop** | Repeats a sub-graph until a condition is met. |
| **Variable Set** | Updates the internal `variables` map. |
| **Wait** | Pauses execution for a specified duration. |

---

## Non-Visual Conditions (FR-008)

To support complex non-visual logic, the WE will implement specialized condition evaluators:

### 1. File State
- **Check**: `File(path).existsSync()`
- **Use Case**: Wait for a download to complete or a log file to appear.

### 2. Internal Variables
- **Check**: `variables[key] == value`
- **Use Case**: Counter-based loops or branching based on previous script results.

### 3. Script Exit Codes
- **Integration**: Update the Python engine's `/execute` response to include the exit code for delegated commands.
- **Check**: `lastResult.exitCode == expectedCode`

---

## Integration Patterns

### Undo/Redo Management
To fulfill **FR-013**, the VWB will use the `value_notifier_tools` package (or similar `HistoryValueNotifier` patterns) to track the state of the `NodeFlowController`. Every significant graph change will push a new state to the history stack, allowing users to revert mistakes or restore deleted nodes.

### Commands Registry Integration
The VWB will integrate with the existing `TaskProvider` to display a searchable list of saved automation commands. These commands are "instantiated" as `VdaActionNode` instances when dropped onto the canvas.

### API Communication
The WE will interact with the Python engine through the `ApiClient`. Since the engine is currently synchronous (Wait for response), the WE will naturally wait for each node to complete before moving to the next.

### Continuous Persistence
The VWB will implement an auto-save mechanism that triggers on every graph modification (node add/move, connection created). This state is stored in a `draft_workflow.json` in the app's local storage directory.

### Manual Export
Users can explicitly export workflows as `.swflow` files. These files are self-contained JSON documents containing the full graph and metadata, allowing for portability between VDA instances.

## Alternatives Considered

- **flutter_flow_chart**: Rejected due to lack of type-safe node data and more limited styling options.
- **Custom Canvas with CustomPainter**: Rejected as it would require significant effort to implement node dragging, zooming, and connection logic already provided by `vyuh_node_flow`.
