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

# Two _iam_member resources for one (dataset, role, member) share one binding entry: deleting either
# removes the member from the dataset, so the billing or carbon read would go when cud_dataset_id is
# later unset or moved.
run "a_cud_dataset_equal_to_the_billing_or_carbon_dataset_is_granted_once" {
  command = plan

  variables {
    cud_dataset_id = "billing_export"
  }

  assert {
    condition     = length(google_bigquery_dataset_iam_member.cud_data_viewer) == 0
    error_message = "A CUD dataset that is the billing dataset must not be granted a second time."
  }

  assert {
    condition     = google_bigquery_dataset_iam_member.bq_data_viewer.dataset_id == "billing_export"
    error_message = "The billing dataset must still be granted."
  }

  assert {
    condition     = output.settings.cud_dataset == "billing_export"
    error_message = "The settings output must still name the CUD dataset, so Costfluent reads cud_subscriptions_export from it."
  }
}

run "a_cud_dataset_equal_to_the_carbon_dataset_is_granted_once" {
  command = plan

  variables {
    carbon_dataset_id = "exports"
    cud_dataset_id    = "exports"
  }

  assert {
    condition     = length(google_bigquery_dataset_iam_member.cud_data_viewer) == 0
    error_message = "A CUD dataset that is the carbon dataset must not be granted a second time."
  }

  assert {
    condition     = google_bigquery_dataset_iam_member.carbon_data_viewer[0].dataset_id == "exports"
    error_message = "The shared dataset must still be granted once, by carbon_data_viewer."
  }

  assert {
    condition     = output.settings.carbon_dataset == "exports" && output.settings.cud_dataset == "exports"
    error_message = "The settings output must still name both datasets."
  }
}

run "a_cud_dataset_distinct_from_both_is_granted_beside_them" {
  command = plan

  variables {
    carbon_dataset_id = "carbon_footprint"
    cud_dataset_id    = "cud_metadata"
  }

  assert {
    condition = (
      length(google_bigquery_dataset_iam_member.carbon_data_viewer) == 1 &&
      google_bigquery_dataset_iam_member.cud_data_viewer[0].dataset_id == "cud_metadata"
    )
    error_message = "Three distinct datasets must each be granted once."
  }
}
