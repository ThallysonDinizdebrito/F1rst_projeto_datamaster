terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.43.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = ">= 1.30.0"
    }
  }
}

# Provider Azure
provider "azurerm" {
  features {}   
  subscription_id = var.id_da_subscricao
  client_id       = var.id_do_cliente
  client_secret   = var.secreto_do_cliente
  tenant_id       = var.id_do_tenant
}

# Provider Databricks
provider "databricks" {
  azure_workspace_resource_id = var.id_workspace_databricks
  azure_client_id             = var.id_do_cliente
  azure_client_secret         = var.secreto_do_cliente
  azure_tenant_id             = var.id_do_tenant
}
