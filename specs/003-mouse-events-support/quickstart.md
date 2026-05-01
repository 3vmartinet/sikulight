# Quickstart: Mouse Events Automation

## Overview
This feature adds support for scrolling and middle-click automation to the Sikulight engine.

## Usage

### 1. Sending Scroll Commands
To scroll up by 10 units:
```json
{
  "action": "SCROLL",
  "scroll_amount": 10
}
```

### 2. Sending Middle-Click
To perform a middle-click at specific coordinates:
```json
{
  "action": "MIDDLE_CLICK",
  "x": 400,
  "y": 300
}
```
