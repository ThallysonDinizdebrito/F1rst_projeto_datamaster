# ========================================
# EventGrid Topic
# ========================================
resource "azurerm_eventgrid_topic" "topic" {
  name                = "rg-dev-projeto-topic"
  resource_group_name = azurerm_resource_group.grupo_principal.name
  location            = azurerm_resource_group.grupo_principal.location
}

# ========================================
# EventGrid Subscription para Function Validate
# ========================================
resource "azurerm_eventgrid_event_subscription" "sub_func" {
  name  = "testetetetets3"
  scope = azurerm_eventgrid_topic.topic.id

  event_delivery_schema = "CloudEventSchemaV1_0"

  retry_policy {
    event_time_to_live    = 1440
    max_delivery_attempts = 30
  }

  azure_function_endpoint {
    function_id = "${azurerm_linux_function_app.function_validate.id}/functions/validate_fake_data"
  }

  lifecycle {
    ignore_changes = [
      azure_function_endpoint,
    ]
  }
}
