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
-target=azurerm_log_analytics_workspace.container_rejeitados 


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

