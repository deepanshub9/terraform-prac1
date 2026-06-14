# How to Add a New Workflow

Each `.tf` file in this folder = one independent workflow on the same Logic App instance.

## Rules

1. Every workflow file must reference `azurerm_logic_app_workflow.this.id` — that's the shared Logic App instance defined in `../main.tf`
2. Every workflow needs exactly ONE trigger resource
3. Actions must have `depends_on` pointing to their trigger
4. Use `var.workflow_runs_container_name` for the blob container path

## Available trigger types

| Terraform resource | When it fires |
|---|---|
| `azurerm_logic_app_trigger_http_request` | Someone calls the HTTP endpoint |
| `azurerm_logic_app_trigger_recurrence` | On a schedule (hourly, daily etc) |
| `azurerm_logic_app_trigger_custom` | Any other trigger (Service Bus, Event Grid etc) |

## Template — copy this to create a new workflow

```hcl
# ── Workflow: <your workflow name> ────────────────────────────────────────────
resource "azurerm_logic_app_trigger_http_request" "<name>_trigger" {
  name         = "<unique-trigger-name>"
  logic_app_id = azurerm_logic_app_workflow.this.id

  schema = jsonencode({
    type = "object"
    properties = {
      yourField = { type = "string" }
    }
  })
}

resource "azurerm_logic_app_action_custom" "<name>_action" {
  name         = "<unique-action-name>"
  logic_app_id = azurerm_logic_app_workflow.this.id

  body = jsonencode({
    type     = "ApiConnection"
    inputs   = { ... }
    runAfter = {}
  })

  depends_on = [azurerm_logic_app_trigger_http_request.<name>_trigger]
}
```

## Current workflows

| File | Trigger | What it does |
|---|---|---|
| `http_to_blob.tf` | HTTP POST | Saves JSON payload as blob in `workflow-runs/` |
| `scheduled.tf` | Every 1 hour | Writes heartbeat blob to `workflow-runs/` |
```
