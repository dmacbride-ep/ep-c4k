resource "kubernetes_deployment" "ep_mysql_deployment" {
  depends_on = [kubernetes_persistent_volume_claim.mysql_pvc]

  metadata {
    name      = "ep-mysql-${var.database_name}-deployment"
    namespace = var.kubernetes_namespace
    labels = {
      app = "ep-mysql-${var.database_name}"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "ep-mysql-${var.database_name}"
      }
    }
    template {
      metadata {
        labels = {
          app = "ep-mysql-${var.database_name}"
        }
      }
      spec {
        volume {
          name = "mysql-${var.database_name}-pvc"
          persistent_volume_claim {
            claim_name = "mysql-${var.database_name}-pvc"
          }
        }
        init_container {
          name    = "ensure-empty-volume-init-container"
          image   = "busybox"
          command = ["sh", "-c", "rm -rf /var/lib/mysql/lost+found"]
          volume_mount {
            name       = "mysql-${var.database_name}-pvc"
            mount_path = "/var/lib/mysql"
          }
        }
        container {
          name  = "mysql"
          image = "${var.registry_address}${var.docker_image_namespace}/mysql:${var.docker_image_tag}"
          port {
            container_port = 3306
          }
          env {
            name = "MYSQL_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = "ep-mysql-${var.database_name}-secret"
                key  = "EP_DB_ROOT_PASS"
              }
            }
          }
          resources {
            limits {
              cpu    = "1"
              memory = "512Mi"
            }
            requests {
              memory = "512Mi"
              cpu    = "1"
            }
          }
          volume_mount {
            name       = "mysql-${var.database_name}-pvc"
            mount_path = "/var/lib/mysql"
          }
          liveness_probe {
            exec {
              command = ["/bin/bash", "-c", "mysql --defaults-file=/var/lib/mysql/healthcheck_cf -uhealthcheck -e \"select User from mysql.user;\""]
            }
            initial_delay_seconds = 180
            timeout_seconds       = 3
            period_seconds        = 3
            failure_threshold     = 3
          }
          readiness_probe {
            exec {
              command = ["/bin/bash", "-c", "mysql --defaults-file=/var/lib/mysql/healthcheck_cf -uhealthcheck -e \"select User from mysql.user;\""]
            }
            initial_delay_seconds = 1
            timeout_seconds       = 1
            period_seconds        = 3
            failure_threshold     = 3
          }
          image_pull_policy = "Always"
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
  timeouts {
    create = "20m"
  }
}