###############################
# Arquivo: dev.tfvars
# Objetivo: Variáveis específicas do ambiente de desenvolvimento
###############################

# Resource Group
nome_do_grupo_de_recursos   = "rg-dev-projeto"

# Localização
localizacao                  = "brazilsouth"

# Storage Account
nome_da_conta_de_armazenamento = "devprojetoarmazen"

# Container raw (padrão)
nome_do_container_raw        = "raw"

# Variáveis Azure (exemplo de placeholders, serão carregadas via GitHub Secrets)
id_da_subscricao             = "AZURE_CREDENTIALS_DEV"
id_do_cliente                = "ID_DO_CLIENTE_DEV"
var_secreto_do_cliente       = "SEGREDO_DO_CLIENTE_DEV"
id_do_tenant                 = "ID_DO_TENANT_DEV"

# Workspace Databricks (opcional, se for diferente do padrão)
id_workspace_databricks      = ""
