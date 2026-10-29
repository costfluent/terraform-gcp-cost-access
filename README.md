# terraform-gcp-cost-access

Grants [Costfluent](https://costfluent.com) read-only access to one GCP billing export and,
optionally, to its Carbon Footprint and committed use discount metadata exports and to the cost
recommendations of the projects you list.

Costfluent provisions a service account for your organization in its own project and runs the
BigQuery queries there, at its own cost. This module grants that account **BigQuery Data Viewer**
on your billing export dataset and, when you name them, on your Carbon Footprint and committed use
discount metadata export datasets, and, on each project in `recommender_project_ids`, the Recommender
viewer roles for Compute, committed use discounts and Cloud SQL. No service account or key is
created in your cloud, and no secret ever leaves it.

## Requirements

- Terraform >= 1.13
- Permission to set IAM policy on the billing export dataset and, when you list any, on each
  project in `recommender_project_ids`.
- A **Detailed usage cost** BigQuery billing export, in a US or EU multi-region dataset. Standard
  export does not carry the per-resource cost fields Costfluent needs. A dedicated project for the
  export is recommended. Enable it under **Billing → Billing export → BigQuery export**; it takes a
  few hours to start populating.

## Setup

1. Enable the Detailed usage cost export, and note the project, the dataset and the billing
   account ID.
2. Get your organization's Costfluent service account: open **Add GCP** in Costfluent, or create
   the `costfluent_gcp_service_account` resource with the Costfluent Terraform provider.
3. Apply this module with that email, which grants it BigQuery Data Viewer on the dataset. To have
   Costfluent read the projects' cost recommendations into **Savings**, list them in
   `recommender_project_ids`. To have Costfluent read the billing account's provider-reported
   carbon footprint, export it to BigQuery (**Carbon Footprint → Export**) into a dataset in the same
   project and name that dataset in `carbon_dataset_id`. To have Costfluent list the billing
   account's spend-based committed use discounts, enable the committed use discount metadata export
   (Preview, under **Billing → Billing export**; it needs Billing Account Administrator) into a new
   dataset in the same project, since Google's export setup says not to use an existing one, and
   name that dataset in `cud_dataset_id`.
4. If your organization restricts sharing to allowed domains, allow the organization ID and
   customer ID Costfluent shows beside the email.
5. Connect the billing account in Costfluent with the three values. One connection per billing
   account.

## Usage

```hcl
provider "google" {
  project = "my-billing-project"
}

module "costfluent" {
  source  = "costfluent/cost-access/gcp"
  version = "~> 0.2"

  project_id                       = "my-billing-project"
  billing_dataset_id               = "billing_export"
  billing_account_id               = "012345-ABCDEF-678901"
  costfluent_service_account_email = "cfp-...@costfluent-prod-connect.iam.gserviceaccount.com"

  # Optional: read these projects' cost recommendations into Savings.
  recommender_project_ids = ["my-app-prod", "my-app-dev"]

  # Optional: read the Carbon Footprint export in this dataset of the same project.
  carbon_dataset_id = "carbon_footprint"

  # Optional: read the committed use discount metadata export in this dataset of the same project.
  cud_dataset_id = "cud_metadata"
}
```

Then enter the billing account ID, project and dataset in Costfluent > Integrations > GCP, or read
them back with `terraform output connection_json`, and the carbon and committed use discount
datasets, when you set them, with `terraform output settings`.

### Terraform only

With the Costfluent provider, the whole connection is one apply:

```hcl
resource "costfluent_gcp_service_account" "this" {}

module "costfluent" {
  source  = "costfluent/cost-access/gcp"
  version = "~> 0.2"

  project_id                       = "my-billing-project"
  billing_dataset_id               = "billing_export"
  billing_account_id               = "012345-ABCDEF-678901"
  costfluent_service_account_email = costfluent_gcp_service_account.this.email
}

resource "costfluent_provider" "gcp" {
  key          = "gcp"
  display_name = "GCP billing"
  credentials  = module.costfluent.credentials
  settings     = module.costfluent.settings

  depends_on = [module.costfluent]
}
```

A dataset grant takes a little while to propagate; `costfluent_provider` retries the connection for
up to three minutes while Costfluent reports the dataset as not yet shared.

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `project_id` | Project hosting the BigQuery billing export. | `string` | required |
| `billing_dataset_id` | Dataset holding the detailed billing export. | `string` | required |
| `billing_account_id` | Cloud Billing account whose export the dataset holds. | `string` | required |
| `costfluent_service_account_email` | The service account Costfluent provisioned for your organization. | `string` | required |
| `recommender_project_ids` | Projects whose cost recommendations Costfluent reads into **Savings**. Each gets the three Recommender viewer roles below. | `set(string)` | `[]` |
| `carbon_dataset_id` | Dataset in `project_id` holding the Carbon Footprint export. Null grants nothing on it. | `string` | `null` |
| `cud_dataset_id` | Dataset in `project_id` holding the committed use discount metadata export (Preview), a dataset of its own. Null grants nothing on it. | `string` | `null` |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `credentials` | no | Map of `billing_account_id`, `project_id`, `bigquery_dataset`. |
| `connection_json` | no | The same map as JSON. |
| `settings` | no | `carbon_dataset` when `carbon_dataset_id` is set and `cud_dataset` when `cud_dataset_id` is set, for `costfluent_provider`; otherwise empty. |
| `billing_dataset_id` | no | Dataset the Costfluent service account was granted read access to. |
| `recommender_project_ids` | no | Projects whose cost recommendations the Costfluent service account was granted read access to. |

The field names are Costfluent's contract. Do not rename them on the way in. None of them
authenticates: access comes from the dataset grant.

## Permissions granted

- `roles/bigquery.dataViewer` on `billing_dataset_id` only, to the Costfluent service account. No
  other dataset in the project is readable, and Costfluent runs no job in your project.
- `roles/bigquery.dataViewer` on `carbon_dataset_id`, only when you set it, for the same account.
- `roles/bigquery.dataViewer` on `cud_dataset_id`, only when you set it, for the same account.
- On each project in `recommender_project_ids`, and on none by default:

  | Role | Recommenders Costfluent reads with it |
  |---|---|
  | `roles/recommender.computeViewer` | VM machine type, idle VM, idle disk, idle IP address, idle image |
  | `roles/recommender.projectCudViewer` | committed use discount purchase |
  | `roles/recommender.cloudsqlViewer` | idle and overprovisioned Cloud SQL instances |

  These are the narrowest predefined roles that cover those recommenders. They read
  recommendations and insights only, and change nothing. `roles/recommender.viewer` is not
  granted: it would also expose the project's IAM, firewall and security insights.

## Upgrading from 0.1.x

0.2.0 replaces the customer-held service account key with a Costfluent-provisioned account.

- The module no longer creates a service account, key or `roles/bigquery.jobUser` binding. Applying
  0.2.0 destroys them.
- New required inputs: `billing_account_id` and `costfluent_service_account_email`.
  `service_account_id` is gone.
- `credentials` now holds three non-sensitive fields; `credentials_json` and
  `service_account_email` are replaced by `connection_json`.
- Remove the old connection in Costfluent and connect again with the three values.

## Security

- No credential is created, stored in state or handed to Costfluent.
- Removing the module with `terraform destroy` revokes Costfluent's access completely. Removing a
  project from `recommender_project_ids` revokes its three roles and leaves the project's other
  bindings alone.

## License

MIT — see [LICENSE](LICENSE).
