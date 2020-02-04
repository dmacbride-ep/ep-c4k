#####
# install the Kubernetes Dashboard
#####

resource "kubernetes_secret" "kubernetes-dashboard-certs" {
  count = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0

  metadata {
    name      = "kubernetes-dashboard-certs"
    namespace = "kube-system"
    labels = {
      "k8s-app" = "kubernetes-dashboard"
    }
  }
  type = "Opaque"
}

resource "kubernetes_service_account" "kubernetes-dashboard" {
  count = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0

  metadata {
    name      = "kubernetes-dashboard"
    namespace = "kube-system"
    labels = {
      "k8s-app" = "kubernetes-dashboard"
    }
  }
  automount_service_account_token = true
}

resource "kubernetes_role" "kubernetes-dashboard-minimal" {
  count = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0

  metadata {
    name      = "kubernetes-dashboard-minimal"
    namespace = "kube-system"
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create"]
  }
  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["create"]
  }
  rule {
    api_groups     = [""]
    resources      = ["secrets"]
    resource_names = ["kubernetes-dashboard-key-holder", "kubernetes-dashboard-certs"]
    verbs          = ["get", "update", "delete"]
  }
  rule {
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["kubernetes-dashboard-settings"]
    verbs          = ["get", "update"]
  }
  rule {
    api_groups     = [""]
    resources      = ["services"]
    resource_names = ["heapster"]
    verbs          = ["proxy"]
  }
  rule {
    api_groups     = [""]
    resources      = ["services/proxy"]
    resource_names = ["heapster", "http:heapster:", "https:heapster:"]
    verbs          = ["get"]
  }
}

resource "kubernetes_role_binding" "kubernetes-dashboard" {
  count      = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0
  depends_on = [kubernetes_service_account.kubernetes-dashboard, kubernetes_role.kubernetes-dashboard-minimal]

  metadata {
    name      = "kubernetes-dashboard-minimal"
    namespace = "kube-system"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "kubernetes-dashboard-minimal"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "kubernetes-dashboard"
    namespace = "kube-system"
  }
}

resource "kubernetes_deployment" "kubernetes-dashboard" {
  count      = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0
  depends_on = [kubernetes_role_binding.kubernetes-dashboard, kubernetes_secret.kubernetes-dashboard-certs]

  metadata {
    name      = "kubernetes-dashboard"
    namespace = "kube-system"
    labels = {
      "k8s-app" = "kubernetes-dashboard"
    }
  }
  spec {
    replicas               = 1
    revision_history_limit = 10
    selector {
      match_labels = {
        "k8s-app" = "kubernetes-dashboard"
      }
    }
    template {
      metadata {
        labels = {
          "k8s-app" = "kubernetes-dashboard"
        }
      }
      spec {
        service_account_name = "kubernetes-dashboard"
        container {
          name  = "kubernetes-dashboard"
          image = "k8s.gcr.io/kubernetes-dashboard-amd64:v1.10.1"
          port {
            container_port = "8443"
            protocol       = "TCP"
          }
          args = ["--auto-generate-certificates"]
          liveness_probe {
            http_get {
              scheme = "HTTPS"
              path   = "/"
              port   = 8443
            }
            initial_delay_seconds = 30
            period_seconds        = 30
          }
          volume_mount {
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            name       = kubernetes_service_account.kubernetes-dashboard[0].default_secret_name
            read_only  = true
          }
          volume_mount {
            name       = "kubernetes-dashboard-certs"
            mount_path = "/certs"
          }
          volume_mount {
            name       = "tmp-volume"
            mount_path = "/tmp"
          }
        }
        dns_config {
          option {
            name = "single-request-reopen"
          }
          option {
            name = "timeout"
            value = 3
          }
          option {
            name = "attempts"
            value = 3
          }
        }
        volume {
          name = kubernetes_service_account.kubernetes-dashboard[0].default_secret_name
          secret {
            secret_name = kubernetes_service_account.kubernetes-dashboard[0].default_secret_name
          }
        }
        volume {
          name = "kubernetes-dashboard-certs"
          secret {
            secret_name = "kubernetes-dashboard-certs"
          }
        }
        volume {
          name = "tmp-volume"
          empty_dir {}
        }
      }
    }
  }

  timeouts {
    create = "2m"
    delete = "2m"
    update = "2m"
  }
}

resource "kubernetes_service" "kubernetes-dashboard" {
  count = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0

  metadata {
    name      = "kubernetes-dashboard"
    namespace = "kube-system"
    labels = {
      "k8s-app" = "kubernetes-dashboard"
    }
  }
  spec {
    selector = {
      "k8s-app" = "kubernetes-dashboard"
    }
    port {
      port        = 443
      target_port = 8443
    }
  }
}

#####
# ensure that Kubernetes Dashboard users can operate on the cluster
#####

resource "kubernetes_service_account" "eks-admin" {
  count = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0

  metadata {
    name      = "eks-admin"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "eks-admin" {
  count      = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0
  depends_on = [kubernetes_service_account.eks-admin]

  metadata {
    name = "eks-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "eks-admin"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "kubernetes-dashboard" {
  count      = (var.cloud == "azure") && (terraform.workspace == "bootstrap") ? 1 : 0
  depends_on = [kubernetes_service_account.kubernetes-dashboard]

  metadata {
    name = "kubernetes-dashboard"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "kubernetes-dashboard"
    namespace = "kube-system"
  }
}