########################################################################################################################
# Ingress (IBM managed Traefik, class public-iks-traefik)
#
# - TLS at the Ingress uses the IBM wildcard certificate of the cluster Ingress subdomain. IBM keeps it in the
#   "default" namespace; an Ingress can only use a secret from its own namespace, so it is copied here.
# - The TFE pod serves HTTPS with a self-signed certificate, so Traefik is told to talk HTTPS to the pod and not to
#   verify that certificate (ServersTransport with insecureSkipVerify).
########################################################################################################################

locals {
  ingress_tls_secret_name = "tfe-ingress-tls"
  servers_transport_name  = "tfe-transport"
  # Traefik reference format for a CRD in another provider: <namespace>-<name>@kubernetescrd
  servers_transport_ref = "${var.namespace}-${local.servers_transport_name}@kubernetescrd"
}

data "kubernetes_secret_v1" "iks_wildcard" {
  metadata {
    name      = local.iks_ingress_secret_name
    namespace = "default"
  }
}

resource "kubernetes_secret_v1" "ingress_tls" {
  metadata {
    name      = local.ingress_tls_secret_name
    namespace = kubernetes_namespace_v1.terraform_enterprise.metadata.0.name
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = data.kubernetes_secret_v1.iks_wildcard.data["tls.crt"]
    "tls.key" = data.kubernetes_secret_v1.iks_wildcard.data["tls.key"]
  }
}

resource "kubernetes_manifest" "tfe_servers_transport" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "ServersTransport"
    metadata = {
      name      = local.servers_transport_name
      namespace = var.namespace
    }
    spec = {
      insecureSkipVerify = true
    }
  }

  depends_on = [kubernetes_namespace_v1.terraform_enterprise]
}
