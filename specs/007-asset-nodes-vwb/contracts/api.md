# API Contract: Asset Workflow Nodes

## Execute Action Request
`POST /engine/execute`

```json
{
  "node_id": "uuid",
  "asset_id": "uuid",
  "action": "CLICK",
  "ignore_error": false
}
```

## Execute Action Response
`200 OK`

```json
{
  "success": true,
  "action_performed": "CLICK",
  "retry_count": 0
}
```

`400/500 Error`

```json
{
  "success": false,
  "error_type": "TIMEOUT",
  "message": "Image not found after 3 retries."
}
```
