########################################################################################################################
# PostgreSQL extensions
#
# The IBM Cloud PostgreSQL instance only has a private endpoint, so the extensions are created by a Kubernetes Job
# that runs inside the cluster (which can reach the private endpoint). The Helm release waits for this Job.
########################################################################################################################

locals {
  postgres_extensions       = ["citext", "hstore", "pg_stat_statements", "uuid-ossp"]
  postgres_extension_schema = "ibm_extension"
}

resource "kubernetes_secret_v1" "postgres_extensions" {
  metadata {
    name      = "postgres-extensions"
    namespace = kubernetes_namespace_v1.terraform_enterprise.metadata.0.name
  }

  data = {
    PGHOST     = local.pg_host
    PGPORT     = tostring(local.pg_port)
    PGUSER     = local.pg_user
    PGPASSWORD = local.pg_password
    PGDATABASE = var.postgres_db
  }
}

resource "kubernetes_job_v1" "postgres_extensions" {
  metadata {
    name      = "postgres-extensions"
    namespace = kubernetes_namespace_v1.terraform_enterprise.metadata.0.name
  }

  spec {
    backoff_limit = 6

    template {
      metadata {
        labels = {
          app = "postgres-extensions"
        }
      }

      spec {
        restart_policy = "OnFailure"

        container {
          name  = "psql"
          image = var.image_postgres

          command = ["/bin/sh", "-c"]
          args = [
            join(" && ", [
              for ext in local.postgres_extensions :
              "psql -v ON_ERROR_STOP=1 -c 'CREATE EXTENSION IF NOT EXISTS \"${ext}\" SCHEMA ${local.postgres_extension_schema};'"
            ])
          ]

          env {
            name  = "PGSSLMODE"
            value = "require"
          }
          env {
            name  = "PGCONNECT_TIMEOUT"
            value = "15"
          }

          env_from {
            secret_ref {
              name = kubernetes_secret_v1.postgres_extensions.metadata.0.name
            }
          }
        }
      }
    }
  }

  wait_for_completion = true

  timeouts {
    create = "5m"
    update = "5m"
  }
}
