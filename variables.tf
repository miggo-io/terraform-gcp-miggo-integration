variable "gcp_project_name" {
  description = "GCP Project Name"
  type        = string
}

variable "access_token" {
  description = "Miggo Access Token"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "aws_role_name" {
  description = "AWS Role name"
  type        = string
  default     = "gcp-integration"
}

variable "miggo_descope_project_id" {
  description = "Miggo Descope Project ID"
  type        = string
}

