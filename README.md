# terraform-gcp-cost-access

Grants [Costfluent](https://costfluent.com) read-only access to one GCP billing export.

Costfluent provisions a service account for your organization in its own project and runs the
BigQuery queries there, at its own cost. This module grants that account **BigQuery Data Viewer**
on your billing export dataset, and nothing else. No service account, key or project-level role is
created in your cloud, and no secret ever leaves it.

## Requirements

- Terraform >= 1.13
- Permission to set IAM policy on the billing export dataset.
- A **Detailed usage cost** BigQuery billing export, in a US or EU multi-region dataset. Standard
  export does not carry the per-resource cost fields Costfluent needs. A dedicated project for the
  export is recommended. Enable it under **Billing → Billing export → BigQuery export**; it takes a
  few hours to start populating.

## Setup

1. Enable the Detailed usage cost export, and note the project, the dataset and the billing
   account ID.
2. Get your organization's Costfluent service account: open **Add GCP** in Costfluent, or create
   the `costfluent_gcp_service_account` resource with the Costfluent Terraform provider.
3. Apply this module with that email, which grants it BigQuery Data Viewer on the dataset.
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
}
```

Then enter the billing account ID, project and dataset in Costfluent > Integrations > GCP, or read
them back with `terraform output connection_json`.

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
  key         = "gcp"
  name        = "GCP billing"
  credentials = module.costfluent.credentials

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

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `credentials` | no | Map of `billing_account_id`, `project_id`, `bigquery_dataset`. |
| `connection_json` | no | The same map as JSON. |
| `billing_dataset_id` | no | Dataset the Costfluent service account was granted read access to. |

The field names are Costfluent's contract. Do not rename them on the way in. None of them
authenticates: access comes from the dataset grant.

## Permissions granted

- `roles/bigquery.dataViewer` on `billing_dataset_id` only, to the Costfluent service account. No
  other dataset in the project is readable, and Costfluent runs no job in your project.

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
- Removing the module with `terraform destroy` revokes Costfluent's access completely.

## License

MIT — see [LICENSE](LICENSE).
