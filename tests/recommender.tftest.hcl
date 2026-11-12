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

run "no_folder_or_organization_grants_nothing_above_the_projects" {
  command = plan

  assert {
    condition     = length(google_folder_iam_member.recommender_viewer) == 0 && length(google_organization_iam_member.recommender_viewer) == 0
    error_message = "Without recommender_folder_ids or recommender_organization_id the module must grant nothing on a folder or the organization."
  }
}

run "each_listed_folder_gets_the_three_recommender_viewer_roles" {
  command = plan

  variables {
    recommender_folder_ids = ["123456789012", "987654321098"]
  }

  assert {
    condition = toset([for key, grant in google_folder_iam_member.recommender_viewer : "${key} ${grant.folder} ${grant.role}"]) == toset([
      "123456789012/roles/recommender.computeViewer folders/123456789012 roles/recommender.computeViewer",
      "123456789012/roles/recommender.projectCudViewer folders/123456789012 roles/recommender.projectCudViewer",
      "123456789012/roles/recommender.cloudsqlViewer folders/123456789012 roles/recommender.cloudsqlViewer",
      "987654321098/roles/recommender.computeViewer folders/987654321098 roles/recommender.computeViewer",
      "987654321098/roles/recommender.projectCudViewer folders/987654321098 roles/recommender.projectCudViewer",
      "987654321098/roles/recommender.cloudsqlViewer folders/987654321098 roles/recommender.cloudsqlViewer",
    ])
    error_message = "Each listed folder must get exactly the Compute, project CUD and Cloud SQL Recommender viewer roles, keyed <folder>/<role>."
  }

  assert {
    condition = alltrue([
      for grant in google_folder_iam_member.recommender_viewer :
      grant.member == "serviceAccount:${var.costfluent_service_account_email}"
    ])
    error_message = "The folder roles must go to the Costfluent service account and no one else."
  }

  assert {
    condition     = length(google_project_iam_member.recommender_viewer) == 0 && length(google_organization_iam_member.recommender_viewer) == 0
    error_message = "Folders alone must grant nothing on a project or the organization."
  }

  assert {
    condition     = output.recommender_folder_ids == tolist(["123456789012", "987654321098"])
    error_message = "The output must name each granted folder once."
  }
}

run "an_organization_gets_the_three_recommender_viewer_roles" {
  command = plan

  variables {
    recommender_organization_id = "112233445566"
  }

  assert {
    condition = toset([for grant in google_organization_iam_member.recommender_viewer : "${grant.org_id} ${grant.role}"]) == toset([
      "112233445566 roles/recommender.computeViewer",
      "112233445566 roles/recommender.projectCudViewer",
      "112233445566 roles/recommender.cloudsqlViewer",
    ])
    error_message = "The organization must get exactly the Compute, project CUD and Cloud SQL Recommender viewer roles."
  }

  assert {
    condition = alltrue([
      for grant in google_organization_iam_member.recommender_viewer :
      grant.member == "serviceAccount:${var.costfluent_service_account_email}"
    ])
    error_message = "The organization roles must go to the Costfluent service account and no one else."
  }

  assert {
    condition     = output.recommender_organization_id == "112233445566"
    error_message = "The output must name the granted organization."
  }
}

run "projects_folders_and_the_organization_combine" {
  command = plan

  variables {
    recommender_project_ids     = ["shop-prod"]
    recommender_folder_ids      = ["123456789012"]
    recommender_organization_id = "112233445566"
  }

  assert {
    condition = (
      length(google_project_iam_member.recommender_viewer) == 3 &&
      length(google_folder_iam_member.recommender_viewer) == 3 &&
      length(google_organization_iam_member.recommender_viewer) == 3
    )
    error_message = "Each scope must get the three roles on its own, independent of the others."
  }
}

run "a_folder_name_instead_of_its_id_is_refused" {
  command = plan

  variables {
    recommender_folder_ids = ["folders/123456789012"]
  }

  expect_failures = [var.recommender_folder_ids]
}

run "a_non_numeric_organization_id_is_refused" {
  command = plan

  variables {
    recommender_organization_id = "acme.example"
  }

  expect_failures = [var.recommender_organization_id]
}
