mock_provider "google" {}

variables {
  project_id                       = "billing-project"
  billing_dataset_id               = "billing_export"
  billing_account_id               = "012345-ABCDEF-678901"
  costfluent_service_account_email = "cfp-aaaaaaaaaaaaaaaaaaaaaaaaaa@costfluent-prod-connect.iam.gserviceaccount.com"
}

run "a_six_character_project_id_and_a_mixed_case_dataset_id_are_accepted" {
  command = plan

  variables {
    project_id         = "a-b-c1"
    billing_dataset_id = "Billing_Export_2"
  }

  assert {
    condition = alltrue([
      google_bigquery_dataset_iam_member.bq_data_viewer.project == "a-b-c1",
      google_bigquery_dataset_iam_member.bq_data_viewer.dataset_id == "Billing_Export_2",
    ])
    error_message = "A six-character project ID and a dataset ID of letters, digits and underscores must be accepted as given."
  }
}

run "a_thirty_character_project_id_is_accepted" {
  command = plan

  variables {
    project_id = join("", ["p", join("", [for i in range(28) : "0"]), "z"])
  }

  assert {
    condition     = length(google_bigquery_dataset_iam_member.bq_data_viewer.project) == 30
    error_message = "A 30-character project ID is the longest GCP allows and must be accepted."
  }
}

run "a_lower_case_billing_account_is_refused" {
  command = plan

  variables {
    billing_account_id = "012345-abcdef-678901"
  }

  expect_failures = [var.billing_account_id]
}

run "a_service_account_outside_iam_gserviceaccount_is_refused" {
  command = plan

  variables {
    costfluent_service_account_email = "costfluent-connector@example.com"
  }

  expect_failures = [var.costfluent_service_account_email]
}

run "a_project_id_with_upper_case_is_refused" {
  command = plan

  variables {
    project_id = "Billing-Project"
  }

  expect_failures = [var.project_id]
}

run "a_project_id_over_30_characters_is_refused" {
  command = plan

  variables {
    project_id = join("", ["p", join("", [for i in range(29) : "0"]), "z"])
  }

  expect_failures = [var.project_id]
}

run "a_project_id_under_6_characters_is_refused" {
  command = plan

  variables {
    project_id = "a-bc1"
  }

  expect_failures = [var.project_id]
}

run "a_dataset_id_with_a_dash_is_refused" {
  command = plan

  variables {
    billing_dataset_id = "billing-export"
  }

  expect_failures = [var.billing_dataset_id]
}
