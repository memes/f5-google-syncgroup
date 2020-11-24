# This module has been tested with Terraform 0.13 only.
#
# Note: GCS backend requires the current user to have valid application-default
# credentials. An error like "... failed: dialing: google: could not find default
# credenitals" indicates that the calling user must (re-)authenticate application
# default credentials using `gcloud auth application-default login`.
terraform {
  required_version = "~> 0.13.5"
  # The location and path for GCS state storage must be specified in an environment
  # file(s) via `-backend-config=env/ENV/automation-factory.config"
  backend "gcs" {}
}

# Provider and Terraform service account impersonation is handled in providers.tf

# Sanitise variables, if needed.
locals {
  # Many Google TF modules require a known service account or `terraform apply`
  # may fail due to dynamic sa email. Since the IAM account will be predictible,
  # just use the account name that will be created.
  bigip_sa   = format("%s-bigip@%s.iam.gserviceaccount.com", var.prefix, var.project_id)
  service_sa = format("%s-service@%s.iam.gserviceaccount.com", var.prefix, var.project_id)
  # Define a service discovery label/value pair if not provided
  service_discovery_label = coalesce(var.service_discovery_label, format("%s-f5-service-discovery", var.prefix))
  service_discovery_value = coalesce(var.service_discovery_value, format("%s-f5-service-member", var.prefix))
  # Labels for the backend service must contain the service discovery pair
  service_labels = merge(var.labels, {
    (local.service_discovery_label) = local.service_discovery_value
  })
  # Ensure that the resources that should *NOT* be part of service discovery do
  # not contain the label. E.g don't label BIG-IPs with key:value used for discovery.
  labels = { for k, v in var.labels : k => v if k != local.service_discovery_label }
  # Region will be taken from first BIG-IP deployment zone
  region = replace(element(var.zones, 0), "/-[a-z]$/", "")
}
