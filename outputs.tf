locals {
  # The provider hands the key back as base64-encoded service account JSON.
  service_account_key = jsondecode(base64decode(google_service_account_key.costfluent.private_key))

  # The credential field names are the contract Costfluent validates against
  # (ProviderDefinitions.Gcp.RequiredCredentialFields in the Costfluent backend). Renaming one here
  # breaks every connection made with this module; scripts/check-integration-contract.py asserts it.
  credentials = {
    project_id       = var.project_id
    client_email     = local.service_account_key.client_email
    private_key      = local.service_account_key.private_key
    bigquery_dataset = var.billing_dataset_id
  }
}

output "credentials" {
  description = "Credential fields for the Costfluent GCP connection."
  sensitive   = true
  value       = local.credentials
}

output "credentials_json" {
  description = "The same credentials as a JSON object, ready to paste into Costfluent."
  sensitive   = true
  value       = jsonencode(local.credentials)
}

output "service_account_email" {
  description = "Service account Costfluent authenticates as."
  value       = google_service_account.costfluent.email
}

output "billing_dataset_id" {
  description = "Dataset the service account was granted read access to."
  value       = var.billing_dataset_id
}
