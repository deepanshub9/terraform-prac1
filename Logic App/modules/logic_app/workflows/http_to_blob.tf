# ── Workflow: HTTP Request → Response + Save to Blob ──────────────────────────
#
# This is the simplest possible real workflow to learn with.
# You can see it running in Azure Portal → Logic App → Overview → Runs history
#
# FLOW:
#   HTTP POST  →  Send Response (200 OK)  →  Save payload blob
#
# HOW TO GET THE TRIGGER URL (after terraform apply):
#   1. Azure Portal → Resource Groups → rg-logicapp-learn
#   2. Click the Logic App resource
#   3. Click "Logic app designer" in left menu
#   4. Click the trigger step "When HTTP request received"
#   5. Copy the "HTTP POST URL" shown there
#
# HOW TO TEST with curl:
#   curl -X POST "<paste trigger url here>" \
#     -H "Content-Type: application/json" \
#     -d '{"message": "hello from curl", "requestId": "test-001"}'
#
# EXPECTED RESPONSE:
#   {"status": "saved", "requestId": "test-001"}
#
# WHERE TO SEE RUNS:
#   Azure Portal → Logic App → Overview → Runs history tab

# ── Step 1: HTTP Trigger ───────────────────────────────────────────────────────
resource "azurerm_logic_app_trigger_http_request" "simple_http" {
  name         = "When_HTTP_request_received"
  logic_app_id = azurerm_logic_app_workflow.this.id

  schema = jsonencode({
    type = "object"
    properties = {
      message   = { type = "string" }
      requestId = { type = "string" }
    }
    required = ["requestId", "message"]
  })
}

# ── Step 2: Send HTTP Response back to caller ──────────────────────────────────
# This runs immediately — caller gets 200 OK before the blob save happens
resource "azurerm_logic_app_action_custom" "send_response" {
  name         = "Send_Response"
  logic_app_id = azurerm_logic_app_workflow.this.id

  body = jsonencode({
    type = "Response"
    kind = "Http"
    inputs = {
      statusCode = 200
      headers = {
        "Content-Type" = "application/json"
      }
      body = {
        status    = "saved"
        requestId = "@{triggerBody()?['requestId']}"
        message   = "Workflow received: @{triggerBody()?['message']}"
      }
    }
    runAfter = {}
  })

  depends_on = [azurerm_logic_app_trigger_http_request.simple_http]
}

# ── Step 3: Save payload to blob storage ──────────────────────────────────────
# Runs after response is sent — non-blocking for the caller
resource "azurerm_logic_app_action_custom" "save_to_blob" {
  name         = "Save_to_Blob_Storage"
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
      body = {
        requestId = "@{triggerBody()?['requestId']}"
        message   = "@{triggerBody()?['message']}"
        savedAt   = "@{utcNow()}"
      }
    }
    # runs after response is already sent to caller
    runAfter = {
      Send_Response = ["Succeeded"]
    }
  })

  depends_on = [azurerm_logic_app_action_custom.send_response]
}
