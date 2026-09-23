# Grants Costfluent read-only access to one GCP billing export in BigQuery.
#
# Costfluent provisions a service account for your organization in its own project and runs the
# queries there, at its own cost. This module grants that account read on the billing export
# dataset alone: no service account, key or project-level role is created in your cloud.

resource "google_bigquery_dataset_iam_member" "bq_data_viewer" {
  project    = var.project_id
  dataset_id = var.billing_dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${var.costfluent_service_account_email}"
}
