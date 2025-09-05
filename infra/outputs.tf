output "id_resource_group" {
  description = "ID do Resource Group"
  value       = azurerm_resource_group.grupo_principal.id
}

output "nome_resource_group" {
  description = "Nome do Resource Group"
  value       = azurerm_resource_group.grupo_principal.name
}

output "nome_storage_account" {
  description = "Nome da Storage Account"
  value       = azurerm_storage_account.conta_armazenamento.name
}

output "nome_container_raw" {
  description = "Nome do container RAW"
  value       = azurerm_storage_container.container_raw.name
}

output "id_workspace_databricks" {
  description = "ID do Databricks Workspace"
  value       = azurerm_databricks_workspace.workspace.id
}

output "url_workspace_databricks" {
  description = "URL do Databricks Workspace"
  value       = azurerm_databricks_workspace.workspace.workspace_url
}

output "nome_function_app" {
  description = "Nome da Function App Linux"
  value       = azurerm_linux_function_app.function_app.name
}
