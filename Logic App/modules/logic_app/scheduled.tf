# ── Workflow: Scheduled Heartbeat → File Share ────────────────────────────────
# Runs every 1 hour, writes a heartbeat file to logicapp-files file share
#
# SEE RUNS:
#   Portal → learn-logicapp-scheduled → Overview → Runs history

resource "azurerm_logic_app_trigger_recurrence" "heartbeat_schedule" {
  name         = "every-1-hour"
  logic_app_id = azurerm_logic_app_workflow.scheduled.id
  frequency    = "Hour"
  interval     = 1
}

resource "azurerm_logic_app_action_custom" "write_heartbeat_to_fileshare" {
  name         = "write-heartbeat-to-fileshare"
  logic_app_id = azurerm_logic_app_workflow.scheduled.id

  body = jsonencode({
    type = "ApiConnection"
    inputs = {
      host = {
        connection = {
          name = "@parameters('$connections')['azurefile']['connectionId']"
        }
      }
      method = "post"
      path   = "/datasets/default/files"
      queries = {
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
