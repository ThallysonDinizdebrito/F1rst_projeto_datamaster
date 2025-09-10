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

  # Habilita Data Lake Gen2 ideal para big data
  # is_hns_enabled = true
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
# resource "azurerm_databricks_workspace" "workspace" {
#  name                = "${var.nome_do_grupo_de_recursos}-databricks"
#  resource_group_name = azurerm_resource_group.grupo_principal.name
#  location            = azurerm_resource_group.grupo_principal.location
#  sku                 = "premium"
#}

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
  "FUNCTIONS_WORKER_RUNTIME"         = "python"
  "SCM_DO_BUILD_DURING_DEPLOYMENT"   = "true"
  "ENABLE_ORYX_BUILD"                = "true"
  "BLOB_DIRECTORY"                   =   var.nome_pasta_json   
  }
}


# =======================================================================================
# CRIAÇÃO DOS CONTAINERS PARA A FUNCTION PROX DE VALIDADOS DE CAMPOS PARA ENVIO AOS CONTAINERS 
# =======================================================================================

# ===========================
# Container 'rejeitados'
# ===========================
resource "azurerm_storage_container" "container_rejeitados" {
  name                  = var.nome_do_container_rejeitados
  storage_account_name  = azurerm_storage_account.conta_armazenamento.name
  container_access_type = "private"
}


# ===========================
# Container 'validado'
# ===========================
resource "azurerm_storage_container" "container_validado" {
  name                  = var.nome_do_container_validado
  storage_account_name  = azurerm_storage_account.conta_armazenamento.name
  container_access_type = "private"
}


# ===========================
# Linux Function App - Validação
# ===========================
resource "azurerm_linux_function_app" "function_validate" {
  name                = "${var.nome_do_grupo_de_recursos}-func-validate"  
  # Nome da Azure Function App de validação, baseado no nome do Resource Group

  location            = azurerm_resource_group.grupo_principal.location  
  # Região onde a Function será criada (mesma do Resource Group)

  resource_group_name = azurerm_resource_group.grupo_principal.name  
  # O Resource Group onde a Function será provisionada

  service_plan_id     = azurerm_service_plan.function_plan.id  
  # ID do App Service Plan que define o tipo de hospedagem (Linux + Consumo)

  storage_account_name       = azurerm_storage_account.conta_armazenamento.name  
  storage_account_access_key = azurerm_storage_account.conta_armazenamento.primary_access_key  
  # Storage Account associada à Function, usada para logs, arquivos temporários e deployment

  site_config {
    application_stack {
      python_version = "3.11"  
      # Define a versão do Python que a Function vai usar
    }
  }

  identity {
    type = "SystemAssigned"  
    # Cria uma identidade gerenciada pelo Azure para a Function,
    # que pode ser usada para acessar recursos do Azure (ex: Storage, Key Vault) sem usar keys diretamente
  }
  app_settings = {
    "RAW_CONTAINER_NAME"               = azurerm_storage_container.container_raw.name  
    # Nome do container onde os blobs de entrada (raw) vão chegar

    "VALIDATED_CONTAINER_NAME" = azurerm_storage_container.container_validado.name
    # Nome do container destino para arquivos válidos (você vai criar manualmente)

   "REJECTED_CONTAINER_NAME"  = azurerm_storage_container.container_rejeitados.name   
    # Nome do container destino para arquivos inválidos (você vai criar manualmente)

    "AZURE_STORAGE_ACCOUNT_NAME"       = azurerm_storage_account.conta_armazenamento.name  
    # Nome da Storage Account, para que a Function consiga ler/escrever blobs

    "FUNCTIONS_WORKER_RUNTIME"         = "python"  
    # Define que a Function usa runtime Python

    "SCM_DO_BUILD_DURING_DEPLOYMENT"   = "true"  
    # Permite que o código seja buildado durante o deploy (Oryx build)

    "ENABLE_ORYX_BUILD"                = "true"  
    # Habilita o mecanismo de build automático do Azure para Python
  }
}

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


# ===========================
# Event Grid Topic (custom)
# ===========================
resource "azurerm_eventgrid_topic" "topic" {
  name                = "rg-dev-projeto-topic"
  resource_group_name = azurerm_resource_group.grupo_principal.name
  location            = azurerm_resource_group.grupo_principal.location
  input_schema        = "CloudEventSchemaV1_0"
}

# ===========================
# Event Subscription
# ===========================
resource "azurerm_eventgrid_event_subscription" "sub_func" {
  name  = "rg-dev-projeto-sub-func"
  scope = azurerm_eventgrid_topic.topic.id

  included_event_types  = ["Microsoft.Storage.BlobCreated"]
  event_delivery_schema = "CloudEventSchemaV1_0"

  azure_function_endpoint {
    function_id = "${azurerm_linux_function_app.function_validate.id}/functions/validate_fake_data"
  }

  storage_blob_dead_letter_destination {
    storage_account_id          = azurerm_storage_account.sa.id
    storage_blob_container_name = azurerm_storage_container.container_rejeitados.name
  }

  depends_on = [
    azurerm_linux_function_app.function_validate,
    azurerm_eventgrid_topic.topic
  ]
}

