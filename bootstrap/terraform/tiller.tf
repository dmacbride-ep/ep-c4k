resource "kubernetes_deployment" "tiller_deploy" {
  depends_on = [kubernetes_service.tiller_deploy, kubernetes_service_account.tiller, kubernetes_cluster_role_binding.tiller, azurerm_kubernetes_cluster.hub]

  metadata {
    name      = "tiller-deploy"
    namespace = "kube-system"
    labels    = { app = "helm", name = "tiller" }
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "helm", name = "tiller" }
    }
    template {
      metadata {
        labels = { app = "helm", name = "tiller" }
      }
      spec {
        container {
          name  = "tiller"
          image = "gcr.io/kubernetes-helm/tiller:v2.15.1"
          port {
            name           = "tiller"
            container_port = 44134
          }
          port {
            name           = "http"
            container_port = 44135
          }
          env {
            name  = "TILLER_NAMESPACE"
            value = "kube-system"
          }
          env {
            name  = "TILLER_HISTORY_MAX"
            value = "0"
          }
          resources {
            limits {
              memory = "128Mi"
              cpu    = "100m"
            }
            requests {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
          liveness_probe {
            http_get {
              path = "/liveness"
              port = "44135"
            }
            initial_delay_seconds = 1
            timeout_seconds       = 1
          }
          readiness_probe {
            http_get {
              path = "/readiness"
              port = "44135"
            }
            initial_delay_seconds = 1
            timeout_seconds       = 1
          }
          image_pull_policy = "IfNotPresent"
        }
        automount_service_account_token = true
        service_account_name            = "terraform-tiller"
      }
    }
  }
}

resource "kubernetes_service" "tiller_deploy" {
  metadata {
    name      = "tiller-deploy"
    namespace = "kube-system"
    labels    = { app = "helm", name = "tiller" }
  }
  spec {
    port {
      name        = "tiller"
      port        = 44134
      target_port = "tiller"
    }
    selector = { app = "helm", name = "tiller" }
    type     = "ClusterIP"
  }
}

resource "kubernetes_service_account" "tiller" {
  count      = terraform.workspace == "bootstrap" ? 1 : 0
  depends_on = [azurerm_kubernetes_cluster.hub]

  metadata {
    name      = "terraform-tiller"
    namespace = "kube-system"
  }

  automount_service_account_token = true
}

resource "kubernetes_cluster_role_binding" "tiller" {
  count      = terraform.workspace == "bootstrap" ? 1 : 0
  depends_on = [kubernetes_service_account.tiller]

  metadata {
    name = "terraform-tiller"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind = "ServiceAccount"
    name = "terraform-tiller"

    api_group = ""
    namespace = "kube-system"
  }
}
