locals {
  # IBM-provided Ingress subdomain of the OpenShift cluster (from the infra state). IBM registers a wildcard DNS record
  # for it and the default OpenShift router (openshift-ingress) already serves the IBM wildcard certificate for it, so
  # any single label below it resolves and is covered by a valid certificate.
  ingress_hostname = data.terraform_remote_state.infra.outputs.cluster_ingress_hostname

  fqdn = "${var.route53_subdomain}.${local.ingress_hostname}"

  # The Helm chart hard-codes this Service name, whatever the release name is.
  tfe_service_name = "terraform-enterprise"
}
