# ================================================================
# Event Grid - System Topic (Storage Account)
# ================================================================
resource "azurerm_eventgrid_system_topic" "raw_topic" {
  name                   = "${var.nome_do_grupo_de_recursos}-raw-topic"
  location               = azurerm_resource_group.grupo_principal.location
  resource_group_name    = azurerm_resource_group.grupo_principal.name
  source_arm_resource_id = azurerm_storage_account.conta_armazenamento.id
  topic_type             = "Microsoft.Storage.StorageAccounts"
}

# ================================================================
# Event Grid - Custom Topic (opcional)
# ================================================================
resource "azurerm_eventgrid_topic" "custom_topic" {
  name                = "${var.nome_do_grupo_de_recursos}-custom-topic"
  location            = azurerm_resource_group.grupo_principal.location
  resource_group_name = azurerm_resource_group.grupo_principal.name
}

# ================================================================
# Data source para Function App existente
# ================================================================
data "azurerm_linux_function_app" "function_validate" {
  name                = "rg-dev-projeto-func-init"
  resource_group_name = "rg-dev-projeto"
}

# ================================================================
# Event Grid Subscription - System Topic -> Function App
# ================================================================
resource "azurerm_eventgrid_event_subscription" "sub_func_system_topic" {
  name                = "${var.nome_do_grupo_de_recursos}-sub-func-system"
  resource_group_name = azurerm_resource_group.grupo_principal.name
  system_topic        = azurerm_eventgrid_system_topic.raw_topic.name

  included_event_types  = ["Microsoft.Storage.BlobCreated"]
  event_delivery_schema = "CloudEventSchemaV1_0"

  azure_function_endpoint {
    function_id = "${data.azurerm_linux_function_app.function_validate.id}/functions/validate_fake_data"
  }

  storage_blob_dead_letter_destination {
    storage_account_id          = azurerm_storage_account.conta_armazenamento.id
    storage_blob_container_name = azurerm_storage_container.container_rejeitados.name
  }

  depends_on = [
    azurerm_eventgrid_system_topic.raw_topic
  ]
}


# ================================================================
# Event Grid Subscription - Custom Topic -> Function App
# ================================================================
resource "azurerm_eventgrid_event_subscription" "sub_func_custom_topic" {
  name                  = "${var.nome_do_grupo_de_recursos}-sub-func-custom"
  scope                 = azurerm_eventgrid_topic.custom_topic.id
  event_delivery_schema = "CloudEventSchemaV1_0"

  azure_function_endpoint {
    function_id = "${data.azurerm_linux_function_app.function_validate.id}/functions/validate_fake_data"
  }

  storage_blob_dead_letter_destination {
    storage_account_id          = azurerm_storage_account.conta_armazenamento.id
    storage_blob_container_name = azurerm_storage_container.container_rejeitados.name
  }

  depends_on = [
    azurerm_eventgrid_topic.custom_topic
  ]
}
