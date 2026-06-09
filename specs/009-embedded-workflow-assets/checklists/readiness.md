# Requirements Quality Checklist: Embedded Workflow Assets (Release Readiness Gate)

**Purpose**: Validate specification completeness and quality before proceeding to task execution
**Created**: 2026-06-08
**Feature**: [specs/009-embedded-workflow-assets/spec.md]

## Requirement Completeness

- [ ] CHK001 - Are the exact supported image formats (e.g., PNG, JPG) explicitly listed in the export requirements? [Completeness, Spec §FR-001]
- [ ] CHK002 - Does the specification define the behavior when a `.macaque` file is corrupted or invalid upon import? [Gap, Exception Flow]
- [ ] CHK003 - Is the behavior specified for workflows containing zero assets during save? [Completeness, Edge Case]
- [ ] CHK004 - Are the specific metadata fields for `IsolatedAssetStore` (e.g., workflowId mapping) documented? [Completeness, Data Model]
- [ ] CHK005 - Does the specification define requirements for handling asset name collisions within the *same* `.macaque` archive? [Gap, Consistency]

## Requirement Clarity

- [ ] CHK006 - Is "referenced image assets" quantified—does it include all nodes or only active/executable ones? [Clarity, Spec §FR-001]
- [ ] CHK007 - Is the "dedicated temporary folder" location quantified with a specific system path pattern? [Clarity, Data Model]
- [ ] CHK008 - Are the "tabs" in the Asset Manager defined with specific labels and interaction rules (e.g., drag-and-drop between tabs)? [Clarity, Spec §FR-006]
- [ ] CHK009 - Is "automatically clean up" quantified—does it happen synchronously or asynchronously after tab closure? [Ambiguity, Spec §FR-007]
- [ ] CHK010 - Is the term "single unit (container format)" explicitly mapped to the ZIP/macaque specification? [Consistency, Spec §FR-002]

## Requirement Consistency

- [ ] CHK011 - Do the save requirements in §FR-001 align with the `.macaque` contract defined in `contracts/macaque_format.md`? [Consistency]
- [ ] CHK012 - Does the mapping logic in §FR-004 align with the `IsolatedAssetStore` path structure defined in the Data Model? [Consistency]
- [ ] CHK013 - Are the tab display requirements in §FR-006 consistent with existing Asset Manager UI patterns? [Consistency]

## Acceptance Criteria Quality

- [ ] CHK014 - Is SC-002 (Loading < 2s) testable without specifying implemention details? [Measurability, Spec §SC-002]
- [ ] CHK015 - Is "0% chance of local asset corruption" (SC-003) objectively verifiable through isolated tests? [Measurability, Spec §SC-003]
- [ ] CHK016 - Can "100% of temporary asset folders are cleaned up" (SC-004) be verified in a CI environment? [Measurability, Spec §SC-004]

## Scenario & Edge Case Coverage

- [ ] CHK017 - Are requirements defined for "Abnormal Shutdown" (e.g., crash recovery for temp folders)? [Coverage, Spec §Edge Cases]
- [ ] CHK018 - Does the specification define behavior when the disk is full during extraction? [Coverage, Gap]
- [ ] CHK019 - Are requirements specified for workflows with very large assets (e.g., memory limits during bundling)? [Coverage, Spec §Edge Cases]
- [ ] CHK020 - Is the behavior defined when an imported workflow references an asset that was *intended* to be in the archive but is missing? [Coverage, Exception Flow]

## Dependencies & Assumptions

- [ ] CHK021 - Is the dependency on the `archive` package and its limitations (e.g., zip bomb protection) documented? [Dependency, Plan]
- [ ] CHK022 - Is the assumption that "Imported assets are NOT automatically merged" validated against user expectations for long-term storage? [Assumption, Spec §Assumptions]
- [ ] CHK023 - Are dependencies on system temporary directory permissions documented for different OSs? [Dependency, Gap]
