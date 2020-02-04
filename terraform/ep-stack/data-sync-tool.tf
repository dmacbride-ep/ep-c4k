data "kubernetes_secret" "target_jms_secret" {
  count = "${var.deploy_dst_webapp == "true" ? 1 : 0}"

  metadata {
    name      = "ep-jms-${var.target_jms_name}-secret"
    namespace = "${var.target_namespace}"
  }
}

resource "kubernetes_deployment" "ep_data_sync_deployment" {
  count = var.deploy_dst_webapp == "true" ? 1 : 0

  metadata {
    name      = "ep-data-sync-deployment"
    namespace = var.kubernetes_namespace
    labels = {
      app = "ep-data-sync"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "ep-data-sync"
      }
    }
    template {
      metadata {
        labels = {
          app = "ep-data-sync"
        }
      }
      spec {
        container {
          name  = "data-sync"
          image = "${var.registry_address}${var.namespace}/data-sync:${var.docker_image_tag}"
          port {
            container_port = 8080
          }
          env_from {
            secret_ref {
              name = "ep-stack-secret"
            }
          }
          env_from {
            secret_ref {
              name = "ep-jms-${var.jms_name}-secret"
            }
          }
          env_from {
            secret_ref {
              name = "ep-mysql-${var.database_name}-secret"
            }
          }
          env_from {
            secret_ref {
              name = "ep-searchslave-secret"
            }
          }
          env {
            name = "EP_DST_TARGET_JDBC_DRIVER_CLASS"
            value_from {
              secret_key_ref {
                name = "target-database-secrets"
                key  = "EP_DB_JDBC_DRIVER_CLASS"
              }
            }
          }
          env {
            name = "EP_DST_TARGET_PORT"
            value_from {
              secret_key_ref {
                name = "target-database-secrets"
                key  = "EP_DB_PORT"
              }
            }
          }
          env {
            name = "EP_DST_TARGET_SCHEMA"
            value_from {
              secret_key_ref {
                name = "target-database-secrets"
                key  = "EP_DB_SCHEMA_NAME"
              }
            }
          }
          env {
            name = "EP_DST_TARGET_DATABASE"
            value_from {
              secret_key_ref {
                name = "target-database-secrets"
                key  = "EP_DB_SCHEMA_NAME"
              }
            }
          }
          env {
            name = "EP_DST_TARGET_JMS_URL"
            value_from {
              secret_key_ref {
                name = "target-jms-secrets"
                key  = "EP_JMS_URL"
              }
            }
          }
          env {
            name = "EP_DST_TARGET_HOST"
            value_from {
              secret_key_ref {
                name = "target-database-secrets"
                key  = "EP_DB_HOSTNAME"
              }
            }
          }
          env {
            name = "EP_DST_TARGET_USERNAME"
            value_from {
              secret_key_ref {
                name = "target-database-secrets"
                key  = "EP_DB_USER"
              }
            }
          }
          env {
            name = "EP_DST_TARGET_PASSWORD"
            value_from {
              secret_key_ref {
                name = "target-database-secrets"
                key  = "EP_DB_PASS"
              }
            }
          }
          env {
            name = "EP_DST_TARGET_PARAMS"
            value_from {
              secret_key_ref {
                name = "target-database-secrets"
                key  = "EP_DB_CONNECTION_PARAMS"
              }
            }
          }
          env {
            name  = "EP_DST_TARGET_VALIDATION_QUERY"
            value = "/* ping */"
          }
          env {
            name = "EP_DST_TARGET_URL"
            value_from {
              secret_key_ref {
                name = "target-database-secrets"
                key  = "EP_DB_URL"
              }
            }
          }
          env {
            name  = "EP_DST_TIMEOUT"
            value = "86400"
          }
          resources {
            limits {
              cpu    = local.ep_stack_resourcing_proflies["data-sync"][var.ep_resourcing_profile]["cpu-cores"]
              memory = local.ep_stack_resourcing_proflies["data-sync"][var.ep_resourcing_profile]["memory"]
            }
            requests {
              cpu    = local.ep_stack_resourcing_proflies["data-sync"][var.ep_resourcing_profile]["cpu-cores"]
              memory = local.ep_stack_resourcing_proflies["data-sync"][var.ep_resourcing_profile]["memory"]
            }
          }
          liveness_probe {
            exec {
              command = ["/bin/bash", "-c", "curl --max-time 3 -s -f localhost:8080/data-sync/status | head -n 1 | grep OK"]
            }
            initial_delay_seconds = 300
            timeout_seconds       = 5
            period_seconds        = 10
            failure_threshold     = 3
          }
          readiness_probe {
            exec {
              command = ["/bin/bash", "-c", "curl --max-time 3 -s -f localhost:8080/data-sync/status | head -n 1 | grep OK"]
            }
            initial_delay_seconds = 1
            timeout_seconds       = 5
            period_seconds        = 10
            failure_threshold     = 3
          }
          image_pull_policy = "Always"
          tty               = true
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
        restart_policy = "Always"
        affinity {
          pod_anti_affinity {
            required_during_scheduling_ignored_during_execution {
              topology_key = "kubernetes.io/hostname"
            }
          }
        }
      }
    }
    progress_deadline_seconds = 900
  }
}

resource "kubernetes_service" "ep_data_sync_service" {
  count = var.deploy_dst_webapp == "true" ? 1 : 0

  metadata {
    name      = "ep-data-sync-service"
    namespace = var.kubernetes_namespace
    labels = {
      app = "ep-data-sync"
    }
  }
  spec {
    port {
      name     = "ep-data-sync-port-8080"
      protocol = "TCP"
      port     = 8080
    }
    selector = {
      app = "ep-data-sync"
    }
    type = "ClusterIP"
  }
}
