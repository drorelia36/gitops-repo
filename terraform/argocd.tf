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
