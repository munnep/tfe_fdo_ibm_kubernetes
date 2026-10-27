# General
variable "route53_subdomain" {
  description = "Hostname label of TFE. It is placed below the IKS Ingress subdomain (from the infra state)."
  type        = string
}

variable "kubectl_config_path" {
  description = "Path to the kube config file."
  type        = string
  default     = "../kubeconfig/config.yaml"
}

variable "kubectl_context" {
  description = "The context to use within the kube config file."
  type        = string
  default     = "tfe-iks"
}

variable "namespace" {
  description = "Kubernetes namespace to deploy resources into."
  type        = string
  default     = "terraform-enterprise"
}

variable "tag_prefix" {
  description = "Prefix for naming Kubernetes resources."
  type        = string
  default     = "tfe"
}

variable "tfe_helm_chart_version" {
  description = "Version of the terraform-enterprise Helm chart."
  type        = string
  default     = "v2.0.4"
}

# SeaweedFS
variable "seaweedfs_access_key" {
  description = "SeaweedFS access key."
  type        = string
  default     = "admin"
}

variable "seaweedfs_secret_key" {
  description = "SeaweedFS secret key."
  type        = string
  default     = "password"
}

variable "image_seaweedfs" {
  description = "SeaweedFS docker image."
  type        = string
  default     = "docker.io/chrislusf/seaweedfs:4.09"
}

# Postgres (host, port, user and password come from the infra remote state)
variable "postgres_db" {
  description = "Postgres database name."
  type        = string
  default     = "ibmclouddb"
}

variable "postgres_db_explorer" {
  description = "Second Postgres database name."
  type        = string
  default     = "tfe_explorer"
}

variable "image_postgres" {
  description = "Postgres docker image."
  type        = string
  default     = "docker.io/library/postgres:16"
}

variable "image_pgbouncer" {
  description = "PgBouncer docker image."
  type        = string
  default     = "docker.io/edoburu/pgbouncer:v1.25.1-p0"
}

variable "image_haproxy" {
  description = "HAProxy docker image."
  type        = string
  default     = "docker.io/library/haproxy:2.8.18"
}

# Redis
variable "image_redis" {
  description = "Redis docker image."
  type        = string
  default     = "docker.io/library/redis:7"
}

# TFE
variable "tfe_encryption_password" {
  description = "Password used to encrypt TFE data."
  type        = string
}

variable "admin_username" {
  description = "Username for the TFE admin account."
  type        = string
}

variable "admin_email" {
  description = "Email address for the TFE admin account."
  type        = string
}

variable "admin_password" {
  description = "Password for the TFE admin account."
  type        = string
}

variable "release_sequence" {
  description = "Release number of the TFE version you wish to install."
  type        = string
}

variable "registry_username" {
  description = "Username to download docker tfe image."
  type        = string
  default     = "terraform"
}

variable "registry_images_url" {
  description = "URL for the images registry to download docker tfe image."
  type        = string
  default     = "images.releases.hashicorp.com"
}

variable "tfe_raw_license" {
  description = "The raw TFE license string"
  type        = string
}

variable "replica_count" {
  description = "Number of replicas (pods)."
  type        = number
  default     = 1
}


variable "tfe_helm_release_timeout" {
  description = "Timeout for the TFE Helm release."
  type        = number
  default     = 300
}

variable "mcp_service_type" {
  description = "Kubernetes Service type for the MCP server."
  type        = string
  default     = "ClusterIP"
}

variable "mcp_endpoint" {
  description = "HTTP endpoint path exposed by the MCP server."
  type        = string
  default     = "/mcp"
}


variable "tfe_beta_release" {
  description = "trying to install a beta release version"
  type        = bool
  default     = false
}

variable "beta_registry_images_url" {
  description = "URL for the images registry to download docker tfe image."
  type        = string
  default     = "example.com"
}

variable "tfe_beta_release_user" {
  description = "Beta release user for login registry"
  type        = string
  default     = "user1"
}

variable "tfe_beta_release_password" {
  description = "Beta release user for login registry"
  type        = string
  default     = "very_secret"
}

