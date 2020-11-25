# F5 BIG-IP sync-groups and GCP L4 LBs

Provisions a number of BIG-IP instances and adds them to unmanaged instance groups
that can be fronted by a GCP NLB. A sync-only group is established between BIG-IP
instances.

## Provision

Copy or edit the environment files that drive the provisioning.

```shell
terraform init -backend-config env/emes/common.config
terraform apply -var-file env/emes/common.tfvars -auto-approve
```

## GUI management

Start an SSH tunnel proxy through IAP and use `127.0.0.1:8888` for HTTPS proxy.

```shell
gcloud compute ssh emes-syncgroup-bastion --strict-host-key-checking=no --ssh-flag=-oUserKnownHostsFile=/dev/null --ssh-flag=-A --ssh-flag=-L8888:127.0.0.1:8888 --project=f5-gcs-4138-sales-cloud-sales --zone=us-west1-c
```

## Teardown

```shell
terraform destroy -var-file env/emes/common.tfvars -auto-approve
```
