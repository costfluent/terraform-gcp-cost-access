locals {
  # The credential field names are the contract Costfluent validates against: the credential fields
  # it requires of a GCP connection. Renaming one here
  # breaks every connection made with this module, and Costfluent's own build checks it.
  # None of them authenticates: access comes from the dataset grant, not from these values.
  credentials = {
    billing_account_id = var.billing_account_id
    project_id         = var.project_id
    bigquery_dataset   = var.billing_dataset_id
  }

  # The optional settings Costfluent accepts of a GCP connection, under the same contract.
  settings = {
    carbon_dataset = var.carbon_dataset_id
    cud_dataset    = var.cud_dataset_id
  }
}

output "credentials" {
  description = "Connection fields for the Costfluent GCP connection."
  value       = local.credentials
}

output "connection_json" {
  description = "The same fields as a JSON object."
  value       = jsonencode(local.credentials)
}

output "settings" {
  description = "Settings for costfluent_provider: the carbon footprint dataset, when carbon_dataset_id is set, and the committed use discount metadata dataset, when cud_dataset_id is set."
  # A setting the module was not given is left out rather than sent empty.
  value = { for key, value in local.settings : key => value if value != null }
}

output "billing_dataset_id" {
  description = "Dataset the Costfluent service account was granted read access to."
  value       = google_bigquery_dataset_iam_member.bq_data_viewer.dataset_id
}

output "recommender_project_ids" {
  description = "Projects whose cost recommendations the Costfluent service account was granted read access to."
  value       = sort(distinct([for grant in google_project_iam_member.recommender_viewer : grant.project]))
}
