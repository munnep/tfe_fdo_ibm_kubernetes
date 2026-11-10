########################################################################################################################
# VPC Cluster: IKS (IBM Kubernetes Service) or Red Hat OpenShift on IBM Cloud, selected with var.openshift
#
# Both flavours use the same resource. OpenShift differs only in that the version ends in "_openshift" and the cluster
# needs a COS instance to back up its internal image registry.
########################################################################################################################

locals {
  cluster_type = var.openshift ? "openshift" : "kubernetes"
  cluster_name = "${var.environment_prefix}-${var.openshift ? "openshift" : "iks"}"

  # OpenShift needs at least 2 workers in the default pool (two router replicas), the separate agent pool does not count.
  default_pool_worker_count = var.openshift ? max(var.workers_per_zone, 2) : var.workers_per_zone
}

resource "ibm_container_vpc_cluster" "cluster" {
  name              = local.cluster_name
  vpc_id            = ibm_is_vpc.vpc.id
  resource_group_id = local.resource_group_id
  flavor            = var.worker_machine_type
  worker_count      = local.default_pool_worker_count
  kube_version      = var.openshift ? var.openshift_version : (var.kube_version == "default" ? null : var.kube_version)
  cos_instance_crn  = var.openshift ? ibm_resource_instance.cos.crn : null
  tags              = ["terraform-enterprise"]

  zones {
    subnet_id = ibm_is_subnet.subnet.id
    name      = local.zone
  }

  worker_labels = var.worker_labels

  wait_for_worker_update              = true
  force_delete_storage                = false
  disable_public_service_endpoint     = false
  disable_outbound_traffic_protection = var.disable_outbound_traffic_protection
}

########################################################################################################################
# Cluster Config (admin kubeconfig details)
########################################################################################################################

data "ibm_container_cluster_config" "cluster" {
  cluster_name_id   = ibm_container_vpc_cluster.cluster.id
  resource_group_id = local.resource_group_id
  admin             = true
}

locals {
  # IKS authenticates the admin with a client certificate, OpenShift with a (short-lived) token.
  kubeconfig_user = var.openshift ? tomap({
    token = data.ibm_container_cluster_config.cluster.token
    }) : tomap({
    "client-certificate-data" = base64encode(data.ibm_container_cluster_config.cluster.admin_certificate)
    "client-key-data"         = base64encode(data.ibm_container_cluster_config.cluster.admin_key)
  })

  # The OpenShift API endpoint can be signed by a public CA, in which case no CA bundle is returned.
  kubeconfig_ca = data.ibm_container_cluster_config.cluster.ca_certificate == "" ? tomap({}) : tomap({
    "certificate-authority-data" = base64encode(data.ibm_container_cluster_config.cluster.ca_certificate)
  })

  kubeconfig = yamlencode({
    apiVersion        = "v1"
    kind              = "Config"
    "current-context" = local.cluster_name
    clusters = [{
      name    = local.cluster_name
      cluster = merge({ server = data.ibm_container_cluster_config.cluster.host }, local.kubeconfig_ca)
    }]
    users = [{
      name = "${local.cluster_name}-admin"
      user = local.kubeconfig_user
    }]
    contexts = [{
      name = local.cluster_name
      context = {
        cluster = local.cluster_name
        user    = "${local.cluster_name}-admin"
      }
    }]
  })
}

resource "local_file" "kubeconfig" {
  content  = local.kubeconfig
  filename = "${path.module}/../kubeconfig/config.yaml"
}

########################################################################################################################
# Agent Worker Pool
########################################################################################################################

resource "ibm_container_vpc_worker_pool" "agent" {
  cluster           = ibm_container_vpc_cluster.cluster.id
  worker_pool_name  = "${var.environment_prefix}-agent"
  flavor            = "bx2.4x16"
  vpc_id            = ibm_is_vpc.vpc.id
  worker_count      = 1
  resource_group_id = local.resource_group_id
  labels            = {}

  zones {
    subnet_id = ibm_is_subnet.subnet.id
    name      = local.zone
  }
}
