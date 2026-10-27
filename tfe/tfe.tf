data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "${path.module}/../infra/terraform.tfstate"
  }
}

locals {
  effective_registry_url      = var.tfe_beta_release ? var.beta_registry_images_url : var.registry_images_url
  effective_registry_username = var.tfe_beta_release ? var.tfe_beta_release_user : var.registry_username
  effective_registry_password = var.tfe_beta_release ? var.tfe_beta_release_password : var.tfe_raw_license

  # Database settings from infra state
  pg_host     = data.terraform_remote_state.infra.outputs.postgres_hostname
  pg_port     = data.terraform_remote_state.infra.outputs.postgres_port
  pg_user     = data.terraform_remote_state.infra.outputs.postgres_tfe_username
  pg_password = data.terraform_remote_state.infra.outputs.postgres_tfe_password

  # Object storage (COS) settings from infra state
  cos_bucket_name       = data.terraform_remote_state.infra.outputs.cos_bucket_name
  cos_access_key_id     = data.terraform_remote_state.infra.outputs.cos_hmac_access_key_id
  cos_secret_access_key = data.terraform_remote_state.infra.outputs.cos_hmac_secret_access_key
  cos_endpoint          = "https://${data.terraform_remote_state.infra.outputs.cos_s3_endpoint_public}"
  cos_region            = data.terraform_remote_state.infra.outputs.region

  # Redis settings from infra state
  redis_host = data.terraform_remote_state.infra.outputs.redis_hostname
  redis_port = data.terraform_remote_state.infra.outputs.redis_port
  redis_user = data.terraform_remote_state.infra.outputs.redis_username
  # IBM Cloud Databases returns a plain-text password despite the output name.
  redis_password           = data.terraform_remote_state.infra.outputs.redis_password_base64
  redis_certificate_b64    = data.terraform_remote_state.infra.outputs.redis_certificate_base64
  redis_certificate_decode = base64decode(data.terraform_remote_state.infra.outputs.redis_certificate_base64)
  redis_use_auth           = true
  redis_use_tls            = true
}

resource "kubernetes_secret_v1" "terraform-enterprise" {
  metadata {
    name      = "terraform-enterprise"
    namespace = kubernetes_namespace_v1.terraform_enterprise.metadata.0.name
  }
  type = "kubernetes.io/dockerconfigjson"
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        (local.effective_registry_url) = {
          "username" = local.effective_registry_username
          "password" = local.effective_registry_password
          "auth"     = base64encode("${local.effective_registry_username}:${local.effective_registry_password}")
        }
      }
    })
  }
}


resource "helm_release" "tfe" {
  name       = "${var.tag_prefix}-tfe"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "terraform-enterprise"
  # chart           = "/Users/patrick/git/TFE/terraform-enterprise-helm2"
  namespace       = kubernetes_namespace_v1.terraform_enterprise.metadata.0.name
  version         = var.tfe_helm_chart_version
  cleanup_on_fail = true

  values = [
    templatefile("${path.module}/overrides.yaml", {
      tag_prefix       = var.tag_prefix
      replica_count    = var.replica_count
      enc_password     = var.tfe_encryption_password
      pg_dbname        = var.postgres_db
      pg_user          = local.pg_user
      pg_password      = local.pg_password
      pg_address       = "${local.pg_host}:${local.pg_port}"
      fqdn             = local.fqdn
      s3_bucket        = local.cos_bucket_name
      s3_region        = local.cos_region
      s3_bucket_key    = local.cos_access_key_id
      s3_bucket_secret = local.cos_secret_access_key
      s3_endpoint      = local.cos_endpoint
      cert_data        = base64encode(tls_self_signed_cert.tfe.cert_pem)
      key_data         = base64encode(nonsensitive(tls_private_key.tfe.private_key_pem))
      # TFE trusts its own self-signed certificate plus the Redis CA
      ca_cert_data          = base64encode("${tls_self_signed_cert.tfe.cert_pem}${local.redis_certificate_decode}")
      redis_host            = local.redis_host
      redis_port            = local.redis_port
      redis_user            = local.redis_user
      redis_password        = local.redis_password
      redis_use_auth        = local.redis_use_auth
      redis_use_tls         = local.redis_use_tls
      redis_certificate_b64 = local.redis_certificate_b64
      tfe_license           = var.tfe_raw_license
      tfe_release           = var.release_sequence
      tfe_beta_release      = var.tfe_beta_release
      registry_images_url   = local.effective_registry_url
      namespace             = kubernetes_namespace_v1.terraform_enterprise.metadata.0.name
      ingress_class         = "public-iks-traefik"
      ingress_tls_secret    = kubernetes_secret_v1.ingress_tls.metadata.0.name
      servers_transport     = local.servers_transport_ref
    })
  ]

  depends_on = [kubernetes_job_v1.postgres_extensions, kubernetes_manifest.tfe_servers_transport]

  timeout = var.tfe_helm_release_timeout
}

output "tfe_execute_script_to_create_user_admin" {
  value = "./scripts/configure_tfe.sh ${local.fqdn} ${var.admin_email} ${var.admin_username} ${var.admin_password}"
}

output "tfe_url" {
  value = "https://${local.fqdn}"
}

output "tfe_admin_console" {
  value = "https://admin-${local.fqdn}"
}