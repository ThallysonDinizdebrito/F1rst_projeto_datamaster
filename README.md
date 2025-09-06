# Projeto de Engenharia de Dados - Azure & Databricks

Este projeto cria uma infraestrutura de engenharia de dados usando **Azure** e **Databricks**, provisionada com **Terraform** e automatizada via **GitHub Actions** (CI/CD), com ambientes separados para **desenvolvimento (dev)** e **produção (prod)**.

---

## Estrutura do Projeto

/
├── infra/
│ ├── main.tf
│ ├── variaveis.tf
│ ├── provedores.tf
│ ├── backend.tf
│ ├── dev.tfvars
│ └── prod.tfvars
│
├── .github/
│ └── workflows/
│ ├── deploy-dev.yml
│ └── deploy-prod.yml
│
└── README.md


---

## Pré-requisitos

- Conta no **Azure** com permissão para criar Resource Groups, Storage Accounts e Databricks Workspaces.
- **Service Principal** no Azure com:
  - clientId
  - clientSecret
  - tenantId
  - subscriptionId
- **GitHub Actions** configurado com os secrets:
  - `AZURE_CREDENTIALS_DEV` → JSON do SP dev
  - `AZURE_CREDENTIALS_PROD` → JSON do SP prod
  - `AZURE_STORAGE_ACCOUNT_DEV` → Storage Account do backend dev
  - `AZURE_STORAGE_ACCOUNT_PROD` → Storage Account do backend prod

- Terraform `>= 1.7.0`

Criar Service Principal no Azure:


az ad sp create-for-rbac --name "terraform-prod" --role="Contributor" --scopes="/subscriptions/<SUBSCRIPTION_ID>"


az ad sp create-for-rbac --name "terraform-dev" --role="Contributor" --scopes="/subscriptions/<SUBSCRIPTION_ID>"


Copie o JSON resultante para usar como secret:
Dev
{
  "clientId": "<ID_DO_CLIENTE>",
  "clientSecret": "<SEGREDO_DO_CLIENTE>",
  "subscriptionId": "<ID_DA_SUBSCRIPTION>",
  "tenantId": "<ID_DO_TENANT>"
}
Prod
{
  "clientId": "<ID_DO_CLIENTE>",
  "clientSecret": "<SEGREDO_DO_CLIENTE>",
  "subscriptionId": "<ID_DA_SUBSCRIPTION>",
  "tenantId": "<ID_DO_TENANT>"
}

---
crie dois ambientes 
https://github.com/<seu repositoriogit>/settings/environments
 - dev
 -prod
 

 cadastre as secrets 
AZURE_CLIENT_ID = "clientId": "<ID_DO_CLIENTE>",
AZURE_CLIENT_SECRET = "clientSecret": "<SEGREDO_DO_CLIENTE>"
AZURE_CREDENTIALS_DEV
AZURE_STORAGE_ACCOUNT_DEV = "Nome do estore de account azure"
AZURE_SUBSCRIPTION_ID = "subscriptionId": "<ID_DA_SUBSCRIPTION>"
AZURE_TENANT_ID = "tenantId": "<ID_DO_TENANT>"
AZURE_STORAGE_CONNECTION_STRING


## Backend Remoto do Terraform

> ⚠️ O backend remoto **não pode ser criado automaticamente** pelo Terraform principal do projeto.

O backend é usado para armazenar o **estado do Terraform** de forma segura e compartilhada. Antes de rodar qualquer `terraform init` ou `terraform apply`, ele precisa existir.


## dentro do power shell Import-Module Az
Install-Module -Name Az -AllowClobber -Scope CurrentUser
#Se perguntar sobre repositórios, aceite (Yes ou A).

# Isso instala todos os cmdlets do Azure, incluindo New-AzResourceGroup, New-AzStorageAccount etc.
importe o module no powershell
Import-Module Az
# entre na conta azure
Connect-AzAccount
# verificar se esta na subscription correta
Get-AzContext

# Autenticação no Azure
Connect-AzAccount -TenantId "<ID_DO_TENANT>" -UseDeviceAuthentication
 - Vai gerar um código para autenticar via navegador.
 - Ideal para desenvolvimento local.


# criar o recurso grupo backend
# Cria o Resource Group para o backend
New-AzResourceGroup -Name "rg-backend-dev" -Location "brazilsouth"


### Como criar o backend remoto (PowerShell)

```powershell
# Variáveis
$rg="rg-backend-dev"; $loc="brazilsouth"; $sa="estadotfdev"; $cont="tfstate";

# Criar Resource Group, Storage Account e container tfstate
New-AzResourceGroup -Name $rg -Location $loc;
New-AzStorageAccount -ResourceGroupName $rg -Name $sa -SkuName "Standard_LRS" -Kind "StorageV2" -Location $loc;
$key=(Get-AzStorageAccountKey -ResourceGroupName $rg -Name $sa)[0].Value;
$ctx=New-AzStorageContext -StorageAccountName $sa -StorageAccountKey $key;
New-AzStorageContainer -Name $cont -Context $ctx

#remover os recursos caso precise

Remove-AzResourceGroup -Name "rg-backend-dev" -Force
Remove-AzResourceGroup -Name "rg-dev-projeto" -Force


# criar o plano de hospedagem da function
 az functionapp plan create --name rg-dev-projeto-func-plan --resource-group rg-dev-projeto --location westeurope --sku EP1 --is-linux

 # criar a function 

 az functionapp create --name rg-dev-projeto-func --resource-group rg-dev-projeto --storage-account devprojetoarmazen --plan rg-dev-projeto-func-plan --runtime python --runtime-version 3.11 --functions-version 4 --os-type Linux


# desscobrir o Azure Key Vault da conta de armazenamento 

az storage account keys list --resource-group rg-dev-projeto --account-name devprojetoarmazen  --query "[0].value" --output tsv

#delete function
az functionapp delete --name rg-dev-projeto-func --resource-group rg-dev-projeto


# ver suas variaveis de ambiente dentro da azure
az functionapp config appsettings list --name rg-dev-projeto-func --resource-group rg-dev-projeto