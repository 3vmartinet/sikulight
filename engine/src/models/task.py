from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field
from uuid import UUID, uuid4
from datetime import datetime

class InteractionMode(str, Enum):
    STANDARD = "STANDARD"
    DELEGATED = "DELEGATED"

class StandardAction(str, Enum):
    CLICK = "CLICK"
    DOUBLE_CLICK = "DOUBLE_CLICK"
    RIGHT_CLICK = "RIGHT_CLICK"
    HOVER = "HOVER"

class InteractionProfile(BaseModel):
    mode: InteractionMode
    standard_action: Optional[StandardAction] = None
    delegated_command_path: Optional[str] = None
    confidence_threshold: float = Field(default=0.8, ge=0.0, le=1.0)
    timeout_seconds: int = Field(default=30, gt=0)

class AutomationTask(BaseModel):
    id: UUID = Field(default_factory=uuid4)
    name: str
    reference_image_path: str
    profile: InteractionProfile
    created_at: datetime = Field(default_factory=datetime.now)
    last_run_at: Optional[datetime] = None
