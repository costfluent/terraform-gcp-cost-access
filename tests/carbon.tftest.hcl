mock_provider "google" {}

variables {
  project_id                       = "billing-project"
  billing_dataset_id               = "billing_export"
  billing_account_id               = "012345-ABCDEF-678901"
  costfluent_service_account_email = "cfp-aaaaaaaaaaaaaaaaaaaaaaaaaa@costfluent-prod-connect.iam.gserviceaccount.com"
}

run "no_carbon_dataset_grants_nothing_on_it" {
  command = plan

  assert {
    condition     = length(google_bigquery_dataset_iam_member.carbon_data_viewer) == 0
    error_message = "Without carbon_dataset_id the module must grant nothing beyond the billing dataset."
  }

  assert {
    condition     = length(output.settings) == 0
    error_message = "Without carbon_dataset_id the settings output must be empty."
  }
}

run "a_carbon_dataset_is_read_like_the_billing_dataset" {
  command = plan

  variables {
    carbon_dataset_id = "carbon_footprint"
  }

  assert {
    condition = (
      google_bigquery_dataset_iam_member.carbon_data_viewer[0].project == "billing-project" &&
      google_bigquery_dataset_iam_member.carbon_data_viewer[0].dataset_id == "carbon_footprint" &&
      google_bigquery_dataset_iam_member.carbon_data_viewer[0].role == "roles/bigquery.dataViewer" &&
      google_bigquery_dataset_iam_member.carbon_data_viewer[0].member == "serviceAccount:${var.costfluent_service_account_email}"
    )
    error_message = "The carbon dataset must grant BigQuery Data Viewer to the Costfluent service account, in the billing export's project, and nothing wider."
  }

  assert {
    condition     = length(output.settings) == 1 && output.settings.carbon_dataset == "carbon_footprint"
    error_message = "The settings output must name the carbon dataset under carbon_dataset, the key Costfluent reads."
  }
}

run "an_invalid_carbon_dataset_is_refused" {
  command = plan

  variables {
    carbon_dataset_id = "carbon-footprint"
  }

  expect_failures = [var.carbon_dataset_id]
}
