# General outputs (container specific outputs are in their respective files)

# output "minikube_tunnel" {
#   value = "sudo minikube tunnel --profile=tfe"
# }

# output "minikube_delete_cluster" {
#   value = "minikube delete --profile=tfe"
# }

# output "grafana_url" {
#   value = var.enable_monitoring ? "https://grafana-${local.fqdn}" : "monitoring disabled"
# }

output "kubeconfig_export" {
  description = "Command to point kubectl at the cluster used by this configuration."
  value       = "export KUBECONFIG=${abspath(var.kubectl_config_path)}"
}

