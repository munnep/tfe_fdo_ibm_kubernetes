########################################################################################################################
# Terraform Enterprise Prerequisites
#
# All resources are defined directly in the respective .tf files:
#   resource_group.tf     - IBM Resource Group
#   cos.tf                - Cloud Object Storage instance, bucket, credentials
#   postgres.tf           - PostgreSQL (IBM Cloud Databases)
#   redis.tf              - Redis (IBM Cloud Databases)
#   vpc.tf                - VPC, subnets, public gateways, network ACL
#   additional_network.tf - VPE gateways and security groups
#   cluster.tf            - IKS or OpenShift VPC cluster (var.openshift) and agent worker pool
########################################################################################################################
