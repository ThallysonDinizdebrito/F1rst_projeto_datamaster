# Data source para Function App existente
data "azurerm_linux_function_app" "function_validate" {
  name                = "projeto-func-validate"   # CONFIRMAR no portal Azure
  resource_group_name = azurerm_resource_group.rg.name
}

# Subscription do EventGrid -> Function
resource "azurerm_eventgrid_event_subscription" "sub_func" {
  name  = "sub-func-validate"
  scope = azurerm_storage_account.sa.id

  event_delivery_schema = "CloudEventSchemaV1_0"

  retry_policy {
    event_time_to_live    = 1440
    max_delivery_attempts = 30
  }

  azure_function_endpoint {
    function_id = "${data.azurerm_linux_function_app.function_validate.id}/functions/validate_fake_data"
  }

  lifecycle {
    ignore_changes = [
      azure_function_endpoint,
    ]
  }
}
