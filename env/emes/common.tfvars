# Use this file to set Terraform variables for cis-gke specific Terraform
project_id  = "f5-gcs-4138-sales-cloud-sales"
tf_sa_email = "terraform@f5-gcs-4138-sales-cloud-sales.iam.gserviceaccount.com"
prefix      = "emes-syncgroup"
labels = {
  owner     = "emes"
  retention = "none"
}
tags          = []
zones         = ["us-west1-c", "us-west1-a"]
domain_name   = "example.com"
num_instances = 6
