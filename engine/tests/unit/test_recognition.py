import pytest
import cv2
import numpy as np
import os
from engine.src.core.recognition import find_template

def test_find_template():
    # Create a dummy screen and a template with a unique pattern
    screen = np.zeros((200, 200, 3), dtype=np.uint8)
    template = np.zeros((50, 50, 3), dtype=np.uint8)
    cv2.circle(template, (25, 25), 20, (255, 255, 255), -1)
    
    # Place template at (100, 100)
    screen[100:150, 100:150] = template
    
    # Save temporarily
    cv2.imwrite("test_screen.png", screen)
    cv2.imwrite("test_template.png", template)
    
    try:
        # Test finding it
        match = find_template("test_screen.png", "test_template.png", threshold=0.8)
        assert match is not None
        assert abs(match[0] - 125) <= 1
        assert abs(match[1] - 125) <= 1
    finally:
        if os.path.exists("test_screen.png"):
            os.remove("test_screen.png")
        if os.path.exists("test_template.png"):
            os.remove("test_template.png")
