# Contract: .swflow Workflow File Format

The `.swflow` file is a JSON document stored on the local filesystem. It uses the `vyuh_node_flow` serialization format for the graph structure, extended with Sikulight-specific metadata.

## Schema

```json
{
  "version": "1.0",
  "name": "User Workflow Name",
  "variables": {
    "counter": 0
  },
  "graph": {
    "nodes": [
      {
        "id": "node-start",
        "type": "start",
        "position": {"x": 100, "y": 100},
        "data": {}
      },
      {
        "id": "node-action-1",
        "type": "vda_action",
        "position": {"x": 300, "y": 100},
        "data": {
          "command_name": "Click Submit",
          "timeout_override": 30
        }
      }
    ],
    "connections": [
      {
        "sourceNodeId": "node-start",
        "sourcePortId": "out",
        "targetNodeId": "node-action-1",
        "targetPortId": "in"
      }
    ]
  }
}
```

## Node Data Types

### `vda_action`
- `command_name`: (String) Name of the persisted TaskCommand.
- `timeout_override`: (Integer, optional) Seconds to wait.

### `branch`
- `condition_type`: (String) "visual", "variable", "file", "exit_code".
- `outcomes`: (List<String>) Port labels (e.g., ["Found", "Not Found"]).

### `visual_check`
- `reference_image_path`: (String)
- `confidence_threshold`: (Double)
- `timeout_seconds`: (Integer)

### `loop`
- `max_iterations`: (Integer) Safety cap.
- `condition_node_id`: (String) Node that determines loop continuation.

### `variable_set`
- `variable_name`: (String)
- `operation`: (String) "set", "add".
- `value`: (Any)
