###############################
# Arquivo: backend.tf
# Objetivo: Configurar o backend remoto para armazenar o estado do Terraform
###############################


terraform {
  backend "azurerm" {
    resource_group_name  = "rg-backend-dev"
    storage_account_name = "estadotfdev"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}