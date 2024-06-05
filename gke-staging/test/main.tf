# Configure Helm provider for Kubernetes 
# (Windows Deployment)
provider "helm" {
  kubernetes {
    config_path = file("C:\\Users\\PC\\.kube\\config")
  }
}

# (Linux Deployment)
# provider "helm" {
#   kubernetes {
#     config_path = file("${pathexpand("~")}/.kube/config")
#   }
# }


# Install Argo CD using Helm
resource "helm_release" "argo_cd" {
  name       = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "6.5.1"
  namespace  = "argo-cd"
}