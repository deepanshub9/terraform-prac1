# ── Workflow: HTTP Request → Response + Save to Blob ──────────────────────────
# FLOW: HTTP POST → Send 200 Response → Save payload to blob
#
# HOW TO GET TRIGGER URL after apply:
#   Portal → rg-logicapp-learn → learn-logicapp-http
#   → Logic app designer → click trigger → copy HTTP POST URL
#
# TEST:
#   curl -X POST "<trigger_url>" \
#     -H "Content-Type: application/json" \
#     -d '{"message": "hello", "requestId": "test-001"}'
#
# SEE RUNS:
#   Portal → learn-logicapp-http → Overview → Runs history

resource "azurerm_logic_app_trigger_http_request" "simple_http" {
  name         = "When_HTTP_request_received"
  logic_app_id = azurerm_logic_app_workflow.http.id

  schema = jsonencode({
    type = "object"
    properties = {
      message   = { type = "string" }
      requestId = { type = "string" }
    }
    required = ["requestId", "message"]
  })
}

resource "azurerm_logic_app_action_custom" "send_response" {
  name         = "Send_Response"
  logic_app_id = azurerm_logic_app_workflow.http.id

  body = jsonencode({
    type = "Response"
    kind = "Http"
    inputs = {
      statusCode = 200
      headers    = { "Content-Type" = "application/json" }
      body = {
        status    = "saved"
        requestId = "@{triggerBody()?['requestId']}"
        message   = "Received: @{triggerBody()?['message']}"
      }
    }
    runAfter = {}
  })

  depends_on = [azurerm_logic_app_trigger_http_request.simple_http]
}

resource "azurerm_logic_app_action_custom" "save_to_blob" {
  name         = "Save_to_Blob_Storage"
  logic_app_id = azurerm_logic_app_workflow.http.id

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
    runAfter = {
      Send_Response = ["Succeeded"]
    }
  })

  depends_on = [azurerm_logic_app_action_custom.send_response]
}
