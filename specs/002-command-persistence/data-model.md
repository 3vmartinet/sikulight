# Data Model: Command Persistence

## Entities

### `PersistedCommand`
Represents an automation command saved by the user.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | String | Unique identifier (UUID or timestamp). |
| `command` | String | The actual command string to execute. |
| `createdAt` | DateTime | When the command was created/last executed. |
| `label` | String? | Optional label for the command. |

## Relationships
- None (independent entity).

## Validation Rules
- `command` MUST NOT be empty.
- `id` MUST be unique.
