# API Contract: UI <-> Engine

## REST Endpoints

### 1. Execute Task
- **POST** `/execute`
- **Request**:
  ```json
  {
    "task_id": "uuid",
    "image_path": "string",
    "action": "string",
    "threshold": 0.8,
    "timeout": 30
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "success": true,
    "coordinates": [x, y],
    "message": "Interaction performed"
  }
  ```

### 2. Status
- **GET** `/status`
- **Response (200 OK)**:
  ```json
  {
    "engine_status": "IDLE",
    "permissions": {
      "screen_recording": true,
      "accessibility": true
    }
  }
  ```

### 3. Config
- **GET/POST** `/config`
- Manages the "scripts" directory path.
