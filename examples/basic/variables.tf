variable "project_id" {
  description = "Project hosting the BigQuery billing export."
  type        = string
}

variable "billing_dataset_id" {
  description = "Dataset holding the detailed billing export."
  type        = string
}
