locals {
    webhook_url = "https://api.miggo.io/integration/gcp"
    miggo_auth_url = "https://auth.miggo.io/v1/auth/accesskey/exchange"
    miggo_descope_project_id = "P2UjsJwOFdIeUAtW0pGTJ5SeJAlq"
    aws_role_name = "gcp-integration"
    aws_account_id = "540030267408"
}

data "google_client_config" "current" {}

# Get the project number from the project ID
data "google_project" "current" {
  project_id = data.google_client_config.current.project
}

# Create the workload identity pool
resource "google_iam_workload_identity_pool" "miggo_workload_identity_pool" {
  project                   = data.google_client_config.current.project
  workload_identity_pool_id = "miggo-workload-identity-pool"
  display_name              = "Miggo Workload Identity Pool"
}

# Create the AWS workload identity provider
resource "google_iam_workload_identity_pool_provider" "miggo_workload_identity_pool_provider" {
  project                            = data.google_client_config.current.project
  workload_identity_pool_id          = google_iam_workload_identity_pool.miggo_workload_identity_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "miggo-workload-identity-provider"

  aws {
    account_id = local.aws_account_id
  }

  attribute_mapping = {
    "attribute.aws_role" = "assertion.arn.contains('assumed-role') ? assertion.arn.extract('{account_arn}assumed-role/') + 'assumed-role/' + assertion.arn.extract('assumed-role/{role_name}/') : assertion.arn"
    "google.subject"     = "assertion.arn"
    "attribute.aws_user" = "assertion.arn.extract('assumed-role/${local.aws_role_name}/{user}')"
  }
}

resource "google_service_account" "miggo_service_account" {
  project    = data.google_client_config.current.project
  account_id = "miggo-service-account"
}

# ask owner about the permissions - what to keep
resource "google_project_iam_member" "miggo_permissions" {
  for_each = toset([
    "roles/viewer",
    "roles/storage.objectViewer",
    "roles/compute.viewer",
    "roles/compute.networkViewer",
    "roles/container.viewer",
    "roles/cloudsql.viewer",
    "roles/spanner.viewer",
    "roles/bigtable.viewer",
    "roles/bigquery.dataViewer",
    "roles/bigquery.metadataViewer",
    "roles/dataflow.viewer",
    "roles/dataproc.viewer",
    "roles/iam.securityReviewer",
    "roles/securitycenter.findingsViewer",
    "roles/securitycenter.sourcesViewer",
    "roles/logging.viewer",
    "roles/monitoring.viewer",
    "roles/cloudtrace.user",
    "roles/cloudprofiler.user",
    "roles/dns.reader",
    "roles/appengine.appViewer",
    "roles/cloudfunctions.viewer",
    "roles/run.viewer",
    "roles/file.viewer",
    "roles/pubsub.viewer",
    "roles/secretmanager.viewer",
    "roles/apigateway.viewer",
    "roles/domains.viewer",
  ])
  
  project = data.google_client_config.current.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.miggo_service_account.email}"
}

resource "google_service_account_iam_binding" "readonly_workload_identity_binding" {
  service_account_id = google_service_account.miggo_service_account.id
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "principalSet://iam.googleapis.com/projects/${data.google_project.current.number}/locations/global/workloadIdentityPools/miggo-workload-identity-pool/attribute.aws_role/arn:aws:sts::${local.aws_account_id}:assumed-role/${local.aws_role_name}",
  ]
}

resource "google_service_account_iam_binding" "readonly_workload_identity_token_creator" {
  service_account_id = google_service_account.miggo_service_account.id
  role               = "roles/iam.serviceAccountTokenCreator"
  members = [
    "principalSet://iam.googleapis.com/projects/${data.google_project.current.number}/locations/global/workloadIdentityPools/miggo-workload-identity-pool/attribute.aws_role/arn:aws:sts::${local.aws_account_id}:assumed-role/${local.aws_role_name}",
  ]
}

resource "google_service_account_iam_binding" "readonly_workload_identity_user" {
  service_account_id = google_service_account.miggo_service_account.id
  role               = "roles/iam.serviceAccountUser"
  members = [
    "principalSet://iam.googleapis.com/projects/${data.google_project.current.number}/locations/global/workloadIdentityPools/miggo-workload-identity-pool/attribute.aws_role/arn:aws:sts::${local.aws_account_id}:assumed-role/${local.aws_role_name}",
  ]
}


# Send webhook notification about the integration
resource "null_resource" "integration_webhook" {
  triggers = {
    project_id = data.google_project.current.number
  }

  provisioner "local-exec" {
    command = <<EOT
      /usr/bin/env sh -c 'TOKEN=$(curl -X POST ${local.miggo_auth_url} \
      -H "Authorization: Bearer ${local.miggo_descope_project_id}:${var.access_token}" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      -d "{}" \
      | jq -r ".sessionJwt") && \
      curl -X POST ${local.webhook_url} \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"GCPProjectNumber\": \"${data.google_project.current.number}\"}"'
    EOT
  }

  depends_on = [
    data.google_project.current,
    google_iam_workload_identity_pool.miggo_workload_identity_pool,
    google_iam_workload_identity_pool_provider.miggo_workload_identity_pool_provider,
    google_service_account.miggo_service_account,
    google_project_iam_member.miggo_permissions,
    google_service_account_iam_binding.readonly_workload_identity_binding,
    google_service_account_iam_binding.readonly_workload_identity_token_creator,
    google_service_account_iam_binding.readonly_workload_identity_user,
  ]
}