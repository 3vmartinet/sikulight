# Contract: API Updates for Workflow Support

To support conditional branching based on script results, the `/execute` response from the Python engine must be enhanced.

## Endpoint: POST `/execute`

### Enhanced Response Body (Success)

```json
{
  "success": true,
  "message": "Task executed",
  "coordinates": [100, 200],
  "execution_details": {
    "mode": "delegated",
    "exit_code": 0,
    "stdout": "Backup successful\n",
    "stderr": ""
  }
}
```

### Enhanced Response Body (Failure/Error)

```json
{
  "success": false,
  "message": "Element not found",
  "execution_details": null
}
```

*Note: For `standard` mode, `exit_code` will always be 0 if the click/hover was successful.*
