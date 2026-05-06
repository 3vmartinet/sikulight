# Research: Asset Workflow Nodes

**Decision**: Implement AssetNode within the existing VWB architecture.

## Rationale
- Leveraging VWB's existing node architecture (from @specs/005) is the most efficient and consistent approach.
- AssetNode effectively becomes a special-case "Action" node that uses the existing visual-based recognition engine.
- Configuration for actions and error handling in the right pane aligns with the existing sidebar UI.

## Alternatives Considered
- **Standalone Node type vs generic Action Node**: AssetNode as a dedicated type simplifies node-specific UI (thumbnail display) compared to extending a generic Action Node.
- **External Workflow Engine**: Rejected in favor of the current Python engine to avoid unnecessary dependencies and complexity.

## Research Findings
- The Python server already supports `Action` execution.
- Existing `Recognition` engine provides the necessary image-matching hooks.
- Drag-and-drop mechanism already exists in `AssetRegistryPanel`.
