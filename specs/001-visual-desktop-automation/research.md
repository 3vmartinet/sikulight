# Research: Visual Desktop Automation Tool

## Decisions & Rationale

### 1. Visual Recognition Algorithm
- **Decision**: OpenCV Template Matching (`cv2.matchTemplate`) with a configurable confidence threshold (default 0.8).
- **Rationale**: Efficient for UI element recognition. The confidence threshold (decided during clarification) allows handling anti-aliasing and minor rendering differences.
- **Alternatives Considered**: SIFT/SURF (too slow/complex), Deep Learning (excessive resource requirements).

### 2. Inter-Process Communication (IPC)
- **Decision**: Local REST API using FastAPI.
- **Rationale**: Robust, typed contracts, and easy integration with Flutter's `http` package.
- **Alternatives Considered**: WebSockets (unnecessary for current request-response flow).

### 3. Visual Feedback
- **Decision**: A transparent overlay window managed by the engine (using a lightweight toolkit like `tkinter` or `PyQt`) or a brief "flash" managed by the OS.
- **Rationale**: SC-004 requires visual confirmation within 100ms. A quick highlight at the detected coordinates satisfies this.
- **Implementation**: The engine will trigger a brief overlay highlight at the click coordinates immediately before/during the click.

### 4. Security & Restricted Execution
- **Decision**: Path validation for all delegated commands.
- **Rationale**: To mitigate risks (decided during clarification), the engine will verify that any command path starts within the designated "scripts" folder and contains no directory traversal sequences (`..`).

### 5. Platform-Specific Permissions
- **Decision**: Runtime checks for screen recording and accessibility.
- **Rationale**: Mandatory for macOS 10.15+. The engine will include a utility to check these permissions and return a specific error code if missing, which the UI will then display to the user.

## Unresolved Unknowns
- **Wayland Support**: Some Wayland compositors (like GNOME) restrict global screen capture. Researching "PipeWire" or "xdg-desktop-portal" as a fallback for `Pillow.ImageGrab`.
