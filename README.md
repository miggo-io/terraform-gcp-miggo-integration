# Miggo GCP Integration Terraform Module

Terraform module for integrating Miggo with GCP to increase visibility into your cloud environment, enriching data from Miggo Sensors or other APMs. This allows Miggo to detect internet-facing services, anomalies, gaps, and drifts.

## Usage

```hcl
module "miggo_integration" {
  source  = "miggo-io/miggo-integration/google"
  version = "1.0.0"

  gcp_project_name         = "your-gcp-project-name"
  access_token             = "your-miggo-access-token"
  miggo_descope_project_id = "miggo-descope-project-id"
  aws_account_id           = "miggo-aws-account-id"
  aws_role_name            = "gcp-integration"
}
```

## Resources

This module manages the following resources:

* `google_iam_workload_identity_pool`
* `google_iam_workload_identity_pool_provider`
* `google_service_account`
* `google_project_iam_member`
* `google_service_account_iam_binding`