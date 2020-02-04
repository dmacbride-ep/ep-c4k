resource "kubernetes_namespace" "newrelic" {
  count = var.enable_new_relic_agent && (terraform.workspace == "bootstrap") ? 1 : 0

  metadata {
    name = "newrelic"
  }
}

resource "kubernetes_daemonset" "newrelic_infra" {
  count      = var.enable_new_relic_agent && (terraform.workspace == "bootstrap") ? 1 : 0
  depends_on = [kubernetes_namespace.newrelic]

  metadata {
    name      = "newrelic-infra"
    namespace = "newrelic"
    labels    = { app = "newrelic-infra" }
  }
  spec {
    selector {
      match_labels = { name = "newrelic-infra" }
    }
    template {
      metadata {
        labels = { name = "newrelic-infra" }
      }
      spec {
        volume {
          name = "host-volume"
          host_path {
            path = "/"
          }
        }
        volume {
          name = "host-docker-socket"
          host_path {
            path = "/var/run/docker.sock"
          }
        }
        container {
          name  = "newrelic-infra"
          image = "newrelic/infrastructure-k8s:1.12.0"
          env {
            name  = "CLUSTER_NAME"
            value = var.new_relic_cluster_name
          }
          env_from {
            secret_ref {
              name     = "newrelic-license-secret"
              optional = false
            }
          }
          env {
            name  = "NRIA_VERBOSE"
            value = "0"
          }
          env {
            name = "NRIA_DISPLAY_NAME"
            value_from {
              field_ref {
                api_version = "v1"
                field_path  = "spec.nodeName"
              }
            }
          }
          env {
            name = "NRK8S_NODE_NAME"
            value_from {
              field_ref {
                api_version = "v1"
                field_path  = "spec.nodeName"
              }
            }
          }
          env {
            name  = "NRIA_CUSTOM_ATTRIBUTES"
            value = "{\"clusterName\":\"$(CLUSTER_NAME)\"}"
          }
          env {
            name  = "NRIA_PASSTHROUGH_ENVIRONMENT"
            value = "KUBERNETES_SERVICE_HOST,KUBERNETES_SERVICE_PORT,CLUSTER_NAME,CADVISOR_PORT,NRK8S_NODE_NAME,KUBE_STATE_METRICS_URL"
          }
          resources {
            limits {
              cpu    = "250m"
              memory = "150M"
            }
            requests {
              cpu    = "250m"
              memory = "150M"
            }
          }
          volume_mount {
            name       = "host-volume"
            read_only  = true
            mount_path = "/host"
          }
          volume_mount {
            name       = "host-docker-socket"
            mount_path = "/var/run/docker.sock"
          }
          security_context {
            privileged = true
          }
        }
        dns_policy                      = "ClusterFirstWithHostNet"
        service_account_name            = "newrelic"
        automount_service_account_token = true
        host_network                    = true
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
      }
    }
    strategy {
      type = "RollingUpdate"
    }
  }
}

resource "kubernetes_secret" "newrelic_license_secret" {
  count      = var.enable_new_relic_agent && (terraform.workspace == "bootstrap") ? 1 : 0
  depends_on = [kubernetes_namespace.newrelic]

  metadata {
    name      = "newrelic-license-secret"
    namespace = "newrelic"
  }

  data = {
    NRIA_LICENSE_KEY = var.new_relic_license_key
  }
}

resource "kubernetes_service_account" "newrelic" {
  count      = var.enable_new_relic_agent && (terraform.workspace == "bootstrap") ? 1 : 0
  depends_on = [kubernetes_namespace.newrelic]

  metadata {
    name      = "newrelic"
    namespace = "newrelic"
  }
  automount_service_account_token = true
}

resource "kubernetes_cluster_role" "newrelic" {
  count = var.enable_new_relic_agent && (terraform.workspace == "bootstrap") ? 1 : 0

  metadata {
    name = "newrelic"
  }
  rule {
    verbs      = ["get", "list"]
    api_groups = [""]
    resources  = ["nodes", "nodes/metrics", "nodes/stats", "nodes/proxy", "pods", "services"]
  }
}

resource "kubernetes_cluster_role_binding" "newrelic" {
  count      = var.enable_new_relic_agent && (terraform.workspace == "bootstrap") ? 1 : 0
  depends_on = [kubernetes_namespace.newrelic]

  metadata {
    name = "newrelic"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "newrelic"
    namespace = "newrelic"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "newrelic"
  }
}