variable "project_id" {
  description = "GCP project hosting the BigQuery billing export."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Must be a valid GCP project ID."
  }
}

variable "billing_dataset_id" {
  description = "BigQuery dataset holding the detailed billing export, e.g. \"billing_export\"."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_]+$", var.billing_dataset_id))
    error_message = "Must be a valid BigQuery dataset ID (letters, digits and underscores)."
  }
}

variable "service_account_id" {
  description = "Account ID of the service account Costfluent authenticates as."
  type        = string
  default     = "costfluent-billing"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.service_account_id))
    error_message = "Must be 6-30 lowercase letters, digits, or hyphens, starting with a letter."
  }
}
