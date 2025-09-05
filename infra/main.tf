###############################
# main.tf
# Objetivo: Provisionar Azure + Databricks + Function App Linux
###############################

# Resource Group
resource "azurerm_resource_group" "grupo_principal" {
  name     = var.nome_do_grupo_de_recursos
  location = var.localizacao
}

# Storage Account
resource "azurerm_storage_account" "conta_armazenamento" {
  name                     = var.nome_da_conta_de_armazenamento
  resource_group_name      = azurerm_resource_group.grupo_principal.name
  location                 = azurerm_resource_group.grupo_principal.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Container raw
resource "azurerm_storage_container" "container_raw" {
  name                  = var.nome_do_container_raw
  storage_account_name  = azurerm_storage_account.conta_armazenamento.name
  container_access_type = "private"
}

# Databricks Workspace
resource "azurerm_databricks_workspace" "workspace" {
  name                = "${var.nome_do_grupo_de_recursos}-databricks"
  resource_group_name = azurerm_resource_group.grupo_principal.name
  location            = azurerm_resource_group.grupo_principal.location
  sku                 = "premium"
}

# ===========================
# Service Plan para Function App Linux
# ===========================
resource "azurerm_service_plan" "function_plan" {
  name                = "${var.nome_do_grupo_de_recursos}-func-plan"
  location            = azurerm_resource_group.grupo_principal.location
  resource_group_name = azurerm_resource_group.grupo_principal.name

  os_type  = "Linux"    # obrigatorio
  sku_name = "Y1"       # Plano Consumo para Function App
}

# ===========================
# Function App Linux
# ===========================
resource "azurerm_linux_function_app" "function_app" {
  name                       = "${var.nome_do_grupo_de_recursos}-func"
  location                   = azurerm_resource_group.grupo_principal.location
  resource_group_name        = azurerm_resource_group.grupo_principal.name
  service_plan_id            = azurerm_service_plan.function_plan.id
  storage_account_name       = azurerm_storage_account.conta_armazenamento.name
  storage_account_access_key = azurerm_storage_account.conta_armazenamento.primary_access_key

  app_settings = {
    "RAW_CONTAINER_NAME"         = azurerm_storage_container.container_raw.name
    "AZURE_STORAGE_ACCOUNT_NAME" = azurerm_storage_account.conta_armazenamento.name
    "AZURE_STORAGE_ACCOUNT_KEY"  = azurerm_storage_account.conta_armazenamento.primary_access_key
  }
}
