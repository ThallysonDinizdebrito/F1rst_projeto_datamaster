###############################
# Arquivo: outputs.tf
# Objetivo: Definir saídas importantes do Terraform
###############################

# Output do ID do Resource Group
output "id_resource_group" {
  description = "ID do Resource Group criado"
  value       = azurerm_resource_group.grupo_principal.id
}

# Output do nome do Resource Group
output "nome_resource_group" {
  description = "Nome do Resource Group"
  value       = azurerm_resource_group.grupo_principal.name
}

# Output do nome da Storage Account
output "nome_storage_account" {
  description = "Nome da Storage Account criada"
  value       = azurerm_storage_account.conta_armazenamento.name
}

# Output do nome do container raw
output "nome_container_raw" {
  description = "Nome do container raw"
  value       = azurerm_storage_container.container_raw.name
}

# Output do ID do Databricks Workspace
output "id_workspace_databricks" {
  description = "ID do Databricks Workspace criado"
  value       = azurerm_databricks_workspace.workspace.id
}

# Output da URL do Databricks Workspace
output "url_workspace_databricks" {
  description = "URL do Databricks Workspace"
  value       = azurerm_databricks_workspace.workspace.workspace_url
}
