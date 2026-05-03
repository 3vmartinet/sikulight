# Quickstart: Visual Workflow Builder

This guide helps you set up and run a visual workflow in Sikulight.

## 1. Prerequisites
- Ensure the Python engine is running: `cd engine && python3 -m engine.src.api.app`
- Launch the Flutter app: `cd ui && flutter run`

## 2. Creating a Workflow
1. Navigate to the **Workflow Builder** tab in the app.
2. Click **New Workflow** and give it a name (e.g., "Daily Login").
3. **Drag-and-drop** actions from the **Commands Registry** side panel onto the canvas.
   - *Note: You must have existing VDA actions saved first.*
4. **Link nodes** by dragging from an output port to an input port.
5. Add a **Start Node** at the beginning.

## 3. Adding Logic
1. Drag a **Condition Node** onto the canvas.
2. Connect it to an Action node.
3. Configure the condition (e.g., "If Action 1 succeeds").
4. Connect the "Success" and "Failure" ports to different nodes.

## 4. Running the Workflow
1. Click the **Play** button in the top toolbar to start execution.
2. Click the **Stop** button (appears when running) to immediately terminate the workflow.
3. Watch the execution in real-time:
   - The active node will be highlighted in green.
   - An **Elapsed Time** timer shows the duration of the current run.
   - **Execution Counters** on each node show how many times they have been triggered.
4. Check the **Execution Log** panel for details on each step.

## 5. Workflow Management
- **Continuous Saving**: Your progress is automatically saved to the VDA local storage as you build.
- **Manual Save**: Click the **Save** icon to ensure your latest changes are committed.
- **Undo/Redo**: Use the **Undo** (Ctrl+Z) and **Redo** (Ctrl+Y) buttons to revert or restore graph changes.
- **Export**: Use the **Export** button to save the workflow as a `.swflow` file for sharing.
- **Reset/New**: Click **New Workflow** to start from scratch or **Reset** to clear the current canvas.
