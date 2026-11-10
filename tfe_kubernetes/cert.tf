## Self-signed certificate for the Terraform Enterprise pod.
# TFE needs a certificate for TFE_HOSTNAME to start. Public traffic goes through the IKS Ingress (Traefik), which
# presents the IBM wildcard certificate and re-encrypts to the pod. The Ingress does not verify this certificate
# (see ingress.tf), so a self-signed certificate is enough.
resource "tls_private_key" "tfe" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "tfe" {
  private_key_pem = tls_private_key.tfe.private_key_pem

  subject {
    common_name = local.fqdn
  }

  dns_names             = [local.fqdn, "admin-${local.fqdn}"]
  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# save private key and cert to files
resource "local_file" "private_key" {
  content  = tls_private_key.tfe.private_key_pem
  filename = "${path.module}/certs/private_key.pem"
}

resource "local_file" "cert" {
  content  = tls_self_signed_cert.tfe.cert_pem
  filename = "${path.module}/certs/cert.pem"
}
