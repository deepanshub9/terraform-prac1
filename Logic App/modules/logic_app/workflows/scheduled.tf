# ── Workflow 2: Scheduled Heartbeat → File Share ──────────────────────────────
# HOW IT WORKS:
#   1. Runs automatically every 1 hour
#   2. Writes a heartbeat JSON file to the logicapp-files file share
#   3. File name includes timestamp — each run creates a new file
#
# This workflow uses the azurefile connection (not azureblob)
# so you can see both storage connections working independently

resource "azurerm_logic_app_trigger_recurrence" "heartbeat_schedule" {
  name         = "every-1-hour"
  logic_app_id = azurerm_logic_app_workflow.this.id
  frequency    = "Hour"
  interval     = 1
}

resource "azurerm_logic_app_action_custom" "write_heartbeat_to_fileshare" {
  name         = "write-heartbeat-to-fileshare"
  logic_app_id = azurerm_logic_app_workflow.this.id

  body = jsonencode({
    type = "ApiConnection"
    inputs = {
      host = {
        connection = {
          # Uses the azurefile connection wired in main.tf
          name = "@parameters('$connections')['azurefile']['connectionId']"
        }
      }
      method = "post"
      path   = "/datasets/default/files"
      queries = {
        # writes into the logicapp-files share under /heartbeats/ folder
        folderPath                   = "/${var.file_share_name}/heartbeats"
        name                         = "heartbeat-@{utcNow('yyyy-MM-dd-HH-mm')}.json"
        queryParametersSingleEncoded = true
      }
      body = {
        status    = "alive"
        timestamp = "@utcNow()"
        workflow  = "heartbeat-scheduler"
      }
    }
    runAfter = {}
  })

  depends_on = [azurerm_logic_app_trigger_recurrence.heartbeat_schedule]
}
