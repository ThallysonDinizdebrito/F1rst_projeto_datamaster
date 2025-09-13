resource "azurerm_eventgrid_topic" "topic" {
  name                = "rg-dev-projeto-topic"
  resource_group_name = var.rg_name
  location            = var.location
}

resource "azurerm_eventgrid_event_subscription" "sub_func" {
  name  = "sub-func"
  scope = azurerm_eventgrid_topic.topic.id

  event_delivery_schema = "CloudEventSchemaV1_0"

  azure_function_endpoint {
    function_id = var.function_app_id
  }
}
