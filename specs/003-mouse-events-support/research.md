# Research: Mouse Wheel and Scroll Support

## Decision Log

### Research Task 1: PyAutoGUI Input Capabilities
- **Decision**: Use `pyautogui.scroll(clicks, x=None, y=None)` for scroll events and `pyautogui.click(button='middle')` for middle-click events.
- **Rationale**: Based on established documentation for PyAutoGUI, `scroll()` handles vertical scrolling (positive for up, negative for down). While PyAutoGUI does not have a dedicated `middleClick` function in all versions, `click(button='middle')` is the canonical, cross-platform method for middle-clicking.
- **Alternatives considered**: None, as this is the standard library interface.

### Research Task 2: Existing Input Protocol Analysis
- **Decision**: Extend `StandardAction` enum and update `simulate_click` to handle new button types.
- **Rationale**: The existing structure in `engine/src/core/input.py` and `engine/src/models/task.py` is easily extensible. Adding `SCROLL` and `MIDDLE_CLICK` to `StandardAction` integrates naturally.

### Research Task 3: Protocol Extension
- **Decision**: Add new action types to the API schema and handle them in `input.py`.
- **Rationale**: Ensures backward compatibility while enabling new functionality.
