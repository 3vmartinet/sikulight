from PIL import ImageGrab
import platform
import os
from engine.src.core.logger import logger

def capture_screen(output_path: str = "screen.png") -> str:
    """
    Capture the primary monitor.
    """
    try:
        # ImageGrab works on macOS and Windows. 
        # On Linux, it might need 'scrot' or 'gnome-screenshot'.
        screenshot = ImageGrab.grab()
        screenshot.save(output_path)
        logger.info(f"Screen captured to {output_path}")
        return output_path
    except Exception as e:
        logger.error(f"Failed to capture screen: {e}")
        # Fallback for Linux if needed could be added here
        raise e
