########################################################################################################################
# IKS (IBM Kubernetes Service) VPC Cluster
########################################################################################################################

resource "ibm_container_vpc_cluster" "iks" {
  name              = "${var.environment_prefix}-iks"
  vpc_id            = ibm_is_vpc.vpc.id
  resource_group_id = local.resource_group_id
  flavor            = var.worker_machine_type
  worker_count      = var.workers_per_zone
  kube_version      = var.kube_version == "default" ? null : var.kube_version
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
# IKS Cluster Config (admin kubeconfig details)
########################################################################################################################

data "ibm_container_cluster_config" "iks" {
  cluster_name_id   = ibm_container_vpc_cluster.iks.id
  resource_group_id = local.resource_group_id
  admin             = true
}

locals {
  iks_kubeconfig = yamlencode({
    apiVersion        = "v1"
    kind              = "Config"
    "current-context" = ibm_container_vpc_cluster.iks.name
    clusters = [{
      name = ibm_container_vpc_cluster.iks.name
      cluster = {
        server                       = data.ibm_container_cluster_config.iks.host
        "certificate-authority-data" = base64encode(data.ibm_container_cluster_config.iks.ca_certificate)
      }
    }]
    users = [{
      name = "${ibm_container_vpc_cluster.iks.name}-admin"
      user = {
        "client-certificate-data" = base64encode(data.ibm_container_cluster_config.iks.admin_certificate)
        "client-key-data"         = base64encode(data.ibm_container_cluster_config.iks.admin_key)
      }
    }]
    contexts = [{
      name = ibm_container_vpc_cluster.iks.name
      context = {
        cluster = ibm_container_vpc_cluster.iks.name
        user    = "${ibm_container_vpc_cluster.iks.name}-admin"
      }
    }]
  })
}

resource "local_file" "iks_kubeconfig" {
  content  = local.iks_kubeconfig
  filename = "${path.module}/../kubeconfig/config.yaml"
}

########################################################################################################################
# IKS Agent Worker Pool
########################################################################################################################

resource "ibm_container_vpc_worker_pool" "agent" {
  cluster           = ibm_container_vpc_cluster.iks.id
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
