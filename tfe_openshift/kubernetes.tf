# Create a namespace
resource "kubernetes_namespace_v1" "terraform_enterprise" {
  metadata {
    name = var.namespace
  }

  lifecycle {
    precondition {
      condition     = data.terraform_remote_state.infra.outputs.cluster_type == "openshift"
      error_message = "The infra stage created a plain Kubernetes (IKS) cluster. Set openshift = true in ../infra and apply it, or use ../tfe_kubernetes instead of ../tfe_openshift."
    }
    ignore_changes = [ metadata ]
  }
}
