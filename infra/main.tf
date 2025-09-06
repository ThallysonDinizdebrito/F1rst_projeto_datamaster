###############################
# main.tf
# Objetivo: Provisionar recursos Azure + Databricks + Azure Function
###############################

# ===========================
# Resource Group
# ===========================
resource "azurerm_resource_group" "grupo_principal" {
  name     = var.nome_do_grupo_de_recursos
  location = var.localizacao
}

# ===========================
# Storage Account
# ===========================
resource "azurerm_storage_account" "conta_armazenamento" {
  name                     = var.nome_da_conta_de_armazenamento
  resource_group_name      = azurerm_resource_group.grupo_principal.name
  location                 = azurerm_resource_group.grupo_principal.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# ===========================
# Container 'raw'
# ===========================
resource "azurerm_storage_container" "container_raw" {
  name                  = var.nome_do_container_raw
  storage_account_name  = azurerm_storage_account.conta_armazenamento.name
  container_access_type = "private"
}

# ===========================
# Workspace Databricks
# ===========================
resource "azurerm_databricks_workspace" "workspace" {
  name                = "${var.nome_do_grupo_de_recursos}-databricks"
  resource_group_name = azurerm_resource_group.grupo_principal.name
  location            = azurerm_resource_group.grupo_principal.location
  sku                 = "premium"
}

# ===========================
# App Service Plan (para Azure Function)
# ===========================
resource "azurerm_service_plan" "function_plan" {
  name                = "${var.nome_do_grupo_de_recursos}-func-plan"
  location            = azurerm_resource_group.grupo_principal.location
  resource_group_name = azurerm_resource_group.grupo_principal.name

  os_type  = "Linux"
  sku_name = "Y1"        # plano de consumo
}

# ===========================
# Linux Function App
# ===========================
resource "azurerm_linux_function_app" "function_app" {
  name                = "${var.nome_do_grupo_de_recursos}-func"
  location            = azurerm_resource_group.grupo_principal.location
  resource_group_name = azurerm_resource_group.grupo_principal.name
  service_plan_id     = azurerm_service_plan.function_plan.id
  storage_account_name       = azurerm_storage_account.conta_armazenamento.name
  storage_account_access_key = azurerm_storage_account.conta_armazenamento.primary_access_key

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

identity {
  type = "SystemAssigned"
}

app_settings = {
  "RAW_CONTAINER_NAME"               = azurerm_storage_container.container_raw.name
  "AZURE_STORAGE_ACCOUNT_NAME"       = azurerm_storage_account.conta_armazenamento.name
  "AZURE_STORAGE_CONNECTION_STRING"  = var.storage_connection_string
  "FUNCTIONS_WORKER_RUNTIME"         = "python"
  "SCM_DO_BUILD_DURING_DEPLOYMENT"   = "true"
  "ENABLE_ORYX_BUILD"                = "true"
  }
}


