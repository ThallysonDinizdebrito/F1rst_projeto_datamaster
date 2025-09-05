###############################
# variables.tf
###############################

# Azure SP / Tenant
variable "id_da_subscricao" {
  type        = string
  description = "ID da subscription do Azure"
}

variable "id_do_cliente" {
  type        = string
  description = "Client ID do Service Principal"
}

variable "secreto_do_cliente" {
  type        = string
  description = "Client Secret do Service Principal"
  sensitive   = true
}

variable "id_do_tenant" {
  type        = string
  description = "ID do tenant do Azure"
}

# Resource Group / Storage
variable "nome_do_grupo_de_recursos" {
  type        = string
  description = "Nome do Resource Group"
}

variable "localizacao" {
  type        = string
  description = "Região do Azure"
}

variable "nome_da_conta_de_armazenamento" {
  type        = string
  description = "Nome da Storage Account"
}

variable "nome_do_container_raw" {
  type        = string
  description = "Nome do container RAW"
}

# Databricks Workspace
variable "id_workspace_databricks" {
  type        = string
  description = "ID do Databricks Workspace (opcional)"
  default     = ""
}
