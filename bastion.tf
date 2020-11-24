# Spin up a bastion on the control network.
module "bastion" {
  source                     = "terraform-google-modules/bastion-host/google"
  version                    = "2.10.0"
  service_account_name       = format("%s-bastion", var.prefix)
  name                       = format("%s-bastion", var.prefix)
  name_prefix                = format("%s-bastion", var.prefix)
  fw_name_allow_ssh_from_iap = format("%s-allow-iap-ssh-bastion", var.prefix)
  project                    = var.project_id
  network                    = module.control_vpc.network_self_link
  subnet                     = local.control_subnet
  zone                       = coalesce(var.bastion_zone, element(var.zones, 0))
  members                    = var.bastion_access_members
  tags                       = var.tags
  labels                     = var.labels
  # Default Bastion instance is CentOS; install tinyproxy from EPEL
  startup_script = <<EOD
#!/bin/sh
yum install -y epel-release
yum install -y tinyproxy
systemctl daemon-reload
systemctl stop tinyproxy
# Enable reverse proxy only mode and allow access from all sources; IAP is
# enforcing access to the VM.
sed -i -e '/^#\?ReverseOnly/cReverseOnly Yes' \
    -e '/^Allow /d' \
    /etc/tinyproxy/tinyproxy.conf
systemctl enable tinyproxy
systemctl start tinyproxy
EOD
}
