# General outputs (container specific outputs are in their respective files)

output "kubeconfig_export" {
  description = "Command to point kubectl / oc at the cluster used by this configuration."
  value       = "export KUBECONFIG=${abspath(var.kubectl_config_path)}"
}
