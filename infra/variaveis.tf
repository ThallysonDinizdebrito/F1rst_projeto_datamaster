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

variable "nome_do_container_source" {
  type        = string
  description = "Nome do container source"
}


# Databricks Workspace
variable "id_workspace_databricks" {
  type        = string
  description = "ID do Databricks Workspace (opcional)"
  default     = ""
}

variable "nome_function_app" {
  description = "Nome da Azure Function App"
  type        = string
  default     = "rg-dev-projeto-func"
}


variable "nome_pasta_json" {
  type        = string
  description = "Nome da pasta json"
}

variable "nome_do_container_rejeitados" {
  type        = string
  description = "Nome do container dead_letter"
}

variable "nome_do_container_validado" {
  type        = string
  description = "Nome do container validado"
}

variable "env" {
  type        = string
  description = "Ambiente (dev, hml, prod)"
  default     = "dev"
}

