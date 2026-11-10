########################################################################################################################
# OpenShift Routes
#
# The terraform-enterprise Helm chart does not create Routes. One Route per hostname is created here:
# - TLS is terminated by the OpenShift router with its default certificate (the IBM wildcard certificate of the
#   cluster Ingress subdomain), so no certificate has to be copied into the namespace.
# - The router re-encrypts to the TFE pod, which serves HTTPS with a self-signed certificate. The router verifies that
#   certificate with destinationCACertificate, and checks that it is valid for <service>.<namespace>.svc (see cert.tf).
########################################################################################################################

locals {
  routes = {
    tfe = {
      host        = local.fqdn
      target_port = "https-port"
    }
    tfe-admin = {
      host        = "admin-${local.fqdn}"
      target_port = "admin-https-port"
    }
  }
}

resource "kubernetes_manifest" "tfe_route" {
  for_each = local.routes

  manifest = {
    apiVersion = "route.openshift.io/v1"
    kind       = "Route"
    metadata = {
      name      = each.key
      namespace = var.namespace
    }
    spec = {
      host = each.value.host
      to = {
        kind   = "Service"
        name   = local.tfe_service_name
        weight = 100
      }
      port = {
        targetPort = each.value.target_port
      }
      tls = {
        termination                   = "reencrypt"
        insecureEdgeTerminationPolicy = "Redirect"
        destinationCACertificate      = tls_self_signed_cert.tfe.cert_pem
      }
      wildcardPolicy = "None"
    }
  }

  depends_on = [kubernetes_namespace_v1.terraform_enterprise]
}
