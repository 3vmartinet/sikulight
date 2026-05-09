# Contract: Session Storage Schema

This contract defines the JSON structure used to persist the workspace session between application launches.

## Schema Version 1.0

```json
{
  "active_workflow_path": "string | null",
  "open_file_paths": [
    "string"
  ],
  "last_updated": "ISO-8601 string"
}
```

## Field Definitions

- **active_workflow_path**: The absolute path to the `.swflow` file that was active in the editor when the application last exited.
- **open_file_paths**: A list of absolute paths for all workflows that were open in tabs. This is used to populate the "Recently Open" menu.
- **last_updated**: Timestamp of the last successful session save.

## Storage Location
The file MUST be stored in the application's local documents directory as `session_history.json`.
- **macOS**: `~/Library/Application Support/com.sikulight.vda/session_history.json`
- **Windows**: `%AppData%\sikulight\session_history.json`
- **Linux**: `~/.config/sikulight/session_history.json`
