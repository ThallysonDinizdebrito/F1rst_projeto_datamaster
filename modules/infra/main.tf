resource "azurerm_resource_group" "grupo_principal" {
  name     = var.nome_do_grupo_de_recursos
  location = var.localizacao
}

resource "azurerm_storage_account" "conta_armazenamento" {
  name                     = var.nome_da_conta_de_armazenamento
  resource_group_name      = azurerm_resource_group.grupo_principal.name
  location                 = azurerm_resource_group.grupo_principal.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "container_raw" {
  name                  = var.nome_do_container_raw
  storage_account_id    = azurerm_storage_account.conta_armazenamento.id
  container_access_type = "private"
}

resource "azurerm_service_plan" "function_plan" {
  name                = "${var.nome_do_grupo_de_recursos}-func-plan"
  location            = azurerm_resource_group.grupo_principal.location
  resource_group_name = azurerm_resource_group.grupo_principal.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

output "rg_name" {
  value = azurerm_resource_group.grupo_principal.name
}

output "storage_account_name" {
  value = azurerm_storage_account.conta_armazenamento.name
}

output "function_plan_id" {
  value = azurerm_service_plan.function_plan.id
}
