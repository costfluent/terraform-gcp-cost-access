mock_provider "google" {}

variables {
  project_id                       = "billing-project"
  billing_dataset_id               = "billing_export"
  billing_account_id               = "012345-ABCDEF-678901"
  costfluent_service_account_email = "cfp-aaaaaaaaaaaaaaaaaaaaaaaaaa@costfluent-prod-connect.iam.gserviceaccount.com"
}

run "no_recommender_projects_grants_the_dataset_alone" {
  command = plan

  assert {
    condition     = length(google_project_iam_member.recommender_viewer) == 0
    error_message = "With no recommender_project_ids the module must grant no project role."
  }

  assert {
    condition     = google_bigquery_dataset_iam_member.bq_data_viewer.role == "roles/bigquery.dataViewer"
    error_message = "The billing dataset grant must stay BigQuery Data Viewer."
  }
}

run "each_listed_project_gets_the_three_recommender_viewer_roles" {
  command = plan

  variables {
    recommender_project_ids = ["shop-prod", "shop-dev"]
  }

  assert {
    condition = toset([for grant in google_project_iam_member.recommender_viewer : "${grant.project} ${grant.role}"]) == toset([
      "shop-prod roles/recommender.computeViewer",
      "shop-prod roles/recommender.projectCudViewer",
      "shop-prod roles/recommender.cloudsqlViewer",
      "shop-dev roles/recommender.computeViewer",
      "shop-dev roles/recommender.projectCudViewer",
      "shop-dev roles/recommender.cloudsqlViewer",
    ])
    error_message = "Each listed project must get exactly the Compute, project CUD and Cloud SQL Recommender viewer roles."
  }

  assert {
    condition = alltrue([
      for grant in google_project_iam_member.recommender_viewer :
      grant.member == "serviceAccount:${var.costfluent_service_account_email}"
    ])
    error_message = "The roles must go to the Costfluent service account and no one else."
  }

  assert {
    condition     = output.recommender_project_ids == tolist(["shop-dev", "shop-prod"])
    error_message = "The output must name each granted project once."
  }
}

run "an_invalid_project_id_is_refused" {
  command = plan

  variables {
    recommender_project_ids = ["Not_A_Project"]
  }

  expect_failures = [var.recommender_project_ids]
}
