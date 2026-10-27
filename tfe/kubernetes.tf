# Create a namespace
resource "kubernetes_namespace_v1" "terraform_enterprise" {
  metadata {
    name = var.namespace
  }
}