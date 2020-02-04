resource "kubernetes_deployment" "ep_am_mysql_deployment" {
  depends_on = [kubernetes_persistent_volume_claim.mysql_pvc]

  metadata {
    name      = "ep-am-mysql-${var.database_name}-deployment"
    namespace = var.kubernetes_namespace
    labels = {
      app = "ep-am-mysql-${var.database_name}"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "ep-am-mysql-${var.database_name}"
      }
    }
    template {
      metadata {
        labels = {
          app = "ep-am-mysql-${var.database_name}"
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
          image = "mysql:5.7"
          port {
            container_port = 3306
          }
          env_from {
            secret_ref {
              name = "ep-am-mysql-${var.database_name}-secret"
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
              command = ["/bin/bash", "-c", "mysql --user=root --password=$MYSQL_ROOT_PASSWORD -e \"select User from mysql.user;\""]
            }
            initial_delay_seconds = 180
            timeout_seconds       = 3
            period_seconds        = 3
            failure_threshold     = 3
          }
          readiness_probe {
            exec {
              command = ["/bin/bash", "-c", "mysql --user=root --password=$MYSQL_ROOT_PASSWORD -e \"select User from mysql.user;\""]
            }
            initial_delay_seconds = 1
            timeout_seconds       = 1
            period_seconds        = 3
            failure_threshold     = 3
          }
          image_pull_policy = "Always"
        }
        restart_policy = "Always"
      }
    }
    progress_deadline_seconds = 900
  }
}
