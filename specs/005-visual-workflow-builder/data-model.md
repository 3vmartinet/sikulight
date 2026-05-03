# Data Model: Visual Workflow Builder

## Workflow Entity

Represents the top-level automation graph.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` | Unique identifier for the workflow. |
| `name` | `String` | Display name. |
| `nodes` | `List<NodeData>` | Collection of nodes in the graph. |
| `connections` | `List<ConnectionData>` | Links between node ports. |
| `variables` | `Map<String, dynamic>` | Initial variable definitions. |

---

## Node Data Model (Sealed Class)

Each node in the graph represents a specific operation.

### Common Fields
- `id`: `String`
- `position`: `Offset` (x, y)
- `type`: `String` (Discriminator)

### 1. VdaActionNode
- `command`: `TaskCommand` (Reference to a saved action)
- `timeoutOverride`: `int?` (Optional override for the task timeout)

### 2. BranchNode (Multi-Outcome)
- `conditionType`: `Enum` (VisualSuccess, VariableMatch, FileExists, ScriptExitCode)
- `outcomes`: `List<String>` (Labels for output ports, e.g., ["Success", "Timeout", "Error"])

### 7. VisualCheckNode
- `referenceImagePath`: `String` (Path to the screenshot)
- `confidenceThreshold`: `double`
- `timeoutSeconds`: `int`

### 3. LoopNode
- `loopType`: `Enum` (While, For)
- `condition`: `ConditionData`
- `maxIterations`: `int` (Safety limit, default 100)

### 4. VariableNode
- `variableName`: `String`
- `operation`: `Enum` (Set, Increment, Decrement)
- `value`: `dynamic`

### 5. StartNode
- *Entry point marker (no extra data)*

### 6. EndNode
- *Termination marker (no extra data)*

---

## Execution State (Runtime Only)

Managed by the `WorkflowEngine` during a "Run".

| Field | Type | Description |
|-------|------|-------------|
| `activeNodeId` | `String` | The ID of the node currently executing. |
| `variableValues` | `Map<String, dynamic>` | Current state of variables. |
| `executionLog` | `List<LogEntry>` | History of executed nodes and results. |
| `status` | `Enum` | Idle, Running, Paused, Completed, Failed. |
| `startTime` | `DateTime?` | When the current execution began. |
| `elapsedTime` | `Duration` | Total time spent running the workflow. |
| `nodeExecutionCounts` | `Map<String, int>` | Tracks how many times each node ID has been triggered. |

---

## Relationships

- **Workflow** contains many **Nodes**.
- **Nodes** are linked by **Connections**.
- **Connections** map an **Output Port** of a source node to an **Input Port** of a target node.
- **VdaActionNode** references a **TaskCommand** defined in the **Commands Registry** (persisted task storage).
