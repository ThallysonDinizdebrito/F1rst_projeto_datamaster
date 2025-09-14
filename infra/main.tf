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
# Containers
# ===========================
resource "azurerm_storage_container" "container_raw" {
  name                  = var.nome_do_container_raw
  storage_account_id    = azurerm_storage_account.conta_armazenamento.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "container_validado" {
  name                  = var.nome_do_container_validado
  storage_account_id    = azurerm_storage_account.conta_armazenamento.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "container_rejeitados" {
  name                  = var.nome_do_container_rejeitados
  storage_account_id    = azurerm_storage_account.conta_armazenamento.id
  container_access_type = "private"
}

# ===========================
# Service Plan para Function App
# ===========================
resource "azurerm_service_plan" "function_plan" {
  name                = "${var.nome_do_grupo_de_recursos}-func-plan"
  location            = azurerm_resource_group.grupo_principal.location
  resource_group_name = azurerm_resource_group.grupo_principal.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

# ===========================
# Function Apps (vazias) - func  
# ===========================
resource "azurerm_linux_function_app" "function_app" {
  name                      = "${var.nome_do_grupo_de_recursos}-func"
  location                  = azurerm_resource_group.grupo_principal.location
  resource_group_name       = azurerm_resource_group.grupo_principal.name
  service_plan_id           = azurerm_service_plan.function_plan.id
  storage_account_name      = azurerm_storage_account.conta_armazenamento.name
  storage_account_access_key= azurerm_storage_account.conta_armazenamento.primary_access_key

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  identity { type = "SystemAssigned" }

  app_settings = {
    "RAW_CONTAINER_NAME"             = azurerm_storage_container.container_raw.name
    "AZURE_STORAGE_ACCOUNT_NAME"     = azurerm_storage_account.conta_armazenamento.name
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    "SCM_DO_BUILD_DURING_DEPLOYMENT"= "true"
    "ENABLE_ORYX_BUILD"              = "true"
  }
}

# ===========================
# Function Apps (vazias) - func-init  
# ===========================


resource "azurerm_function_app" "function_validate" {
  name                = "rg-dev-projeto-func-init"
  location            = azurerm_resource_group.grupo_principal.location
  resource_group_name = azurerm_resource_group.grupo_principal.name
  service_plan_id     = azurerm_service_plan.function_plan.id
  storage_account_name = azurerm_storage_account.conta_armazenamento.name
  storage_account_access_key = azurerm_storage_account.conta_armazenamento.primary_access_key
  os_type             = "Linux"
  runtime_stack       = "python|3.11"
}

resource "azurerm_function_app_slot" "deploy_validate_zip" {
  name                = "validate_slot"
  function_app_id     = azurerm_function_app.function_validate.id
  resource_group_name = azurerm_resource_group.grupo_principal.name

  site_config {
    app_command_line = ""
  }

  depends_on = [
    azurerm_function_app.function_validate
  ]
}


resource "azurerm_function_app_zip_deploy" "validate" {
  function_app_id = azurerm_function_app.function_validate.id
  src_path        = "../azure_function/functionvalidacao/functionvalidacao.zip"

  depends_on = [azurerm_function_app.function_validate]
}


# ========================================
# EventGrid Topic
# ========================================
resource "azurerm_eventgrid_topic" "topic" {
  name                = "rg-dev-projeto-topic"
  resource_group_name = azurerm_resource_group.grupo_principal.name
  location            = azurerm_resource_group.grupo_principal.location
}