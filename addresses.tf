# To make things consistent, reserve IP addresses for public ingress IP,
# management, and internal BIG-IP interfaces. Having a consistent IP address
# assigned to each BIG-IP's management and internal interface makes onboarding
# ConfigSync easier.

# Reserve a public IP address for NLB forwarding rule
module "public_ip" {
  source       = "terraform-google-modules/address/google"
  version      = "2.1.0"
  project_id   = var.project_id
  region       = local.region
  names        = [format("%s-nlb", var.prefix)]
  address_type = "EXTERNAL"
}

# Reserve IPs on control VPC for BIG-IP ConfigSync consistency
module "control_private_ip" {
  source       = "terraform-google-modules/address/google"
  version      = "2.1.0"
  project_id   = var.project_id
  region       = local.region
  subnetwork   = local.control_subnet
  names        = formatlist("%s-bigip-mgt-%d", var.prefix, [for i in range(0, var.num_instances) : i])
  address_type = "INTERNAL"
}

# Reserve IPs on internal VPC for BIG-IP ConfigSync consistency
module "internal_private_ip" {
  source       = "terraform-google-modules/address/google"
  version      = "2.1.0"
  project_id   = var.project_id
  region       = local.region
  subnetwork   = local.internal_subnet
  names        = formatlist("%s-bigip-int-%d", var.prefix, [for i in range(0, var.num_instances) : i])
  address_type = "INTERNAL"
}
