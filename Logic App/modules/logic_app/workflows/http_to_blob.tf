# ── Workflow 1: HTTP → Blob ────────────────────────────────────────────────────
# HOW IT WORKS:
#   1. Someone sends HTTP POST with JSON body { "message": "...", "requestId": "..." }
#   2. Logic App receives it via the trigger URL
#   3. The payload is saved as {requestId}.json inside the workflow-runs blob container
#
# TO TEST:
#   curl -X POST "<trigger_url>" \
#     -H "Content-Type: application/json" \
#     -d '{"message": "hello", "requestId": "run-001"}'
#
# RESULT: blob created at  workflow-runs/run-001.json

resource "azurerm_logic_app_trigger_http_request" "http_to_blob" {
  name         = "when-http-request-received"
  logic_app_id = azurerm_logic_app_workflow.this.id

  schema = jsonencode({
    type = "object"
    properties = {
      message   = { type = "string" }
      requestId = { type = "string" }
    }
    required = ["requestId"]
  })
}

resource "azurerm_logic_app_action_custom" "save_payload_to_blob" {
  name         = "save-payload-to-blob"
  logic_app_id = azurerm_logic_app_workflow.this.id

  body = jsonencode({
    type = "ApiConnection"
    inputs = {
      host = {
        connection = {
          name = "@parameters('$connections')['azureblob']['connectionId']"
        }
      }
      method = "post"
      path   = "/datasets/default/files"
      queries = {
        folderPath                   = "/${var.workflow_runs_container_name}"
        name                         = "@{triggerBody()?['requestId']}.json"
        queryParametersSingleEncoded = true
      }
      body = "@triggerBody()"
    }
    runAfter = {}
  })

  depends_on = [azurerm_logic_app_trigger_http_request.http_to_blob]
}
