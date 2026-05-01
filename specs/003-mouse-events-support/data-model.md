# Data Model: Mouse Events

## Interaction Definitions

### StandardAction (Extended)
- **CLICK**: Standard left click.
- **DOUBLE_CLICK**: Standard left double click.
- **RIGHT_CLICK**: Standard right click.
- **HOVER**: Move mouse to coordinates without clicking.
- **MIDDLE_CLICK**: New - Standard mouse wheel click.
- **SCROLL**: New - Mouse wheel movement (vertical/horizontal).

### MouseEvent (New)
- **id**: UUID
- **action**: StandardAction
- **x, y**: Coordinates (optional, required for CLICK/HOVER)
- **scroll_amount**: int (required for SCROLL, positive=up, negative=down)
- **button**: str (optional, default 'left')
