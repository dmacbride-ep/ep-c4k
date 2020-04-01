resource "kubernetes_service_account" "cluster-autoscaler" {
  count = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0

  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "k8s-app"   = "cluster-autoscaler"
    }
  }
}

data "external" "cluster_autoscaler_version" {
  count = "${(var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0}"

  program = ["bash", "./find-latest-cluster-autoscaler-version.sh"]

  query = {
    kubernetes_version = "${var.kubernetes_version}"
  }
}

resource "kubernetes_cluster_role" "cluster-autoscaler" {
  count = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0

  metadata {
    name = "cluster-autoscaler"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "k8s-app"   = "cluster-autoscaler"
    }
  }
  rule {
    api_groups = [""]
    resources  = ["namespaces", "pods"]
    verbs      = ["get", "list", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["events", "endpoints"]
    verbs      = ["create", "patch"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods/eviction"]
    verbs      = ["create"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods/status"]
    verbs      = ["update"]
  }
  rule {
    api_groups     = [""]
    resources      = ["endpoints"]
    resource_names = ["cluster-autoscaler"]
    verbs          = ["get", "update"]
  }
  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["watch", "list", "get", "update"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "services", "replicationcontrollers", "persistentvolumeclaims", "persistentvolumes"]
    verbs      = ["watch", "list", "get"]
  }
  rule {
    api_groups = ["extensions"]
    resources  = ["replicasets", "daemonsets"]
    verbs      = ["watch", "list", "get"]
  }
  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
    verbs      = ["watch", "list"]
  }
  rule {
    api_groups = ["apps"]
    resources  = ["statefulsets", "replicasets", "daemonsets"]
    verbs      = ["watch", "list", "get"]
  }
  rule {
    api_groups = ["batch"]
    resources  = ["jobs"]
    verbs      = ["watch", "list", "get"]
  }
  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses"]
    verbs      = ["watch", "list", "get"]
  }
}

resource "kubernetes_role" "cluster-autoscaler" {
  count = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0

  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "k8s-app"   = "cluster-autoscaler"
    }
  }
  rule {
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["cluster-autoscaler-status"]
    verbs          = ["delete", "get", "update"]
  }
  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["create"]
  }
}

resource "kubernetes_cluster_role_binding" "cluster-autoscaler" {
  count      = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0
  depends_on = [kubernetes_service_account.cluster-autoscaler, kubernetes_cluster_role.cluster-autoscaler]

  metadata {
    name = "cluster-autoscaler"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "k8s-app"   = "cluster-autoscaler"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-autoscaler"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "cluster-autoscaler"
    namespace = "kube-system"
  }
}

resource "kubernetes_role_binding" "cluster-autoscaler" {
  count      = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0
  depends_on = [kubernetes_service_account.cluster-autoscaler, kubernetes_role.cluster-autoscaler]

  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "k8s-app"   = "cluster-autoscaler"
    }
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "cluster-autoscaler"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "cluster-autoscaler"
    namespace = "kube-system"
  }
}

resource "kubernetes_deployment" "cluster-autoscaler" {
  count      = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0
  depends_on = [kubernetes_cluster_role_binding.cluster-autoscaler, kubernetes_role_binding.cluster-autoscaler]

  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      "app" = "cluster-autoscaler"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app" = "cluster-autoscaler"
      }
    }
    template {
      metadata {
        annotations = {
          "iam.amazonaws.com/role" = "role"
        }
        labels = {
          "app" = "cluster-autoscaler"
        }
      }
      spec {
        service_account_name = "cluster-autoscaler"
        container {
          image = "us.gcr.io/k8s-artifacts-prod/autoscaling/cluster-autoscaler:v${data.external.cluster_autoscaler_version[0].result["cluster_autoscaler_version"]}"
          name  = "cluster-autoscaler"
          resources {
            limits {
              cpu    = "100m"
              memory = "300Mi"
            }
            requests {
              cpu    = "100m"
              memory = "300Mi"
            }
          }
          command = [
            "./cluster-autoscaler",
            "--v=4",
            "--stderrthreshold=info",
            "--cloud-provider=aws",
            "--skip-nodes-with-local-storage=false",
            "--expander=least-waste",
            "--expendable-pods-priority-cutoff=-10",
            "--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/${var.kubernetes_cluster_name}"
          ]
          env {
            name  = "AWS_REGION"
            value = var.aws_region
          }
          volume_mount {
            name       = "ssl-certs"
            mount_path = "/etc/ssl/certs/ca-bundle.crt"
            read_only  = true
          }
          volume_mount {
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            name       = kubernetes_service_account.cluster-autoscaler[0].default_secret_name
            read_only  = true
          }
          image_pull_policy = "Always"
        }
        dns_config {
          option {
            name = "single-request-reopen"
          }
          option {
            name  = "timeout"
            value = 3
          }
          option {
            name  = "attempts"
            value = 3
          }
        }
        volume {
          name = "ssl-certs"
          host_path {
            path = "/etc/ssl/certs/ca-bundle.crt"
          }
        }
        volume {
          name = kubernetes_service_account.cluster-autoscaler[0].default_secret_name
          secret {
            secret_name = kubernetes_service_account.cluster-autoscaler[0].default_secret_name
          }
        }
      }
    }
  }
  timeouts {
    create = "3m"
    update = "3m"
    delete = "15s"
  }
}
