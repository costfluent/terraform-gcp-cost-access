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

variable "carbon_dataset_id" {
  description = "BigQuery dataset in project_id that the Carbon Footprint export writes its carbon_footprint table to, e.g. \"carbon_footprint\". Null grants nothing on it and leaves Costfluent's carbon footprint report empty for this billing account."
  type        = string
  default     = null

  validation {
    condition     = var.carbon_dataset_id == null || can(regex("^[a-zA-Z0-9_]+$", var.carbon_dataset_id))
    error_message = "Must be null or a valid BigQuery dataset ID (letters, digits and underscores)."
  }
}

variable "cud_dataset_id" {
  description = "BigQuery dataset in project_id that the committed use discount metadata export (Preview) writes its cud_subscriptions_export table to, e.g. \"cud_metadata\". It is a dataset of its own, because Google's export setup says not to use an existing one, and enabling the export needs Billing Account Administrator. Null grants nothing on it and leaves Costfluent's committed use discount inventory empty for this billing account."
  type        = string
  default     = null

  validation {
    condition     = var.cud_dataset_id == null || can(regex("^[a-zA-Z0-9_]+$", var.cud_dataset_id))
    error_message = "Must be null or a valid BigQuery dataset ID (letters, digits and underscores)."
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

variable "recommender_project_ids" {
  description = "Projects whose cost recommendations Costfluent reads into its savings queue. Each is granted Compute, project committed use discount and Cloud SQL Recommender viewer for the Costfluent service account. Empty grants nothing beyond the billing dataset."
  type        = set(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.recommender_project_ids : can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", id))])
    error_message = "Each entry must be a valid GCP project ID."
  }
}
