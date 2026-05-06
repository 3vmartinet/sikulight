# Data Model: Asset Workflow Nodes

## Entities

### AssetNode
Represents a node in the workflow that performs an action on a visual asset.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | UUID | Unique node identifier. |
| `asset_id` | UUID | Reference to the associated image asset. |
| `action` | String | Mouse action type (e.g., CLICK). |
| `ignore_error` | Boolean | Continue workflow on failure. |
| `x`, `y` | Float | Node position on canvas. |

### ExecutionResult
Response from the server during node execution.

| Field | Type | Description |
| :--- | :--- | :--- |
| `success` | Boolean | Whether the action was successful. |
| `error_message` | String? | Reason for failure (if any). |
| `retry_count` | Integer | Number of retries performed. |

## Relationships
- `AssetNode` (1) -> (1) `Asset` (via `asset_id`)
- `Workflow` (1) -> (*) `AssetNode`
