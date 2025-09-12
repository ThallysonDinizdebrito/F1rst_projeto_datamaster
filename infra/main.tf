###############################
# main.tf - Terraform Azure
# Objetivo: Provisionar recursos Azure + Function App + Event Subscription
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
  sku_name            = "Y1"  # Plano consumo
}

# ===========================
# Function App - App principal
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
    "FUNCTIONS_WORKER_RUNTIME"         = "python"
    "SCM_DO_BUILD_DURING_DEPLOYMENT"   = "true"
    "ENABLE_ORYX_BUILD"                = "true"
  }
}

# ===========================
# Function App - Validação
# ===========================
resource "azurerm_linux_function_app" "function_validate" {
  name                = "${var.nome_do_grupo_de_recursos}-func-init"
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
    "RAW_CONTAINER_NAME"       = azurerm_storage_container.container_raw.name
    "VALIDATED_CONTAINER_NAME" = azurerm_storage_container.container_validado.name
    "REJECTED_CONTAINER_NAME"  = azurerm_storage_container.container_rejeitados.name
    "AZURE_STORAGE_ACCOUNT_NAME" = azurerm_storage_account.conta_armazenamento.name
    "FUNCTIONS_WORKER_RUNTIME"   = "python"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"
    "ENABLE_ORYX_BUILD" = "true"
  }
}

# ========================================
# EventGrid Topic existente (data block)
# ========================================

resource "azurerm_eventgrid_topic" "topic" {
  name                = "rg-dev-projeto-topic"
  resource_group_name = azurerm_resource_group.grupo_principal.name
  location            = azurerm_resource_group.grupo_principal.location
}

resource "null_resource" "event_subscription_cli" {
  depends_on = [azurerm_linux_function_app.function_validate, azurerm_eventgrid_topic.topic]

  provisioner "local-exec" {
    command = <<EOT
      az eventgrid event-subscription create \
        --name testefakedatafunctioninit2 \
        --source-resource-id ${azurerm_eventgrid_topic.topic.id} \
        --endpoint-type azurefunction \
        --endpoint ${azurerm_linux_function_app.function_validate.id}/functions/validate_fake_data \
        --disable-validation
    EOT
  }
}

