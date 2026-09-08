# terraform-gcp-cost-access

Grants [Costfluent](https://costfluent.io) read-only access to one GCP billing export.

The module creates a service account, allows it to run BigQuery jobs in the project, and grants it
read access to your billing export dataset alone.

## Requirements

- Terraform >= 1.13
- Permission to create service accounts and keys, and to set IAM policy on the project and dataset.
- A **Detailed** BigQuery billing export. Standard export does not carry the per-resource cost
  fields Costfluent needs. Enable it under Billing → Billing export → BigQuery export and note the
  dataset ID; it takes a few hours to start populating.

## Usage

```hcl
provider "google" {
  project = "my-billing-project"
}

module "costfluent" {
  source  = "costfluent/cost-access/gcp"
  version = "~> 1.0"

  project_id         = "my-billing-project"
  billing_dataset_id = "billing_export"
}

output "costfluent_credentials" {
  value     = module.costfluent.credentials_json
  sensitive = true
}
```

Then:

```bash
terraform apply
terraform output -raw credentials_json | pbcopy
```

Paste into Costfluent → Providers → Add provider → Google Cloud.

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `project_id` | Project hosting the BigQuery billing export. | `string` | required |
| `billing_dataset_id` | Dataset holding the detailed billing export. | `string` | required |
| `service_account_id` | Account ID of the service account. | `string` | `"costfluent-billing"` |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `credentials` | yes | Map of `project_id`, `client_email`, `private_key`, `bigquery_dataset`. |
| `credentials_json` | yes | The same map as JSON, ready to paste into Costfluent. |
| `service_account_email` | no | Service account Costfluent authenticates as. |
| `billing_dataset_id` | no | Dataset the service account was granted read access to. |

The credential field names are Costfluent's contract. Do not rename them on the way in.

## Permissions granted

- `roles/bigquery.jobUser` on the project — permission to run a query. It grants no access to data
  by itself.
- `roles/bigquery.dataViewer` on `billing_dataset_id` only — the single data grant. No other
  dataset in the project is readable.

## Key rotation

Unlike a client secret, a GCP service account key does not expire, so nothing rotates it for you.
Rotate deliberately, and hand the new key to Costfluent when you do:

```bash
terraform apply -replace='module.costfluent.google_service_account_key.costfluent'
```

## Security

- Credential outputs are marked sensitive, so they stay out of CLI output and logs.
- The service account's private key is stored in Terraform state in plaintext. Keep state in an
  encrypted remote backend and never commit it.
- Removing the module with `terraform destroy` revokes Costfluent's access completely.

## License

MIT — see [LICENSE](LICENSE).
