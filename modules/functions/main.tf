resource "azurerm_linux_function_app" "function_app" {
  name                = "${var.nome_do_grupo_de_recursos}-func"
  location            = var.location
  resource_group_name = var.rg_name
  service_plan_id     = var.function_plan_id
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_account_key

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "RAW_CONTAINER_NAME" = var.container_raw
    "FUNCTIONS_WORKER_RUNTIME" = "python"
  }
}

output "function_app_id" {
  value = azurerm_linux_function_app.function_app.id
}
