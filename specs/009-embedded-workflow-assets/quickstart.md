# Quickstart: Embedded Workflow Assets

## Saving a Workflow
1. Work on your workflow normally in Macaque.
2. Click **Save** in the toolbar.
3. The workflow is saved as a `.macaque` file. All used images are automatically bundled inside.

## Opening a Workflow
1. Click **Open** and select a `.macaque` file.
2. The workflow opens in a new tab.
3. The bundled assets are extracted to a temporary safe location.
4. View these assets in the **Asset Registry** panel under the **Workflow Assets** tab.

## Sharing
- Simply copy or send the `.macaque` file. No need to zip "Assets" folders manually.

## Development Notes
- `WorkflowPersistence` handles `.macaque` ZIP archives.
- Use `ArchiveService` for all ZIP-related logic (creation, extraction, cleanup).
- The "Workflow Assets" tab in the UI dynamically reflects the contents of the currently active tab's `IsolatedAssetStore`.
