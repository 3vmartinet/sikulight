import pytest
import cv2
import numpy as np
import os
from httpx import AsyncClient, ASGITransport
from engine.src.api.app import app
from uuid import uuid4

from unittest.mock import patch

@pytest.mark.asyncio
async def test_execute_endpoint():
    # Create a dummy template image for the test
    template = np.ones((50, 50, 3), dtype=np.uint8)
    cv2.circle(template, (25, 25), 20, (255, 255, 255), -1)
    cv2.imwrite("test_template.png", template)
    
    # Create a dummy screen image
    screen = np.zeros((200, 200, 3), dtype=np.uint8)
    screen[100:150, 100:150] = template
    cv2.imwrite("test_screen.png", screen)
    
    try:
        with patch("engine.src.api.routes.capture_screen", return_value="test_screen.png"), \
             patch("engine.src.api.routes.simulate_click"), \
             patch("engine.src.api.routes.show_highlight"):
            async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
                payload = {
                    "name": "Test Task",
                    "reference_image_path": "test_template.png",
                    "profile": {
                        "mode": "STANDARD",
                        "standard_action": "CLICK",
                        "confidence_threshold": 0.8,
                        "timeout_seconds": 30
                    }
                }
                response = await ac.post("/execute", json=payload)
                assert response.status_code == 200
                data = response.json()
                assert data["success"] is True
                assert data["coordinates"] == [125, 125]

    finally:
        if os.path.exists("test_template.png"):
            os.remove("test_template.png")
        if os.path.exists("test_screen.png"):
            os.remove("test_screen.png")

@pytest.mark.asyncio
async def test_execute_delegated_mode():
    # Setup dummy script
    scripts_dir = os.path.join(os.getcwd(), "scripts")
    os.makedirs(scripts_dir, exist_ok=True)
    script_path = os.path.join(scripts_dir, "test_delegated.sh")
    with open(script_path, "w") as f:
        f.write("#!/bin/bash\necho 'Delegated success'")
    os.chmod(script_path, 0o755)

    # Create dummy images
    template = np.ones((50, 50, 3), dtype=np.uint8)
    cv2.imwrite("test_template_del.png", template)
    screen = np.zeros((200, 200, 3), dtype=np.uint8)
    screen[100:150, 100:150] = template
    cv2.imwrite("test_screen_del.png", screen)

    try:
        with patch("engine.src.api.routes.capture_screen", return_value="test_screen_del.png"), \
             patch("engine.src.api.routes.show_highlight"):
            async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
                payload = {
                    "name": "Delegated Task",
                    "reference_image_path": "test_template_del.png",
                    "profile": {
                        "mode": "DELEGATED",
                        "delegated_command_path": script_path,
                        "confidence_threshold": 0.8,
                        "timeout_seconds": 30
                    }
                }
                response = await ac.post("/execute", json=payload)
                assert response.status_code == 200
                data = response.json()
                assert data["success"] is True
    finally:
        import shutil
        if os.path.exists("test_template_del.png"):
            os.remove("test_template_del.png")
        if os.path.exists("test_screen_del.png"):
            os.remove("test_screen_del.png")
        if os.path.exists(scripts_dir):
            shutil.rmtree(scripts_dir)
