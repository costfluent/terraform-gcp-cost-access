# Grants Costfluent read-only access to one GCP billing export in BigQuery, optionally to the Carbon
# Footprint export beside it, and, on the projects you list, to their cost recommendations.
#
# Costfluent provisions a service account for your organization in its own project and runs the
# queries there, at its own cost. This module grants that account read on the billing export
# dataset, on the carbon footprint dataset when carbon_dataset_id is set, and, for each project in
# recommender_project_ids, the three Recommender viewer roles below. No service account or key is
# created in your cloud.

locals {
  # The narrowest predefined roles that list the cost recommenders Costfluent reads: Compute for
  # machine type, idle instance, disk, address and image; project committed use discounts; and
  # Cloud SQL idle and overprovisioned instances. roles/recommender.viewer would also expose the
  # project's IAM, firewall and security insights. Costfluent's own build checks this list against
  # the roles its Recommender reader names.
  recommender_roles = [
    "roles/recommender.computeViewer",
    "roles/recommender.projectCudViewer",
    "roles/recommender.cloudsqlViewer",
  ]

  recommender_grants = {
    for pair in setproduct(var.recommender_project_ids, local.recommender_roles) :
    "${pair[0]}/${pair[1]}" => { project = pair[0], role = pair[1] }
  }
}

resource "google_bigquery_dataset_iam_member" "bq_data_viewer" {
  project    = var.project_id
  dataset_id = var.billing_dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${var.costfluent_service_account_email}"
}

# The Carbon Footprint export writes its carbon_footprint table to a dataset of its own in the
# billing export's project, which Costfluent reads with the same role.
resource "google_bigquery_dataset_iam_member" "carbon_data_viewer" {
  count = var.carbon_dataset_id == null ? 0 : 1

  project    = var.project_id
  dataset_id = var.carbon_dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${var.costfluent_service_account_email}"
}

# Additive bindings: the project's other members and roles are left as they are.
resource "google_project_iam_member" "recommender_viewer" {
  for_each = local.recommender_grants

  project = each.value.project
  role    = each.value.role
  member  = "serviceAccount:${var.costfluent_service_account_email}"
}
