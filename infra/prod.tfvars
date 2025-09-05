###############################
# Arquivo: prod.tfvars
# Objetivo: Variáveis específicas do ambiente de produção
###############################

# Resource Group
nome_do_grupo_de_recursos   = "rg-prod-projeto"

# Localização
localizacao                  = "westeurope"

# Storage Account
nome_da_conta_de_armazenamento = "prodprojetoarmazen"

# Container raw (padrão)
nome_do_container_raw        = "raw"


# Workspace Databricks (opcional, se for diferente do padrão)
id_workspace_databricks      = ""
