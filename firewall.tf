# Aggregate all Firewall rules (or modules) to this file for consistency.
#
# General approach is to use service accounts as the filters where possible,
# CIDRs where necessary.

# Allow public access to the BIG-IPs on TCP ports 80 and 443.
resource "google_compute_firewall" "ingress_bigip" {
  project       = var.project_id
  name          = format("%s-allow-ingress-bigip", var.prefix)
  network       = module.external_vpc.network_self_link
  description   = "Allow public ingress to BIG-IP VMs on external network"
  source_ranges = var.allow_ingress_cidrs
  target_service_accounts = [
    local.bigip_sa
  ]
  allow {
    protocol = "tcp"
    ports = [
      80,
      443,
    ]
  }
}

# Allow bastion instance to ping and connect to BIG-IP instances on ports 22 and
# 443 via control interface.
resource "google_compute_firewall" "bastion_bigip" {
  project     = var.project_id
  name        = format("%s-allow-bastion-bigip", var.prefix)
  network     = module.control_vpc.network_self_link
  description = "Allow bastion to BIG-IP VMs on control network"
  direction   = "INGRESS"
  source_service_accounts = [
    module.bastion.service_account,
  ]
  target_service_accounts = [
    local.bigip_sa,
  ]
  allow {
    protocol = "tcp"
    ports = [
      22,
      443,
    ]
  }
  allow {
    protocol = "icmp"
  }
}

# Allow NLB health checks to connect to BIG-IP instances on health-check port
resource "google_compute_firewall" "nlb_bigip" {
  project     = var.project_id
  name        = format("%s-allow-nlb-bigip", var.prefix)
  network     = module.external_vpc.network_self_link
  description = "Allow NLB health check to BIG-IP VMs"
  direction   = "INGRESS"
  source_ranges = [
    "35.191.0.0/16",
    "209.85.152.0/22",
    "209.85.204.0/22"
  ]
  target_service_accounts = [
    local.bigip_sa,
  ]
  allow {
    protocol = "tcp"
    ports = [
      var.nlb_readiness_port
    ]
  }
}

# Allow BIG-IP to BIG-IP ConfigSync
module "configsync_fw" {
  source                   = "memes/f5-bigip/google//modules/configsync-fw"
  version                  = "2.0.1"
  project_id               = var.project_id
  bigip_service_account    = local.bigip_sa
  dataplane_network        = module.internal_vpc.network_self_link
  management_network       = module.control_vpc.network_self_link
  dataplane_firewall_name  = format("%s-configsync-internal", var.prefix)
  management_firewall_name = format("%s-configsync-management", var.prefix)
}
