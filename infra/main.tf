###############################
# Arquivo: main.tf
# Objetivo: Provisionar recursos Azure e Databricks
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
# Outputs
# ===========================
output "id_workspace_databricks" {
  value       = azurerm_databricks_workspace.workspace.id
  description = "ID do workspace Databricks criado"
}

output "nome_storage_account" {
  value       = azurerm_storage_account.conta_armazenamento.name
  description = "Nome da Storage Account criada"
}

output "nome_container_raw" {
  value       = azurerm_storage_container.container_raw.name
  description = "Nome do container raw criado"
}
