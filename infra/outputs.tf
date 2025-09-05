###############################
# outputs.tf
###############################

output "id_resource_group" {
  value = azurerm_resource_group.grupo_principal.id
}

output "nome_resource_group" {
  value = azurerm_resource_group.grupo_principal.name
}

output "nome_storage_account" {
  value = azurerm_storage_account.conta_armazenamento.name
}

output "nome_container_raw" {
  value = azurerm_storage_container.container_raw.name
}

output "id_workspace_databricks" {
  value = azurerm_databricks_workspace.workspace.id
}

output "url_workspace_databricks" {
  value = azurerm_databricks_workspace.workspace.workspace_url
}

output "nome_function_app" {
  value = azurerm_linux_function_app.function_app.name
}
