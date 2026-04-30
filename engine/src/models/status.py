from enum import Enum
from typing import Optional
from pydantic import BaseModel
from uuid import UUID

class EngineStatus(str, Enum):
    IDLE = "IDLE"
    BUSY = "BUSY"
    ERROR = "ERROR"

class EngineStatusModel(BaseModel):
    status: EngineStatus
    current_task_id: Optional[UUID] = None
    last_error: Optional[str] = None
    permissions_granted: bool = False
    screen_recording_granted: bool = False
    accessibility_granted: bool = False
