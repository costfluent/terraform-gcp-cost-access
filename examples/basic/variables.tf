variable "project_id" {
  description = "Project hosting the BigQuery billing export."
  type        = string
}

variable "billing_dataset_id" {
  description = "Dataset holding the detailed billing export."
  type        = string
}

variable "billing_account_id" {
  description = "Cloud Billing account whose export the dataset holds."
  type        = string
}

variable "costfluent_service_account_email" {
  description = "The service account shown in Costfluent's Add GCP dialog."
  type        = string
}

variable "recommender_project_ids" {
  description = "Projects whose cost recommendations Costfluent may read. Empty grants none."
  type        = set(string)
  default     = []
}

variable "carbon_dataset_id" {
  description = "Dataset holding the Carbon Footprint export, in the same project. Null grants none."
  type        = string
  default     = null
}
