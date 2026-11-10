terraform {
  required_providers {
    # minikube = {
    #   source = "scott-the-programmer/minikube"
    #   version = "0.5.3"
    # }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.0.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
    }
    tls = {
      source = "hashicorp/tls"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}

provider "kubernetes" {
  config_path    = var.kubectl_config_path
  config_context = data.terraform_remote_state.infra.outputs.kubeconfig_context
}

provider "helm" {
  kubernetes = {
    config_path    = var.kubectl_config_path
    config_context = data.terraform_remote_state.infra.outputs.kubeconfig_context
  }
}
