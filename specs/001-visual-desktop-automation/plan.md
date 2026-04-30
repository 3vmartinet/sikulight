# Implementation Plan: Visual Desktop Automation Tool

**Branch**: `001-visual-desktop-automation` | **Date**: 2026-04-30 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-visual-desktop-automation/spec.md`

## Summary

This project implements a cross-platform desktop automation tool using a hybrid architecture:
1. **Automation Engine (Python)**: Leverages OpenCV for high-performance visual element recognition and PyAutoGUI for reliable cross-platform input simulation (clicks, typing).
2. **User Interface (Flutter)**: Provides a modern, responsive desktop interface for managing automation tasks, reference images, and execution monitoring.

The engine and UI will communicate via a local REST API (FastAPI) to ensure decoupled development and runtime efficiency. Key security features include restricting delegated commands to a user-configurable "scripts" directory.

## Technical Context

**Language/Version**: Python 3.10+, Dart 3.x (Flutter 3.x)
**Primary Dependencies**: 
- **Engine**: `opencv-python`, `pyautogui`, `pillow`, `fastapi`, `uvicorn`
- **UI**: `flutter`, `provider`, `http`
**Storage**: Local file system (JSON for configs, PNG for reference images)
**Testing**: `pytest` (Engine), `flutter test` (UI)
**Target Platform**: macOS (12+), Linux (X11/Wayland)
**Project Type**: Desktop Application
**Performance Goals**: <500ms detection latency, <100ms visual feedback latency.
**Constraints**: Screen recording and accessibility permissions; mandatory "scripts" directory restriction for delegated commands.
**Scale/Scope**: Support for dozens of concurrent automation tasks; single-user local tool.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Principle I: Library-First** - Engine logic will be built as a standalone Python library before being wrapped in an API.
- [x] **Principle II: CLI Interface** - The Python engine will support CLI invocation for debugging.
- [x] **Principle III: Test-First** - Core recognition logic will be validated with a suite of reference images.
- [x] **Principle IV: Integration Testing** - REST API contract tests will be implemented to ensure UI-Engine compatibility.

## Project Structure

```text
engine/                  # Python Automation Engine
├── src/
│   ├── core/            # Recognition & Input logic
│   ├── api/             # IPC Interface (FastAPI)
│   └── models/          # Task & Config definitions
├── tests/
│   ├── unit/
│   └── integration/
└── requirements.txt

ui/                      # Flutter User Interface
├── lib/
│   ├── features/        # Task management, Monitoring
│   ├── core/            # API clients, Constants
│   └── main.dart
├── assets/              # Icons, templates
└── pubspec.yaml

specs/001-visual-desktop-automation/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
└── contracts/
```

**Structure Decision**: Multi-project structure to separate Python automation logic from the Flutter user experience.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |
