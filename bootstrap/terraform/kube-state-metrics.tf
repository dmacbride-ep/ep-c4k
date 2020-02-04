locals {
  # this mapping is based on https://github.com/kubernetes/kube-state-metrics#compatibility-matrix
  kube_state_metrics_version = {
    "1.13" = "v1.9.2"
    "1.14" = "v1.9.2"
    "1.15" = "v1.9.2"
    "1.16" = "v1.9.2"
  }

  ksm_version_to_use = local.kube_state_metrics_version[var.kubernetes_version]
}

resource "kubernetes_deployment" "kube_state_metrics" {
  count = var.enable_new_relic_agent && (terraform.workspace == "bootstrap") ? 1 : 0

  metadata {
    name      = "kube-state-metrics"
    namespace = "kube-system"
    labels    = { "app.kubernetes.io/name" = "kube-state-metrics", "app.kubernetes.io/version" = local.ksm_version_to_use }
  }
  spec {
    replicas = 1
    selector {
      match_labels = { "app.kubernetes.io/name" = "kube-state-metrics" }
    }
    template {
      metadata {
        labels = { "app.kubernetes.io/name" = "kube-state-metrics", "app.kubernetes.io/version" = local.ksm_version_to_use }
      }
      spec {
        container {
          name  = "kube-state-metrics"
          image = "quay.io/coreos/kube-state-metrics:${local.ksm_version_to_use}"
          port {
            name           = "http-metrics"
            container_port = 8080
          }
          port {
            name           = "telemetry"
            container_port = 8081
          }
          resources {
            limits {
              cpu    = "100m"
              memory = "200Mi"
            }
            requests {
              cpu    = "100m"
              memory = "200Mi"
            }
          }
          liveness_probe {
            http_get {
              path = "/healthz"
              port = "8080"
            }
            initial_delay_seconds = 5
            timeout_seconds       = 5
          }
          readiness_probe {
            http_get {
              path = "/"
              port = "8081"
            }
            initial_delay_seconds = 5
            timeout_seconds       = 5
          }
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
        node_selector                   = { "beta.kubernetes.io/os" = "linux" }
        service_account_name            = "kube-state-metrics"
        automount_service_account_token = true
      }
    }
  }
}

resource "kubernetes_service" "kube_state_metrics" {
  count = var.enable_new_relic_agent && (terraform.workspace == "bootstrap") ? 1 : 0

  metadata {
    name      = "kube-state-metrics"
    namespace = "kube-system"
    labels    = { "app.kubernetes.io/name" = "kube-state-metrics", "app.kubernetes.io/version" = local.ksm_version_to_use }
  }
  spec {
    port {
      name        = "http-metrics"
      port        = 8080
      target_port = "http-metrics"
    }
    port {
      name        = "telemetry"
      port        = 8081
      target_port = "telemetry"
    }
    selector   = { "app.kubernetes.io/name" = "kube-state-metrics" }
    cluster_ip = "None"
  }
}

resource "kubernetes_cluster_role" "kube_state_metrics" {
  count = var.enable_new_relic_agent && (terraform.workspace == "bootstrap") ? 1 : 0

  metadata {
    name   = "kube-state-metrics"
    labels = { "app.kubernetes.io/name" = "kube-state-metrics", "app.kubernetes.io/version" = local.ksm_version_to_use }
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = [""]
    resources  = ["configmaps", "secrets", "nodes", "pods", "services", "resourcequotas", "replicationcontrollers", "limitranges", "persistentvolumeclaims", "persistentvolumes", "namespaces", "endpoints"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = ["extensions"]
    resources  = ["daemonsets", "deployments", "replicasets", "ingresses"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = ["apps"]
    resources  = ["statefulsets", "daemonsets", "deployments", "replicasets"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = ["batch"]
    resources  = ["cronjobs", "jobs"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
  }
  rule {
    verbs      = ["create"]
    api_groups = ["authentication.k8s.io"]
    resources  = ["tokenreviews"]
  }
  rule {
    verbs      = ["create"]
    api_groups = ["authorization.k8s.io"]
    resources  = ["subjectaccessreviews"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = ["certificates.k8s.io"]
    resources  = ["certificatesigningrequests"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = ["storage.k8s.io"]
    resources  = ["storageclasses", "volumeattachments"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = ["admissionregistration.k8s.io"]
    resources  = ["mutatingwebhookconfigurations", "validatingwebhookconfigurations"]
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = ["networking.k8s.io"]
    resources  = ["networkpolicies"]
  }
}

resource "kubernetes_service_account" "kube_state_metrics" {
  count = var.enable_new_relic_agent && (terraform.workspace == "bootstrap") ? 1 : 0

  metadata {
    name      = "kube-state-metrics"
    namespace = "kube-system"
    labels    = { "app.kubernetes.io/name" = "kube-state-metrics", "app.kubernetes.io/version" = local.ksm_version_to_use }
  }
}

resource "kubernetes_cluster_role_binding" "kube_state_metrics" {
  count = var.enable_new_relic_agent && (terraform.workspace == "bootstrap") ? 1 : 0

  metadata {
    name   = "kube-state-metrics"
    labels = { "app.kubernetes.io/name" = "kube-state-metrics", "app.kubernetes.io/version" = local.ksm_version_to_use }
  }
  subject {
    kind      = "ServiceAccount"
    name      = "kube-state-metrics"
    namespace = "kube-system"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "kube-state-metrics"
  }
}