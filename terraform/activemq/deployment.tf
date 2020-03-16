resource "kubernetes_deployment" "ep_activemq_deployment" {
  depends_on = [kubernetes_persistent_volume_claim.activemq_volume, kubernetes_secret.jms]

  metadata {
    name      = "ep-activemq-${var.jms_name}-deployment"
    namespace = var.kubernetes_namespace

    labels = {
      app = "ep-activemq-${var.jms_name}"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "ep-activemq-${var.jms_name}"
      }
    }
    template {
      metadata {
        labels = {
          app = "ep-activemq-${var.jms_name}"
        }
      }
      spec {
        volume {
          name = "activemq-${var.jms_name}-volume"
          persistent_volume_claim {
            claim_name = "activemq-${var.jms_name}-volume"
          }
        }
        container {
          name  = "activemq"
          image = "${var.registry_address}${var.docker_image_namespace}/activemq:${var.docker_image_tag}"
          port {
            container_port = 61616
          }
          port {
            container_port = 8161
          }
          env_from {
            secret_ref {
              name     = "ep-jms-${var.jms_name}-secret"
              optional = false
            }
          }
          resources {
            limits {
              cpu    = "1"
              memory = "1280Mi"
            }
            requests {
              cpu    = "1"
              memory = "1280Mi"
            }
          }
          volume_mount {
            name       = "activemq-${var.jms_name}-volume"
            mount_path = "/ep/efs"
          }
          liveness_probe {
            exec {
              command = ["/bin/bash", "-c", "curl -u admin:admin http://localhost:8161/api/jolokia | python -c \"import sys, json; print json.load(sys.stdin)['status']\" | grep 200"]
            }
            initial_delay_seconds = 600
            timeout_seconds       = 4
            period_seconds        = 5
            failure_threshold     = 3
          }
          readiness_probe {
            exec {
              command = ["/bin/bash", "-c", "curl -u admin:admin http://localhost:8161/api/jolokia | python -c \"import sys, json; print json.load(sys.stdin)['status']\" | grep 200"]
            }
            initial_delay_seconds = 1
            timeout_seconds       = 2
            period_seconds        = 5
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
