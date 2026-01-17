###############################
# Arquivo: backend.tf
# Objetivo: Configurar o backend remoto para armazenar o estado do Terraform
###############################


terraform {
  backend "azurerm" {
    resource_group_name  = "rg-backend-dev"        # seu RG recém-criado
    storage_account_name = "estadotfdev"          # sua Storage Account nova
    container_name       = "tfstate"              # container novo
    key                  = "terraform.tfstate"
  }
}