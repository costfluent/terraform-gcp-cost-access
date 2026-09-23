locals {
  # The credential field names are the contract Costfluent validates against
  # (ProviderDefinitions.Gcp.RequiredCredentialFields in the Costfluent backend). Renaming one here
  # breaks every connection made with this module; scripts/check-integration-contract.py asserts it.
  # None of them authenticates: access comes from the dataset grant, not from these values.
  credentials = {
    billing_account_id = var.billing_account_id
    project_id         = var.project_id
    bigquery_dataset   = var.billing_dataset_id
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

output "billing_dataset_id" {
  description = "Dataset the Costfluent service account was granted read access to."
  value       = google_bigquery_dataset_iam_member.bq_data_viewer.dataset_id
}
