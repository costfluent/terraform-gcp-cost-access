module "costfluent" {
  source = "../.."

  project_id                       = var.project_id
  billing_dataset_id               = var.billing_dataset_id
  billing_account_id               = var.billing_account_id
  costfluent_service_account_email = var.costfluent_service_account_email
  recommender_project_ids          = var.recommender_project_ids
  carbon_dataset_id                = var.carbon_dataset_id
  cud_dataset_id                   = var.cud_dataset_id
}

output "connection_json" {
  value = module.costfluent.connection_json
}

output "settings" {
  value = module.costfluent.settings
}
