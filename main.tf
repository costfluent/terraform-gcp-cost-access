# Grants Costfluent read-only access to one GCP billing export in BigQuery, optionally to the Carbon
# Footprint and committed use discount metadata exports beside it, and, on the projects, folders or
# organization you list, to their projects' cost recommendations.
#
# Costfluent provisions a service account for your organization in its own project and runs the
# queries there, at its own cost. This module grants that account read on the billing export
# dataset, on the carbon footprint dataset when carbon_dataset_id is set, on the committed use
# discount metadata dataset when cud_dataset_id is set, and the three Recommender viewer roles below
# on each project in recommender_project_ids, each folder in recommender_folder_ids and the
# organization in recommender_organization_id. No service account or key is created in your cloud.

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

  recommender_folder_grants = {
    for pair in setproduct(var.recommender_folder_ids, local.recommender_roles) :
    "${pair[0]}/${pair[1]}" => { folder = pair[0], role = pair[1] }
  }

  recommender_organization_grants = {
    for pair in setproduct(var.recommender_organization_id == null ? [] : [var.recommender_organization_id], local.recommender_roles) :
    "${pair[0]}/${pair[1]}" => { organization = pair[0], role = pair[1] }
  }
}

resource "google_bigquery_dataset_iam_member" "bq_data_viewer" {
  project    = var.project_id
  dataset_id = var.billing_dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${var.costfluent_service_account_email}"
}

# The Carbon Footprint export writes its carbon_footprint table to a dataset in the billing export's
# project, which Costfluent reads with the same role. A dataset another resource here already grants
# is not granted again: two _iam_member resources for one dataset, role and member share one binding
# entry, so deleting either, when its input is later unset or moved, revokes the other's read too.
resource "google_bigquery_dataset_iam_member" "carbon_data_viewer" {
  count = var.carbon_dataset_id == null || var.carbon_dataset_id == var.billing_dataset_id ? 0 : 1

  project    = var.project_id
  dataset_id = var.carbon_dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${var.costfluent_service_account_email}"
}

# The committed use discount metadata export writes its cud_subscriptions_export table to a dataset
# of its own in the billing export's project, which Costfluent reads with the same role. As above, a
# dataset already granted is not granted again. The null test is a conditional, not ||: older
# Terraform releases, 1.9 among them, evaluate both operands, and contains() refuses a null value.
resource "google_bigquery_dataset_iam_member" "cud_data_viewer" {
  count = var.cud_dataset_id == null ? 0 : contains([var.billing_dataset_id, var.carbon_dataset_id], var.cud_dataset_id) ? 0 : 1

  project    = var.project_id
  dataset_id = var.cud_dataset_id
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

# The same roles on a folder or the organization, which every project under it inherits. Costfluent
# still reads only the projects in the billing export's recent cost rows. Additive members, as above.
resource "google_folder_iam_member" "recommender_viewer" {
  for_each = local.recommender_folder_grants

  folder = "folders/${each.value.folder}"
  role   = each.value.role
  member = "serviceAccount:${var.costfluent_service_account_email}"
}

resource "google_organization_iam_member" "recommender_viewer" {
  for_each = local.recommender_organization_grants

  org_id = each.value.organization
  role   = each.value.role
  member = "serviceAccount:${var.costfluent_service_account_email}"
}
