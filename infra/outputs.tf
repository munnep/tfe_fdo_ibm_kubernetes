########################################################################################################################
# Outputs (only those consumed by the tfe/ configuration)
########################################################################################################################

# cluster information
output "kubeconfig_context" {
  value = "${var.environment_prefix}-iks"
}

# COS (Cloud Object Storage)
output "cos_bucket_name" {
  description = "COS bucket name."
  value       = ibm_cos_bucket.tfe.bucket_name
}

output "cos_hmac_access_key_id" {
  description = "COS HMAC access key ID for S3 API access."
  value       = nonsensitive(ibm_resource_key.cos.credentials["cos_hmac_keys.access_key_id"])
}

output "cos_hmac_secret_access_key" {
  description = "COS HMAC secret access key for S3 API access."
  value       = nonsensitive(ibm_resource_key.cos.credentials["cos_hmac_keys.secret_access_key"])
}

output "cos_s3_endpoint_public" {
  description = "COS S3 public endpoint."
  value       = ibm_cos_bucket.tfe.s3_endpoint_public
}

output "region" {
  description = "IBM Cloud region used for the COS bucket."
  value       = var.region
}

# PostgreSQL (IBM Cloud Databases)
output "postgres_hostname" {
  description = "PostgreSQL hostname."
  value       = local.postgres_hostname
}

output "postgres_port" {
  description = "PostgreSQL port."
  value       = local.postgres_port
}

output "postgres_tfe_username" {
  description = "PostgreSQL TFE username."
  value       = nonsensitive(local.postgres_username)
}

output "postgres_tfe_password" {
  description = "PostgreSQL TFE password."
  value       = nonsensitive(local.postgres_password)
}

# Redis (IBM Cloud Databases)
output "redis_hostname" {
  description = "Redis hostname."
  value       = local.redis_host
}

output "redis_port" {
  description = "Redis port."
  value       = local.redis_port
}

output "redis_username" {
  description = "Redis TFE username."
  value       = nonsensitive(local.redis_username)
}

output "redis_password_base64" {
  description = "Redis TFE password (plain text despite the name, as returned by IBM Cloud Databases)."
  value       = nonsensitive(local.redis_pass_base64)
}

output "redis_certificate_base64" {
  description = "Redis certificate in base64 format."
  value       = nonsensitive(local.redis_certificate_b64)
}

# IKS Cluster
output "iks_cluster_ingress_hostname" {
  description = "Ingress subdomain of the IKS cluster."
  value       = ibm_container_vpc_cluster.iks.ingress_hostname
}
