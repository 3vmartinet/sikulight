import subprocess
import os
from engine.src.core.security import validate_script_path
from engine.src.core.logger import logger

def execute_delegated_command(script_path: str, scripts_dir: str):
    """
    Validate and execute a delegated command.
    """
    try:
        valid_path = validate_script_path(script_path, scripts_dir)
        
        # Determine how to run based on extension
        if valid_path.endswith(".py"):
            cmd = ["python3", valid_path]
        elif valid_path.endswith(".sh"):
            cmd = ["bash", valid_path]
        else:
            # Assume it's an executable
            cmd = [valid_path]
            
        logger.info(f"Executing delegated command: {cmd}")
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        logger.info(f"Command finished with output: {result.stdout}")
        return result.stdout
        
    except subprocess.CalledProcessError as e:
        logger.error(f"Command failed with error: {e.stderr}")
        raise e
    except Exception as e:
        logger.error(f"Error executing delegated command: {e}")
        raise e
