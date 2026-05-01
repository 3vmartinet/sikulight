from fastapi import APIRouter, HTTPException
from engine.src.models.task import AutomationTask
from engine.src.models.status import EngineStatusModel, EngineStatus

router = APIRouter()

# Global state for now
engine_status = EngineStatusModel(status=EngineStatus.IDLE)

@router.get("/status", response_model=EngineStatusModel)
async def get_status():
    return engine_status

from engine.src.core.capture import capture_screen
from engine.src.core.recognition import find_template
from engine.src.core.input import simulate_click, simulate_hover, simulate_scroll, get_cursor_position
from engine.src.core.overlay import show_highlight
from engine.src.core.executor import execute_delegated_command
from engine.src.models.task import InteractionMode, StandardAction
import pyautogui
import asyncio
import os

SCRIPTS_DIR = os.getenv("SIKULIGHT_SCRIPTS_DIR", os.path.join(os.getcwd(), "scripts"))

@router.post("/execute")
async def execute_task(task: AutomationTask):
    if engine_status.status == EngineStatus.BUSY:
        raise HTTPException(status_code=400, detail="Engine is busy")
    
    engine_status.status = EngineStatus.BUSY
    engine_status.current_task_id = task.id
    
    try:
        # Capture current mouse position to restore later
        original_x, original_y = pyautogui.position()

        # Run recognition
        screen_path = capture_screen()
        coords = find_template(
            screen_path, 
            task.reference_image_path, 
            threshold=task.profile.confidence_threshold
        )

        if coords:
            x, y = coords

            # Show highlight
            show_highlight(x, y)

            if task.profile.mode == InteractionMode.STANDARD:
                if task.profile.standard_action == StandardAction.CLICK:
                    simulate_click(x, y)
                elif task.profile.standard_action == StandardAction.DOUBLE_CLICK:
                    simulate_click(x, y, clicks=2)
                elif task.profile.standard_action == StandardAction.RIGHT_CLICK:
                    simulate_click(x, y, button='right')
                elif task.profile.standard_action == StandardAction.HOVER:
                    simulate_hover(x, y)
                elif task.profile.standard_action == StandardAction.MIDDLE_CLICK:
                    simulate_click(x, y, button='middle')
                elif task.profile.standard_action == StandardAction.SCROLL:
                    simulate_hover(task.profile.x or 0, task.profile.y or 0)
                    simulate_scroll(task.profile.scroll_magnitude or 10)
            elif task.profile.mode == InteractionMode.DELEGATED:
                if not task.profile.delegated_command_path:
                    raise ValueError("Delegated command path is required for DELEGATED mode")

                execute_delegated_command(task.profile.delegated_command_path, SCRIPTS_DIR)

            # Restore mouse position
            pyautogui.moveTo(original_x, original_y)

            engine_status.status = EngineStatus.IDLE
            engine_status.current_task_id = None
            return {"success": True, "message": "Task executed", "coordinates": [x, y]}
        else:
            engine_status.status = EngineStatus.IDLE
            engine_status.current_task_id = None
            # Restore even if not found? User didn't specify, but safe to restore.
            pyautogui.moveTo(original_x, original_y)
            return {"success": False, "message": "Element not found"}
            
    except Exception as e:
        engine_status.status = EngineStatus.ERROR
        engine_status.last_error = str(e)
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/abort")
async def abort_task():
    engine_status.status = EngineStatus.IDLE
    engine_status.current_task_id = None
    return {"success": True, "message": "Task aborted"}

@router.get("/cursor-position")
async def get_cursor_position_route():
    x, y = get_cursor_position()
    return {"x": x, "y": y}

@router.get("/cursor-position")
async def get_cursor_position_route():
    x, y = get_cursor_position()
    return {"x": x, "y": y}
