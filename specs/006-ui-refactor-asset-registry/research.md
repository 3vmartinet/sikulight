# Research: UI Refactor and Asset Registry

## Decisions & Findings

### D-001: Drag and Drop Implementation
**Decision**: Use the `desktop_drop` package.
**Rationale**: The requirements specifically ask for dropping images *into* the Asset Registry from the operating system. `desktop_drop` is lightweight, doesn't require Rust (unlike `super_drag_and_drop`), and is ideal for this "drop to import" use case. Pair with `file_picker` for manual selection fallback.
**Alternatives considered**: `super_drag_and_drop` (overkill for simple imports), native platform channels (too complex for MVP).

### D-002: File System Monitoring
**Decision**: Use the `watcher` package (specifically `DirectoryWatcher`).
**Rationale**: Maintained by the Dart team and handles recursive watching and platform-specific quirks (like `inotify` limits or macOS `FSEvents`) better than `dart:io`. It allows the Asset Registry to stay in sync with manual file system changes (renames/deletes) performed outside the app.
**Alternatives considered**: `dart:io` `FileSystemEntity.watch()` (less reliable on Linux/macOS for recursive tasks).

### D-003: Asset Identification & Metadata
**Decision**: Use a hidden `.assets.json` sidecar file in the assets directory.
**Rationale**: To satisfy the requirement that "renaming shall not interfere with any other functionality," we need a stable internal ID. Since we are using the local file system (where filenames are the primary key), a sidecar file will map `ID -> current_filename`. If a file is renamed externally, the watcher will detect it, and we can attempt to re-sync or mark as missing.
**Alternatives considered**: Embedding IDs in filenames (ugly, user-facing), SQLite (overkill for simple local file tracking).

### D-004: UI Refactor for Startup
**Decision**: Modify `main.dart` to set `WorkflowScreen` (VWB) as the `home` widget.
**Rationale**: Simplifies the entry point and aligns with the requirement to start in VWB view. Existing `TaskMonitorView` will be moved to a secondary view or accessible via navigation if still needed.

### D-005: Side Panel Architecture
**Decision**: Create a `SidePanelCoordinator` or update `WorkflowViewModel` to manage the state (expanded/collapsed) of the two registries.
**Rationale**: The Command Registry and Asset Registry need to share vertical space. Using a `Column` with `Expanded` widgets wrapped in "expandable/collapsible" containers (like `ExpansionTile` or custom animated containers) will provide the requested layout.

## Unknowns Resolved
- **Duplicate Handling**: Will use a standard "Overwrite/Rename/Skip" dialog as clarified by the user.
- **External Deletion**: Resolved via `watcher` + "Missing" status icon in UI.
- **Internal Referencing**: VWB nodes will store the Asset ID, not the path. `AssetStorageService` will resolve `ID -> Path` at runtime.
