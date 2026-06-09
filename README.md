# sikulite
Yet another Sikuli, vibe-coded with GitHub Spec Kit.

## Portable Workflows (.macaque)
Sikulite now uses the `.macaque` file format for portable workflows. A `.macaque` file is a ZIP-based bundle that contains:
- The workflow configuration (JSON)
- All referenced image assets

This ensures that your workflows are portable by default and can be shared easily without worrying about missing image dependencies.

## Asset Management
The Asset Manager now features two tabs:
- **Local Assets**: Global assets registered on your local machine.
- **Workflow Assets**: Assets bundled within the currently active portable workflow.

When you open a `.macaque` file, its assets are extracted to an isolated temporary directory and cleared automatically when the tab is closed.
