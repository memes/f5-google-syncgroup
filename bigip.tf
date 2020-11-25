# This file handles BIG-IP specific resource configuration.

# Create a specific service account for BIG-IP VMs to use. This will be used
# to anchor firewall rules, allow service discovery, etc.
module "bigip_sa" {
  source       = "terraform-google-modules/service-accounts/google"
  version      = "3.0.1"
  project_id   = var.project_id
  prefix       = var.prefix
  names        = ["bigip"]
  display_name = "BIG-IP service account"
  project_roles = [
    "${var.project_id}=>roles/logging.logWriter",
    "${var.project_id}=>roles/monitoring.metricWriter",
    "${var.project_id}=>roles/monitoring.viewer",
    # This is to support BIG-IP downstream service discovery
    "${var.project_id}=>roles/compute.viewer"
  ]
  generate_keys = false
}

# Emes' TF module for BIG-IP requires a password in Secret Manager. Create a
# random secret and allow BIG-IP service account to read the value.
module "bigip_password" {
  source     = "memes/secret-manager/google//modules/random"
  version    = "1.0.2"
  project_id = var.project_id
  id         = format("%s-bigip-admin-password-key", var.prefix)
  accessors = [
    format("serviceAccount:%s", local.bigip_sa)
  ]
  labels           = var.labels
  length           = 8
  special_char_set = "#%&*()-_=+[]:?,."
}

locals {
  # DO will be unique per instance to setup ConfigSync
  do_payloads = [for i in range(0, var.num_instances) : templatefile("${path.module}/templates/do.json",
    {
      hostname         = format("%s-bigip-%d.%s", var.prefix, i, coalesce(var.domain_name, format("%s.c.%s.internal", element(var.zones, i), var.project_id))),
      allow_phone_home = false,
      dns_servers      = ["169.254.169.254"],
      search_domains   = ["google.internal"],
      ntp_servers      = ["169.254.169.254"],
      timezone         = "UTC",
      modules = {
        ltm = "nominal"
      },
      sync_address       = element(module.internal_private_ip.addresses, i),
      sync_group_members = module.internal_private_ip.addresses,
      sync_member        = max(0, tonumber(i) - 1)
    }
  )]
  # All instances can share the same AS3 declaration
  as3_payloads = [templatefile("${path.module}/templates/as3.json",
    {
      health_check_port      = var.nlb_readiness_port,
      health_check_addresses = [element(module.public_ip.addresses, 0)]
    }
  )]
}

module "bigip" {
  source                            = "memes/f5-bigip/google"
  version                           = "2.0.1"
  project_id                        = var.project_id
  num_instances                     = var.num_instances
  instance_name_template            = format("%s-bigip-%%d", var.prefix)
  zones                             = var.zones
  service_account                   = local.bigip_sa
  provision_external_public_ip      = false
  external_subnetwork               = local.external_subnet
  management_subnetwork             = local.control_subnet
  management_subnetwork_network_ips = module.control_private_ip.addresses
  internal_subnetworks              = [local.internal_subnet]
  internal_subnetwork_network_ips   = [for ip in module.internal_private_ip.addresses : [ip]]
  image                             = var.bigip_image
  allow_phone_home                  = false
  allow_usage_analytics             = false
  admin_password_secret_manager_key = module.bigip_password.secret_id
  metadata = {
    # Enable default service on first internal NIC; ConfigSync will fail to
    # connect if this isn't set
    INT0_ALLOW_SERVICE = "default"
  }
  do_payloads  = local.do_payloads
  as3_payloads = local.as3_payloads
}
