###############################
# Arquivo: dev.tfvars
# Objetivo: Variáveis específicas do ambiente de desenvolvimento
###############################

# Resource Group
nome_do_grupo_de_recursos   = "rg-dev-projeto"

# Localização
localizacao = "westeurope"

# Storage Account
nome_da_conta_de_armazenamento = "devprojetoarmazen"

# Containers
nome_do_container_source        = "source"
nome_do_container_validado   = "raw"
nome_do_container_rejeitados = "deadletter"

# Function App
nome_function_app = "rg-dev-projeto-func"

# Pasta de JSON usada na function
nome_pasta_json = "json"

# Databricks (opcional, vazio por enquanto)
id_workspace_databricks = ""
