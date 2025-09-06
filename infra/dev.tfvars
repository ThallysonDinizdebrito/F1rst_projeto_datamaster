###############################
# Arquivo: dev.tfvars
# Objetivo: Variáveis específicas do ambiente de desenvolvimento
###############################

# Resource Group
nome_do_grupo_de_recursos   = "rg-dev-projeto"

# Localização
localizacao                  = "westeurope"

# Storage Account
nome_da_conta_de_armazenamento = "devprojetoarmazen"

# Container raw (padrão)
nome_do_container_raw        = "raw"


# Workspace Databricks (opcional, se for diferente do padrão)
id_workspace_databricks      = ""


# App Function 
nome_function_app      = "rg-dev-projeto-func"

# Container raw (padrão)
nome_pasta_json        = "json"
