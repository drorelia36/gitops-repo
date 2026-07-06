resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  version          = "6.0.0"
  create_namespace = false

  set {
    name  = "server.insecure"
    value = "true"
  }

  values = [
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.argocd]
}

output "argocd_url" {
  value = "https://34.169.226.197"
}

# GitHub Token Variable
variable "github_token" {
  description = "GitHub Personal Access Token for Argo CD"
  type        = string
  sensitive   = true
}

# GitHub Repository Secret for Argo CD
resource "kubernetes_secret" "github_repo" {
  metadata {
    name      = "github-repo-creds"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "git"
    url      = "https://github.com/drorelia36/gitops-repo.git"
    username = "oauth2"
    password = var.github_token
  }

  depends_on = [kubernetes_namespace.argocd]
}
