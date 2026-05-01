import pyautogui
from engine.src.core.logger import logger

# Disable PyAutoGUI fail-safe for automation stability
pyautogui.FAILSAFE = False

def simulate_click(x: int, y: int, clicks: int = 1, button: str = 'left'):
    """
    Simulate mouse click at (x, y). Supported buttons: 'left', 'middle', 'right'.
    """
    if button not in ['left', 'middle', 'right']:
        raise ValueError(f"Invalid button: {button}. Must be 'left', 'middle', or 'right'.")

    try:
        pyautogui.click(x=x, y=y, clicks=clicks, button=button)
        logger.info(f"Simulated {clicks} {button} click(s) at ({x}, {y})")
    except Exception as e:
        logger.error(f"Failed to simulate click: {e}")
        raise e

def simulate_hover(x: int, y: int):
    """
    Simulate mouse hover at (x, y).
    """
    try:
        pyautogui.moveTo(x, y)
        logger.info(f"Simulated hover at ({x}, {y})")
    except Exception as e:
        logger.error(f"Failed to simulate hover: {e}")
        raise e

def simulate_scroll(amount: int):
    """
    Simulate mouse scroll.
    """
    try:
        pyautogui.scroll(amount)
        logger.info(f"Simulated scroll by {amount}")
    except Exception as e:
        logger.error(f"Failed to simulate scroll: {e}")
        raise e

def get_cursor_position():
    """
    Get current mouse cursor position.
    """
    return pyautogui.position()
