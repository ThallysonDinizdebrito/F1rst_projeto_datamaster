# =======================================================================================
# Event Grid - System Topic 
# =======================================================================================
resource "azurerm_eventgrid_system_topic" "raw_topic" {
  name                = "${var.nome_do_grupo_de_recursos}-raw-topic"
  location            = azurerm_resource_group.grupo_principal.location
  resource_group_name = azurerm_resource_group.grupo_principal.name
  source_arm_resource_id = azurerm_storage_account.conta_armazenamento.id
  topic_type          = "Microsoft.Storage.StorageAccounts"
}



# Data source para Function App existente
data "azurerm_linux_function_app" "function_validate" {
  name                = "rg-dev-projeto-func-init"
  resource_group_name = "rg-dev-projeto"
}

# EventGrid Subscription apontando para a Function
resource "azurerm_eventgrid_event_subscription" "sub_func" {
  name  = "sub-func-    "
  scope = azurerm_eventgrid_topic.topic.id        # Ou storage_account.sa.id se for o caso

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



# Data source para Function App existente
data "azurerm_linux_function_app" "function_validate" {
  name                = "rg-dev-projeto-func-init"
  resource_group_name = "rg-dev-projeto"
}

# EventGrid Subscription apontando para a Function
resource "azurerm_eventgrid_event_subscription" "sub_func" {
  name  = "sub-func-    "
  scope = azurerm_eventgrid_topic.topic.id        # Ou storage_account.sa.id se for o caso

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






# =================================
# Event Grid Subscription para Function App
# =================================
resource "azurerm_eventgrid_event_subscription" "raw_to_function" {
  name                  = "${var.nome_do_grupo_de_recursos}-sub-func"
  scope                 = azurerm_eventgrid_system_topic.raw_topic.id
  included_event_types  = ["Microsoft.Storage.BlobCreated"]
  event_delivery_schema = "CloudEventSchemaV1_0"

  azure_function_endpoint {
    function_id = "${azurerm_linux_function_app.function_validate.id}/functions/validate_fake_data"
  }

  dynamic "storage_blob_dead_letter_destination" {
    for_each = [1] # só um destino
    content {
      storage_account_id          = azurerm_storage_account.conta_armazenamento.id
      storage_blob_container_name = azurerm_storage_container.container_rejeitados.name
    }
  }

  depends_on = [
    azurerm_linux_function_app.function_validate,
    azurerm_eventgrid_system_topic.raw_topic
  ]
}
