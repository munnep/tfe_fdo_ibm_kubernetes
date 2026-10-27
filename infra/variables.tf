########################################################################################################################
# Input Variables
########################################################################################################################

variable "environment_prefix" {
  type        = string
  description = "the naming convention for everything created"
}

variable "ibmcloud_api_key" {
  type        = string
  description = "IBM Cloud API key. Prefer setting env var IC_API_KEY instead of putting it in a file."
  sensitive   = true
  default     = null
}

variable "ibmcloud_provider_visibility" {
  type        = string
  description = "IBM Cloud provider visibility setting."
  default     = "public"
}

variable "region" {
  type        = string
  description = "Region where resources are created"
  default     = "eu-de"
}

variable "resource_tags" {
  type        = list(string)
  description = "Optional list of tags to be added to created resources"
  default     = []
}

variable "access_tags" {
  type        = list(string)
  description = "Optional list of access tags to be added to created resources"
  default     = []
}

########################################################################################################################
# PostgreSQL (IBM Cloud Databases)
########################################################################################################################

variable "postgres_deletion_protection" {
  type        = bool
  description = "Enable deletion protection within terraform."
  default     = false
}

variable "postgres_members" {
  type        = number
  description = "Number of members (nodes) for the PostgreSQL cluster. 2 = HA with 2 zones, 3 = HA with 3 zones (recommended for production)."
  default     = 2

}

########################################################################################################################
# Redis (IBM Cloud Databases)
########################################################################################################################

variable "redis_deletion_protection" {
  type        = bool
  description = "Enable deletion protection for Redis instance."
  default     = false
}

variable "redis_version" {
  type        = string
  description = "Redis version to deploy."
  default     = "8.2"
}

########################################################################################################################
# IKS Cluster
########################################################################################################################

variable "kube_version" {
  type        = string
  description = "Kubernetes version for the IKS cluster. Use 'default' to get the current IBM Cloud default."
  default     = "default"
}

variable "worker_machine_type" {
  type        = string
  description = "Flavor (machine type) for the default worker pool nodes."
  default     = "bx2.4x16"
}

variable "workers_per_zone" {
  type        = number
  description = "Number of worker nodes per zone in the default worker pool."
  default     = 1
}

variable "worker_labels" {
  type        = map(string)
  description = "Optional labels to apply to the default worker pool nodes."
  default     = {}
}

variable "disable_outbound_traffic_protection" {
  type        = bool
  description = "Allow outbound connections from IKS worker nodes to public internet destinations."
  default     = true
}
