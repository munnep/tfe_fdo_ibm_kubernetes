locals {
  # IBM-provided Ingress subdomain of the IKS cluster (from the infra state). IBM registers a wildcard DNS record and a
  # wildcard TLS certificate for it, so any single label below it resolves and is covered by the certificate.
  iks_ingress_hostname = data.terraform_remote_state.infra.outputs.iks_cluster_ingress_hostname

  # The IBM wildcard certificate secret is named after the first label of the Ingress subdomain.
  iks_ingress_secret_name = split(".", local.iks_ingress_hostname)[0]

  fqdn = "${var.route53_subdomain}.${local.iks_ingress_hostname}"
}
