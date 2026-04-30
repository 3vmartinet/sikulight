try:
    import tkinter as tk
    HAS_TKINTER = True
except (ImportError, ModuleNotFoundError):
    HAS_TKINTER = False

from threading import Timer
from engine.src.core.logger import logger

def show_highlight(x: int, y: int, size: int = 50, duration: float = 0.5):
    """
    Show a brief highlight at (x, y).
    """
    if not HAS_TKINTER:
        logger.warning("Tkinter not available, skipping highlight")
        return

    try:
        root = tk.Tk()
        root.overrideredirect(True)
        root.attributes("-topmost", True)
        # Transparent background if possible, or just a bright color
        root.attributes("-alpha", 0.5) 
        
        # Center the square on (x, y)
        root.geometry(f"{size}x{size}+{x - size // 2}+{y - size // 2}")
        
        canvas = tk.Canvas(root, width=size, height=size, bg="red", highlightthickness=0)
        canvas.pack()
        
        def close():
            root.destroy()
        
        root.after(int(duration * 1000), close)
        root.mainloop()
    except Exception as e:
        logger.error(f"Failed to show highlight: {e}")
        # Non-critical, so we don't raise
