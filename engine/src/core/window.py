import platform
import subprocess
from engine.src.core.logger import logger

def get_active_window_id():
    """Returns the identifier of the currently active window."""
    system = platform.system()
    try:
        if system == "Darwin":
            script = 'tell application "System Events" to return name of 1st process whose frontmost is true'
            result = subprocess.check_output(["osascript", "-e", script], text=True).strip()
            return result
        elif system == "Linux":
            # Using xdotool to get active window ID
            return subprocess.check_output(["xdotool", "getactivewindow"], text=True).strip()
    except Exception as e:
        logger.warning(f"Could not get active window: {e}")
    return None

def focus_window(window_id):
    """Brings the specified window to the front."""
    if not window_id:
        return
    system = platform.system()
    try:
        if system == "Darwin":
            script = f'tell application "{window_id}" to activate'
            subprocess.run(["osascript", "-e", script])
        elif system == "Linux":
            subprocess.run(["xdotool", "windowactivate", window_id])
    except Exception as e:
        logger.warning(f"Could not focus window {window_id}: {e}")

def hide_vda_application():
    """Minimizes the current application (the VDA app)."""
    system = platform.system()
    try:
        if system == "Darwin":
            # Minimize the frontmost application
            script = 'tell application "System Events" to set the visible of every process whose frontmost is true to false'
            subprocess.run(["osascript", "-e", script])
        elif system == "Linux":
            # Minimize active window
            subprocess.run(["xdotool", "windowminimize", "$(xdotool getactivewindow)"])
    except Exception as e:
        logger.warning(f"Could not hide application: {e}")

def show_vda_application():
    """Restores the VDA application visibility."""
    system = platform.system()
    try:
        if system == "Darwin":
            # Set the 'ui' process as visible and activate it
            subprocess.run(["osascript", "-e", 'tell application "System Events" to set visible of process "ui" to true'])
            subprocess.run(["osascript", "-e", 'tell application "ui" to activate'])
        elif system == "Linux":
            # Restore active window
            subprocess.run(["xdotool", "windowactivate", "$(xdotool getactivewindow)"])
    except Exception as e:
        logger.warning(f"Could not show application: {e}")
