import sys
import platform

def check_screen_recording_permission() -> bool:
    """
    Check if screen recording permission is granted.
    On macOS, this typically requires checking TCC database.
    This is a placeholder for now.
    """
    if platform.system() == "Darwin":
        # Placeholder for macOS check
        return True 
    elif platform.system() == "Linux":
        # Linux depends on X11 vs Wayland
        return True
    return True

def check_accessibility_permission() -> bool:
    """
    Check if accessibility permission is granted (needed for input simulation on macOS).
    """
    if platform.system() == "Darwin":
        # Placeholder for macOS check
        return True
    return True

def get_permissions_status() -> dict:
    return {
        "screen_recording": check_screen_recording_permission(),
        "accessibility": check_accessibility_permission()
    }
