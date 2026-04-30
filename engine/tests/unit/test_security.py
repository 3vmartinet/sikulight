import pytest
import os
from engine.src.core.security import validate_script_path

def test_validate_script_path():
    # Setup a dummy scripts directory
    scripts_dir = os.path.abspath("scripts")
    if not os.path.exists(scripts_dir):
        os.makedirs(scripts_dir)
    
    try:
        # Valid path
        valid_path = os.path.join(scripts_dir, "test.sh")
        with open(valid_path, "w") as f:
            f.write("echo hello")
        assert validate_script_path(valid_path, scripts_dir) == valid_path
        
        # Invalid path (outside scripts dir)
        invalid_path = os.path.abspath("outside.sh")
        with open(invalid_path, "w") as f:
            f.write("echo evil")
        with pytest.raises(ValueError, match="Path must be inside scripts directory"):
            validate_script_path(invalid_path, scripts_dir)
            
        # Directory traversal
        traversal_path = os.path.join(scripts_dir, "../outside.sh")
        with pytest.raises(ValueError, match="Path must be inside scripts directory"):
            validate_script_path(traversal_path, scripts_dir)
            
    finally:
        if os.path.exists(scripts_dir):
            import shutil
            shutil.rmtree(scripts_dir)
        if os.path.exists("outside.sh"):
            os.remove("outside.sh")
