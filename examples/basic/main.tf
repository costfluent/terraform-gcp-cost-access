module "costfluent" {
  source = "../.."

  project_id         = var.project_id
  billing_dataset_id = var.billing_dataset_id
}

output "credentials_json" {
  value     = module.costfluent.credentials_json
  sensitive = true
}
