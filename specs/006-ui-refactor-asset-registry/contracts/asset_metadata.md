# Contract: Asset Metadata Storage

**File**: `.assets.json`  
**Location**: Project Assets Directory  
**Format**: JSON

## Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "version": { "type": "integer" },
    "assets": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": { "type": "string", "format": "uuid" },
          "filename": { "type": "string" },
          "status": { "enum": ["available", "missing"] },
          "lastModified": { "type": "string", "format": "date-time" }
        },
        "required": ["id", "filename", "status"]
      }
    }
  },
  "required": ["version", "assets"]
}
```

## Usage
- This file is managed by the `AssetStorageService`.
- It MUST be updated whenever an asset is added, renamed, or deleted via the UI.
- On startup, the service reconciles this file with the actual contents of the directory.
