# External network will be exposed as an ingress on public internet. Egress
# through this network is prohibited.
module "external_vpc" {
  source                                 = "terraform-google-modules/network/google"
  version                                = "2.5.0"
  project_id                             = var.project_id
  network_name                           = format("%s-external", var.prefix)
  delete_default_internet_gateway_routes = false
  subnets = [
    {
      subnet_name           = "external"
      subnet_ip             = var.external_cidr
      subnet_region         = local.region
      subnet_private_access = false
    }
  ]
}

# Create a NAT gateway on the external network
module "external_nat" {
  source                             = "terraform-google-modules/cloud-nat/google"
  version                            = "~> 1.3.0"
  project_id                         = var.project_id
  region                             = local.region
  name                               = format("%s-external", var.prefix)
  router                             = format("%s-external", var.prefix)
  create_router                      = true
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  network                            = module.external_vpc.network_self_link
  subnetworks = [
    {
      name                     = "external"
      source_ip_ranges_to_nat  = ["ALL_IP_RANGES"]
      secondary_ip_range_names = []
    },
  ]
}

# Control network will be private only. Egress will be permitted via NAT created
# below.
module "control_vpc" {
  source                                 = "terraform-google-modules/network/google"
  version                                = "2.5.0"
  project_id                             = var.project_id
  network_name                           = format("%s-control", var.prefix)
  delete_default_internet_gateway_routes = false
  subnets = [
    {
      subnet_name           = "control"
      subnet_ip             = var.control_cidr
      subnet_region         = local.region
      subnet_private_access = false
    }
  ]
}

# Create a NAT gateway on the control network
module "control_nat" {
  source                             = "terraform-google-modules/cloud-nat/google"
  version                            = "~> 1.3.0"
  project_id                         = var.project_id
  region                             = local.region
  name                               = format("%s-control", var.prefix)
  router                             = format("%s-control", var.prefix)
  create_router                      = true
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  network                            = module.control_vpc.network_self_link
  subnetworks = [
    {
      name                     = "control"
      source_ip_ranges_to_nat  = ["ALL_IP_RANGES"]
      secondary_ip_range_names = []
    },
  ]
}

# Internal network will be private only. Egress will be permitted via NAT created
# below.
module "internal_vpc" {
  source                                 = "terraform-google-modules/network/google"
  version                                = "2.5.0"
  project_id                             = var.project_id
  network_name                           = format("%s-internal", var.prefix)
  delete_default_internet_gateway_routes = false
  subnets = [
    {
      subnet_name           = "internal"
      subnet_ip             = var.internal_cidr
      subnet_region         = local.region
      subnet_private_access = false
    }
  ]
}

# Make it easy to refer to the subnets
locals {
  external_subnet = lookup(lookup(module.external_vpc.subnets, format("%s/external", local.region), {}), "self_link", "")
  control_subnet  = lookup(lookup(module.control_vpc.subnets, format("%s/control", local.region), {}), "self_link", "")
  internal_subnet = lookup(lookup(module.internal_vpc.subnets, format("%s/internal", local.region), {}), "self_link", "")
}
