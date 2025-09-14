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


# ========================================
# EventGrid Topic
# ========================================
resource "azurerm_eventgrid_topic" "topic" {
  name                = "rg-dev-projeto-topic"
  resource_group_name = azurerm_resource_group.grupo_principal.name
  location            = azurerm_resource_group.grupo_principal.location
}