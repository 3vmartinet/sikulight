# API Contracts: Mouse Events

## Endpoint: /automation/mouse
This endpoint receives standard mouse automation commands.

### Payload Schema
```json
{
  "action": "SCROLL" | "MIDDLE_CLICK" | "CLICK" | "DOUBLE_CLICK" | "RIGHT_CLICK" | "HOVER",
  "x": 100,
  "y": 200,
  "scroll_amount": 10,
  "button": "left" | "middle" | "right"
}
```
