# Quickstart: UI Refactor and Asset Registry

## Setup
1. Ensure you have the Flutter SDK (^3.11.5) installed.
2. Add dependencies to `ui/pubspec.yaml`:
   ```yaml
   dependencies:
     desktop_drop: ^0.5.0
     watcher: ^1.1.0
   ```
3. Run `flutter pub get`.

## Usage
### 1. Launch VWB
The application now starts directly on the **Visual Workflow Builder** screen.

### 2. Manage Registries
- Use the collapse/expand toggles on the left sidebar to toggle between **Command Registry** and **Asset Registry**.
- Drag the divider or use the toggle button to maximize your workspace.

### 3. Import Assets
- Drag image files (PNG/JPG) from your computer and drop them into the **Asset Registry** panel.
- Alternatively, use the "+" button to open a file picker.

### 4. Manage Assets
- **Rename**: Right-click an asset or click the edit icon to change its filename.
- **Delete**: Click the trash icon. Confirm deletion to remove the file from disk.
- **Layouts**: Switch between **Grid** and **List** views using the icons at the top of the Asset Registry.

## Developer Notes
- Assets are stored in `~/Documents/Sikulight/Assets` (platform dependent).
- Internal references in `.swflow` files use the Asset UUID, ensuring renames don't break workflows.
