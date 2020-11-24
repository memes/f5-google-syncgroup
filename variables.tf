variable "tf_sa_email" {
  type        = string
  description = <<EOD
The fully-qualified email address of the Terraform service account to use for
resource creation. E.g.
tf_sa_email = "terraform@PROJECT_ID.iam.gserviceaccount.com"
EOD
}

variable "tf_sa_token_lifetime_secs" {
  type        = number
  default     = 600
  description = <<EOD
The expiration duration for the service account token, in seconds. This value
should be high enough to prevent token timeout issues during resource creation,
but short enough that the token is useless replayed later. Default value is 600
(10 mins).
EOD
}

variable "project_id" {
  type        = string
  description = <<EOD
The existing project id that will host the resources. E.g.
project_id = "example-project-id"
EOD
}

variable "prefix" {
  type        = string
  default     = "syncgroup"
  description = <<EOD
The prefix to apply to generated resource names; default is 'syncgroup'.
EOD
}

variable "bigip_image" {
  type        = string
  default     = "projects/f5-7626-networks-public/global/images/f5-bigip-15-1-0-4-0-0-6-payg-good-25mbps-200618231522"
  description = <<EOD
The BIG-IP image to use for instances. Default is a PAYG Good 25mbps image.
EOD
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = <<EOD
An optional map of string key:value pairs that will be applied to all resources
that accept labels. Default is an empty map.
EOD
}

variable "tags" {
  type        = list(string)
  default     = []
  description = <<EOD
An optional list of string network tags that will be applied to all taggable
resources. Default is an empty list.
EOD
}

variable "zones" {
  type        = list(string)
  description = <<EOD
A list of GCE zones to use for BIG-IP instances.
EOD
}

variable "num_instances" {
  type        = number
  default     = 2
  description = <<EOD
The number of BIG-IP instances to provision. Default is 2.
EOD
}

variable "service_discovery_label" {
  type        = string
  default     = ""
  description = <<EOD
The resource label to use for service discovery. If left blank (default), a
label will be generated.
EOD
}

variable "service_discovery_value" {
  type        = string
  default     = ""
  description = <<EOD
The resource label value to use for service discovery. If left blank (default), a
value will be generated.
EOD
}

variable "bastion_zone" {
  type        = string
  default     = ""
  description = <<EOD
The GCE zone to use for bastion instances. If left blank (default), the first
BIG-IP `zone` value will be used.
EOD
}

variable "bastion_access_members" {
  type        = list(string)
  default     = []
  description = <<EOD
An optional list of users/groups/serviceAccounts that will be granted login
privleges to the control-plane bastion via IAP tunnelling. Default is an empty
list.
EOD
}

variable "external_cidr" {
  type        = string
  default     = "172.16.0.0/16"
  description = <<EOD
The CIDR to assign to the 'external' subnet. Default is '172.16.0.0/16'.
EOD
}

variable "control_cidr" {
  type        = string
  default     = "172.17.0.0/16"
  description = <<EOD
The CIDR to assign to the 'control' subnet. Default is '172.17.0.0/16'.
EOD
}

variable "internal_cidr" {
  type        = string
  default     = "172.18.0.0/16"
  description = <<EOD
The CIDR to assign to the 'internal' subnet. Default is '172.18.0.0/16'.
EOD
}

variable "nlb_readiness_port" {
  type        = number
  default     = 26000
  description = <<EOD
The port that will be used for NLB health check probes to BIG-IP. Default is
'26000'.
EOD
}

variable "allow_ingress_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = <<EOD
A list of source CIDRs that will be permitted to connect to BIG-IP via public
ingress and NLB. Default is '0.0.0.0/0'.
EOD
}

variable "domain_name" {
  type        = string
  default     = ""
  description = <<EOD
An optional domain name to use for BIG-IP hostnames. Default is empty string.
EOD
}
