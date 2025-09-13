module "infra" {
  source                    = "./modules/infra"
  nome_do_grupo_de_recursos = var.nome_do_grupo_de_recursos
  localizacao               = var.localizacao
  nome_da_conta_de_armazenamento = var.nome_da_conta_de_armazenamento
  nome_do_container_raw     = var.nome_do_container_raw
}

module "functions" {
  source           = "./modules/functions"
  nome_do_grupo_de_recursos = var.nome_do_grupo_de_recursos
  location         = var.localizacao
  rg_name          = module.infra.rg_name
  function_plan_id = module.infra.function_plan_id
  storage_account_name = module.infra.storage_account_name
  storage_account_key  = "<pegar_do_output_secrets>"
  container_raw        = module.infra.container_raw_name
}

module "eventgrid" {
  source          = "./modules/eventgrid"
  rg_name         = module.infra.rg_name
  location        = var.localizacao
  function_app_id = module.functions.function_app_id
}
