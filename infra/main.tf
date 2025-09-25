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

  #habilitar gen2

  #Habilita ADLS Gen2 (Hierarchical Namespace)
  is_hns_enabled           = true

  # Boas práticas para Data Lake
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"


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



# ========================================
# EventGrid Topic (não criar)
# ========================================
#resource "azurerm_eventgrid_topic" "topic" {
#  name                = "rg-dev-projeto-topic"
#  resource_group_name = azurerm_resource_group.grupo_principal.name
#  location            = azurerm_resource_group.grupo_principal.location
#}


# ========================================
# Log Analytics Workspace
# ========================================

# Criação de um Log Analytics Workspace, onde ficarão centralizados
# os logs e métricas de diferentes recursos (ex: Storage Account, Databricks).

resource "azurerm_log_analytics_workspace" "this" {
  # Nome do workspace, concatenando um prefixo (law) com o ambiente (var.env).
  name                = "law-rg-dev-projeto-dev"

  # Localização e Resource Group são herdados do RG já existente.

  location            = azurerm_resource_group.grupo_principal.location
  resource_group_name = azurerm_resource_group.grupo_principal.name

  # SKU define o modelo de cobrança/capacidade. "PerGB2018" é o mais comum,
  # cobra por volume de dados ingeridos.
  sku                 = "PerGB2018"
}

# ========================================
# # Azure Monitor Diagnostic Settings para Storage Account
# ========================================

resource "azurerm_monitor_diagnostic_setting" "storage_diag" {
  name                       = "rg-dev-projeto-storage-diagnostics-logs"
  target_resource_id         = azurerm_storage_account.conta_armazenamento.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  # Apenas métricas são suportadas nessa conta
  metric {
    category = "Transaction"
  }

  metric {
    category = "Capacity"
  }
}


# ========================================
# User Assigned Managed Identity
# ========================================

resource "azurerm_user_assigned_identity" "grafana_mi" {
  name                = "grafana-mi"
  resource_group_name = azurerm_resource_group.grupo_principal.name
  location            = azurerm_resource_group.grupo_principal.location
}



# ========================================
# Azure Managed Grafana com associa essa MI a um recurso
# ========================================

resource "azurerm_dashboard_grafana" "grafana" {
  name                = "grafana-rg-dev-projeto"
  resource_group_name = azurerm_resource_group.grupo_principal.name
  location            = azurerm_resource_group.grupo_principal.location
  sku                 = "Standard"

  grafana_major_version = "11"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.grafana_mi.id]
  }

  public_network_access_enabled = true
}

# ========================================
# Role Assignment: Grafana MI -> Log Analytics
# ========================================
resource "azurerm_role_assignment" "grafana_law_reader" {
  scope                = azurerm_log_analytics_workspace.this.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = azurerm_user_assigned_identity.grafana_mi.principal_id
}

# ========================================
# Pega informações da subscription atual
# ========================================
data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "grafana_monitor_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_user_assigned_identity.grafana_mi.principal_id
}

