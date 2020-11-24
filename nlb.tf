# Create an external TCP load balancer that will direct ingress traffic to BIG-IP
# instances.

# Health check for NLB; okay for this to fail and recover quickly
resource "google_compute_region_health_check" "nlb" {
  project             = var.project_id
  name                = format("%s-tcp-nlb", var.prefix)
  region              = local.region
  check_interval_sec  = 15
  timeout_sec         = 2
  healthy_threshold   = 1
  unhealthy_threshold = 2

  tcp_health_check {
    port = var.nlb_readiness_port
  }
}

# Add all BIG-IP instances to an unmanged group; umigs are zonal, so create
# multiple groups as needed for regional redundundancy.
resource "google_compute_instance_group" "bigip" {
  for_each    = toset(var.zones)
  project     = var.project_id
  name        = format("%s-bigip-%s", var.prefix, each.value)
  description = format("%s BIG-IP instances %s", var.prefix, each.value)
  zone        = each.value
  # Hack: Emes' TF module doesn't export instance zones, match based on self-link
  # which has the instance's zone in it.
  instances = [for bigip in module.bigip.self_links : bigip if length(regexall(format("/zones/%s/", each.value), bigip)) > 0]
  network   = module.external_vpc.network_self_link
}

# Wrap the BIG-IP uMIGs in a regional backend service
resource "google_compute_region_backend_service" "bigip" {
  provider    = google-beta
  project     = var.project_id
  name        = format("%s-bigip", var.prefix)
  description = format("%s TCP backend service for NLB", var.prefix)
  region      = local.region
  health_checks = [
    google_compute_region_health_check.nlb.id,
  ]
  protocol              = "TCP"
  load_balancing_scheme = "EXTERNAL"
  dynamic "backend" {
    for_each = [for ig in google_compute_instance_group.bigip : ig.self_link]
    content {
      group = backend.value
    }
  }
}

# Create an external NLB that sends all TCP traffic to the unmanaged instance
# groups.
resource "google_compute_forwarding_rule" "service" {
  provider              = google-beta
  project               = var.project_id
  region                = local.region
  load_balancing_scheme = "EXTERNAL"
  name                  = format("%s-nlb-bigip", var.prefix)
  description           = format("%s NLB to BIG-IP", var.prefix)
  labels                = local.labels
  # Assign the reserved public IP address to NLB
  ip_address      = element(module.public_ip.addresses, 0)
  port_range      = "1-65535"
  backend_service = google_compute_region_backend_service.bigip.id
}
