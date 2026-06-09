# Contract: .macaque Workflow Package

## Overview
The `.macaque` file is a ZIP-compressed archive used for sharing workflows between Macaque instances.

## Structure

```text
/
├── workflow.json      # Root workflow JSON file
└── assets/            # Directory for all image dependencies
    ├── {uuid1}.png
    ├── {uuid2}.jpg
    └── ...
```

## Specification

### 1. workflow.json
- MUST be a valid JSON representation of the `Workflow` model.
- MUST contain a `version` field for future-proofing.
- All `assetId` references in nodes MUST correspond to a file in the `assets/` directory (mapped by ID or relative path).

### 2. assets/
- MUST contain only supported image formats (PNG, JPG, BMP).
- Filenames SHOULD be unique within the package (e.g., using Asset UUIDs).

### 3. Compression
- MUST use standard ZIP compression.
- The extension MUST be `.macaque`.
