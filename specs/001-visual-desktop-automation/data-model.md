# Data Model: Visual Desktop Automation Tool

## Entities

### 1. AutomationTask
- `id`: UUID
- `name`: String
- `reference_image_path`: String
- `profile`: InteractionProfile
- `created_at`: DateTime
- `last_run_at`: DateTime

### 2. InteractionProfile
- `mode`: Enum (STANDARD, DELEGATED)
- `standard_action`: Enum (CLICK, DOUBLE_CLICK, RIGHT_CLICK, HOVER)
- `delegated_command_path`: String (Must be inside "scripts" folder)
- `confidence_threshold`: Float (default 0.8)
- `timeout_seconds`: Integer (default 30)

### 3. EngineStatus
- `status`: Enum (IDLE, BUSY, ERROR)
- `current_task_id`: UUID
- `last_error`: String
- `permissions_granted`: Boolean
