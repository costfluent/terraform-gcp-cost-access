# Cost recommendations for every project under some folders, or the whole organization, instead of a
# project list: the folders and organization get the Recommender viewer roles, and their projects,
# including ones created later, inherit them.
module "costfluent" {
  source = "../.."

  project_id                       = var.project_id
  billing_dataset_id               = var.billing_dataset_id
  billing_account_id               = var.billing_account_id
  costfluent_service_account_email = var.costfluent_service_account_email
  recommender_folder_ids           = var.recommender_folder_ids
  recommender_organization_id      = var.recommender_organization_id
}

output "connection_json" {
  value = module.costfluent.connection_json
}

output "recommender_folder_ids" {
  value = module.costfluent.recommender_folder_ids
}
