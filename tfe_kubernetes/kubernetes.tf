# Create a namespace
resource "kubernetes_namespace_v1" "terraform_enterprise" {
  metadata {
    name = var.namespace
  }

  lifecycle {
    precondition {
      condition     = data.terraform_remote_state.infra.outputs.cluster_type == "kubernetes"
      error_message = "The infra stage created an OpenShift cluster. Use ../tfe_openshift, or set openshift = false in ../infra and apply it."
    }
  }
}
