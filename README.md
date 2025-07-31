# Miggo GCP Integration Terraform Module

Terraform module for integrating Miggo with GCP to increase visibility into your cloud environment, enriching data from Miggo Sensors or other APMs. This allows Miggo to detect internet-facing services, anomalies, gaps, and drifts.

## Usage

```hcl

terraform {
    required_providers {
      google = {
        source = "hashicorp/google"
        version = "6.44.0"
      }
    }
  }

provider "google" {
  project = ""
}

module "miggo-integration" {
  source                   = "miggo-io/miggo-integration/gcp"
  version                  = "1.0.3"
  access_token             = ""
}
            
```

## Resources

This module manages the following resources:

* `google_iam_workload_identity_pool`
* `google_iam_workload_identity_pool_provider`
* `google_service_account`
* `google_project_iam_member`
* `google_service_account_iam_binding`