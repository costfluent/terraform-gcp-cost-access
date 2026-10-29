mock_provider "google" {}

variables {
  project_id                       = "billing-project"
  billing_dataset_id               = "billing_export"
  billing_account_id               = "012345-ABCDEF-678901"
  costfluent_service_account_email = "cfp-aaaaaaaaaaaaaaaaaaaaaaaaaa@costfluent-prod-connect.iam.gserviceaccount.com"
}

run "no_cud_dataset_grants_nothing_on_it" {
  command = plan

  assert {
    condition     = length(google_bigquery_dataset_iam_member.cud_data_viewer) == 0
    error_message = "Without cud_dataset_id the module must grant nothing beyond the billing dataset."
  }

  assert {
    condition     = !contains(keys(output.settings), "cud_dataset")
    error_message = "Without cud_dataset_id the settings output must not carry cud_dataset."
  }
}

run "a_cud_dataset_is_read_like_the_billing_dataset" {
  command = plan

  variables {
    cud_dataset_id = "cud_metadata"
  }

  assert {
    condition = (
      google_bigquery_dataset_iam_member.cud_data_viewer[0].project == "billing-project" &&
      google_bigquery_dataset_iam_member.cud_data_viewer[0].dataset_id == "cud_metadata" &&
      google_bigquery_dataset_iam_member.cud_data_viewer[0].role == "roles/bigquery.dataViewer" &&
      google_bigquery_dataset_iam_member.cud_data_viewer[0].member == "serviceAccount:${var.costfluent_service_account_email}"
    )
    error_message = "The CUD metadata dataset must grant BigQuery Data Viewer to the Costfluent service account, in the billing export's project, and nothing wider."
  }

  assert {
    condition     = length(output.settings) == 1 && output.settings.cud_dataset == "cud_metadata"
    error_message = "The settings output must name the CUD metadata dataset under cud_dataset, the key Costfluent reads."
  }
}

run "an_invalid_cud_dataset_is_refused" {
  command = plan

  variables {
    cud_dataset_id = "cud-metadata"
  }

  expect_failures = [var.cud_dataset_id]
}
