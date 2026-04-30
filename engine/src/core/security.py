import os
from engine.src.core.logger import logger

def validate_script_path(script_path: str, allowed_dir: str) -> str:
    """
    Validate that script_path is inside allowed_dir and does not contain directory traversal.
    Returns absolute path if valid, else raises ValueError.
    """
    abs_allowed_dir = os.path.abspath(allowed_dir)
    abs_script_path = os.path.abspath(script_path)
    
    # Check if script_path is within allowed_dir
    if not abs_script_path.startswith(abs_allowed_dir):
        logger.error(f"Security Violation: Path {script_path} is outside {allowed_dir}")
        raise ValueError("Path must be inside scripts directory")
        
    if not os.path.exists(abs_script_path):
        logger.error(f"File not found: {abs_script_path}")
        raise ValueError("Script file not found")
        
    return abs_script_path
