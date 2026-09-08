# Grants Costfluent read-only access to one GCP billing export in BigQuery.
#
# Costfluent queries the detailed billing export dataset directly, so it needs to run BigQuery jobs
# in the project and read that one dataset. It is granted nothing at project data level.

resource "google_service_account" "costfluent" {
  project      = var.project_id
  account_id   = var.service_account_id
  display_name = "Costfluent Billing Access"
  description  = "Read-only BigQuery billing export access for Costfluent."
}

resource "google_service_account_key" "costfluent" {
  service_account_id = google_service_account.costfluent.name
}

# Running a query is a project-level permission; it does not grant access to any data by itself.
resource "google_project_iam_member" "bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.costfluent.email}"
}

# The only data grant: read on the billing export dataset alone.
resource "google_bigquery_dataset_iam_member" "bq_data_viewer" {
  project    = var.project_id
  dataset_id = var.billing_dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.costfluent.email}"
}
