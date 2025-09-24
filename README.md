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

az ad sp create-for-rbac --name "terraform-dev" --role="Contributor" --scopes="/subscriptions/<SUBSCRIPTION_ID>"


Salve o JSON resultante para usar como secret:

{
  "clientId": "<ID_DO_CLIENTE>",
  "clientSecret": "<SEGREDO_DO_CLIENTE>",
  "subscriptionId": "<ID_DA_SUBSCRIPTION>",
  "tenantId": "<ID_DO_TENANT>"
}

# cadastro de SECRET NO GITHUB 

INSTALAÇÃO 
winget install github.cli
VERIFICAR SE INSTALOUI
gh --version

LOGIN
gh auth login
Where do you use GitHub? GitHub.com
? What is your preferred protocol for Git operations on this host? HTTPS
? Authenticate Git with your GitHub credentials? Yes
? How would you like to authenticate GitHub CLI? Login with a web browser
! First copy your one-time code: exemplo 4355-1C03
coloque esse código no browser onde pede o código

crie as secrets usando ojson do Service Principal 

exemplo template
gh secret set <NOME_SECRET> --body "<secret_key>" -- env <environments>
exemplo pratico, fazer para todos
gh secret set AZURE_CLIENT_ID --body "***********" -- env dev
  nomes:
    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID


## Backend Remoto do Terraform

> ⚠️ O backend remoto **é  criado automaticamente no ci/cd** pelo CLI no projeto.

O backend é usado para armazenar o **estado do Terraform** de forma segura e compartilhada. Antes de rodar qualquer `terraform init` ou `terraform apply`, ele precisa existir.
porém ja esta setado para ser criado no ci/cd só olhar na configuração do YML

#Apartir daqui é necessario somente se quizer criar o state do terraform localmente via power Shell


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


# Como criar o backend remoto (PowerShell)

'```powershell
#Variáveis
$rg="rg-backend-dev"; $loc="brazilsouth"; $sa="estadotfdev"; $cont="tfstate";

# Criar Resource Group, Storage Account e container tfstate
New-AzResourceGroup -Name $rg -Location $loc;
New-AzStorageAccount -ResourceGroupName $rg -Name $sa -SkuName "Standard_LRS" -Kind "StorageV2" -Location $loc;
$key=(Get-AzStorageAccountKey -ResourceGroupName $rg -Name $sa)[0].Value;
$ctx=New-AzStorageContext -StorageAccountName $sa -StorageAccountKey $key;
New-AzStorageContainer -Name $cont -Context $ctx

# remover os recursos caso precise

Remove-AzResourceGroup -Name "rg-backend-dev" -Force


# criar o plano de hospedagem da function - (NÃO NECESSITA NO PROJETO PORQUE VAMOS USAR O PADRÃO)
 az functionapp plan create --name rg-dev-projeto-func-plan --resource-group rg-dev-projeto --location westeurope --sku EP1 --is-linux


# JA ESTA PROVISIONADA A SER CRIADA NO CLI NO DEPLOY  (APENAS PARA CRIAÇÃO E TESTES)
 # criar a function 

 az functionapp create --name rg-dev-projeto-func --resource-group rg-dev-projeto --storage-account devprojetoarmazen --plan rg-dev-projeto-func-plan --runtime python --runtime-version 3.11 --functions-version 4 --os-type Linux


MODELO DE CRIAÇÃO DE FUNCTION
# az functionapp create `
# >>   --resource-group rg-dev-projeto `
# >>   --name rg-dev-projeto-func-init `
# >>   --storage-account devprojetoarmazen `
# >>   --consumption-plan-location westeurope `
# >>   --runtime python `
# >>   --runtime-version 3.11 `
# >>   --functions-version 4 `
# >>   --os-type Linux


# desscobrir o Azure Key Vault da conta de armazenamento 

az storage account keys list --resource-group rg-dev-projeto --account-name devprojetoarmazen  --query "[0].value" --output tsv

# delete function
az functionapp delete --name rg-dev-projeto-func --resource-group rg-dev-projeto

# ver suas variaveis de ambiente dentro da azure
az functionapp config appsettings list --name rg-dev-projeto-func --resource-group rg-dev-projeto

# function start função local
func start


# para testes
# cria um arquivo json teste na pasta aberta
echo "{'teste':'ok'}" > teste.json
# envia o arquivo para o blobstorage
az storage blob upload --account-name devprojetoarmazen --container-name raw --name teste.json --file teste.json --account-key  <key>

#back commite  (caso tenha subido um comite com secret)
escolher o comite com a ser excluido ou editado
git log --oneline

numeros de commites 
git rebase -i HEAD~5

D para dropar os commites
:wq
para salvar e fechar

continuar ou abortar o rebase
git rebase --continue
git rebase --abort

# trazer o json do recurso subscrition (para analisar o json e usar como exemplo na criação de um recurso existente)
az eventgrid event-subscription show --name testefakedatafunctioninit --source-resource-id $(az eventgrid topic show -g rg-dev-projeto -n rg-dev-projeto-topic --query id -o tsv) -o json

# caso precise criar o zip dos pacotes das function (função pra criar um zip para function empacotar e envia para function app criada)
Compress-Archive -Path * -DestinationPath functionvalidacao.zip

# Reinstalar Libs ja deploada das function (muito utio para quando a function não esta funcionando)
cd site/wwwroot
python -m pip install --force-reinstall -r requirements.txt

#reiniciar a function 
# Via Azure CLI
az functionapp restart --name rg-dev-projeto-func --resource-group rg-dev-projeto


# remover ID Lock em Deploy mal sucedido ou cancelado (quando o processo de plan para ou não é completado)
 cd C:\Users\Thall\infra\F1rstDatamaster\infra
terraform force-unlock 1a55c1d2-cf51-561c-2934-74b79b4bcbc5


# listar os serviços na azure
az appservice plan list --resource-group rg-dev-projeto -o table

# garante a reinstalação das libs das function principalmente para a function que gera dados
C:\Users\Thall\infra\F1rstDatamaster\azure_function\GeracaoData> func azure functionapp publish rg-dev-projeto-func --build remote --python

C:\Users\Thall\infra\F1rstDatamaster\azure_function\functionvalidacao> func azure functionapp publish rg-dev-projeto-func-init --build remote --python

# APAGAR O PACKAGE DA FUNCTION
 az functionapp config appsettings delete --name rg-dev-projeto-func --resource-group rg-dev-projeto --setting-names WEBSITE_RUN_FROM_PACKAGE

# CRIAR KEYVALUE 
az keyvault create --name kv-devprojeto --resource-group rg-dev-projeto --location brazilsouth
# CRIAR SEM RBAC
az keyvault create  --name kv-devprojeto --resource-group rg-dev-projeto  --location brazilsouth --enable-rbac-authorization false 

# CONSEDER PERMISÃO - atenção precisa colocar #@ext@
az keyvault set-policy --name kv-devprojeto --upn "thallysoncamila2017_outlook.com#EXT#@thallysoncamila2017outlook.onmicrosoft.com"--secret-permissions get list set delete

# registrar um provider no grafana
az provider register --namespace Microsoft.Dashboard

# verificar se ja esta confirmado o registro
az provider show --namespace Microsoft.Dashboard --query "registrationState"

so rodar a pipeline quando o status do registro estiver como 
"Registered"