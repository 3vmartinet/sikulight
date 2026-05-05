# Data Model: UI Refactor and Asset Registry

## Entities

### Asset
Represents an image resource used in automation workflows.

| Field | Type | Description |
|-------|------|-------------|
| `id` | `String` (UUID) | Unique internal identifier. Persistent across renames. |
| `filename` | `String` | Current name of the file on disk (e.g., "login_btn.png"). |
| `path` | `String` | Absolute path to the file. |
| `status` | `AssetStatus` | Enum: `available`, `missing`. |
| `lastModified` | `DateTime` | Timestamp for sorting and cache invalidation. |

### AssetMetadata
The structure of the `.assets.json` file.

| Field | Type | Description |
|-------|------|-------------|
| `version` | `int` | Schema version. |
| `assets` | `List<Asset>` | List of all registered assets. |

## Enums

### AssetStatus
- `available`: File exists on disk.
- `missing`: Entry exists in metadata but file is not found at the recorded path/filename.

## Relationships
- **Workflow Node -> Asset**: Nodes (like `ExistNode` or `ClickNode`) will now store an `assetId` instead of a raw `referenceImagePath`. 
- **AssetRegistry -> Asset**: The registry manages a collection of Assets.

## Validation Rules
- **Unique Filename**: No two "available" assets can have the same filename in the same directory.
- **Valid Formats**: Only `.png`, `.jpg`, `.jpeg` are accepted.
- **ID Persistence**: Once assigned, an ID must never change, even if the filename is edited.
