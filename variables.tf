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

variable "billing_account_id" {
  description = "Cloud Billing account whose export the dataset holds, e.g. \"012345-ABCDEF-678901\"."
  type        = string

  validation {
    condition     = can(regex("^[0-9A-F]{6}-[0-9A-F]{6}-[0-9A-F]{6}$", var.billing_account_id))
    error_message = "Must be a Cloud Billing account ID: three hyphenated groups of six uppercase hexadecimal characters."
  }
}

variable "costfluent_service_account_email" {
  description = "The service account Costfluent provisioned for your organization, from the costfluent_gcp_service_account resource or the Add GCP dialog."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]@[a-z][a-z0-9-]{4,28}[a-z0-9]\\.iam\\.gserviceaccount\\.com$", var.costfluent_service_account_email))
    error_message = "Must be a GCP service account email ending in .iam.gserviceaccount.com."
  }
}
