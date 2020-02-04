locals {
  nexus_domain_name = "nexus.${var.kubernetes_cluster_name}.${var.domain}"
}

data "template_file" "nexus_xml" {
  template = "${file("nexus.xml.tmpl")}"
  vars = {
    ep_cortex_maven_repo_url           = "${var.ep_cortex_maven_repo_url}",
    ep_commerce_engine_maven_repo_url  = "${var.ep_commerce_engine_maven_repo_url}",
    ep_accelerators_maven_repo_url     = "${var.ep_accelerators_maven_repo_url}",
    ep_repository_user                 = "${var.ep_repository_user}",
    ep_repository_password             = "${var.ep_repository_password}"
    extra_nexus_repository_config_path = "${var.extra_nexus_repository_config_path}"
  }
}

resource "kubernetes_secret" "nexus-secrets" {
  count      = terraform.workspace == "bootstrap" ? 1 : 0
  depends_on = [azurerm_kubernetes_cluster.hub]

  metadata {
    name = "nexus-secrets"
  }
  data = {
    "nexus.xml" = "${data.template_file.nexus_xml.rendered}"
  }
  type = "Opaque"
}

resource "kubernetes_persistent_volume_claim" "ep-nexus-pvc" {
  count      = terraform.workspace == "bootstrap" ? 1 : 0
  depends_on = [azurerm_kubernetes_cluster.hub]

  metadata {
    name = "ep-nexus-pvc"
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "slow-local"
    resources {
      requests = {
        "storage" = "256Gi"
      }
    }
  }
  wait_until_bound = true
}

resource "kubernetes_deployment" "ep_nexus_deployment" {
  count      = terraform.workspace == "bootstrap" ? 1 : 0
  depends_on = [azurerm_kubernetes_cluster.hub]

  metadata {
    name = "ep-nexus-deployment"
    labels = {
      "app" = "ep-nexus"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app" = "ep-nexus"
      }
    }
    template {
      metadata {
        labels = {
          "app" = "ep-nexus"
        }
      }
      spec {
        volume {
          name = "nexus-secrets"
          secret {
            secret_name = "nexus-secrets"
          }
        }
        volume {
          name = "ep-nexus-volume"
          persistent_volume_claim {
            claim_name = "ep-nexus-pvc"
          }
        }
        init_container {
          name    = "nexus-init-add-p2-repository-plugin"
          image   = "alpine"
          command = ["sh", "-c", "apk add libarchive-tools; mkdir -p /sonatype-work/plugin-repository/; wget -T3 -O - http://repo.maven.apache.org/maven2/org/sonatype/nexus/plugins/nexus-p2-repository-plugin/2.14.9-01/nexus-p2-repository-plugin-2.14.9-01-bundle.zip | bsdtar -xv -C /sonatype-work/plugin-repository/ -f-; chown -R 200:200 /sonatype-work"]
          volume_mount {
            name       = "ep-nexus-volume"
            mount_path = "/sonatype-work"
          }
        }
        init_container {
          name    = "nexus-init-add-p2-bridge-plugin"
          image   = "alpine"
          command = ["sh", "-c", "apk add libarchive-tools; mkdir -p /sonatype-work/plugin-repository/; wget -T3 -O - http://repo.maven.apache.org/maven2/org/sonatype/nexus/plugins/nexus-p2-bridge-plugin/2.14.9-01/nexus-p2-bridge-plugin-2.14.9-01-bundle.zip | bsdtar -xv -C /sonatype-work/plugin-repository/ -f-; chown -R 200:200 /sonatype-work"]
          volume_mount {
            name       = "ep-nexus-volume"
            mount_path = "/sonatype-work"
          }
        }
        container {
          name  = "nexus"
          image = "sonatype/nexus:2.14.15-01"
          port {
            container_port = 8081
          }
          env {
            name  = "MIN_HEAP"
            value = "1024m"
          }
          env {
            name  = "MAX_HEAP"
            value = "1024m"
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
            name       = "nexus-secrets"
            read_only  = true
            mount_path = "/nexus-secrets"
          }
          volume_mount {
            name       = "ep-nexus-volume"
            mount_path = "/sonatype-work"
          }
          liveness_probe {
            exec {
              command = ["/bin/bash", "-c", "curl --max-time 3 -s -f http://localhost:8081/nexus/service/local/status | grep -F \"<state>STARTED</state>\""]
            }
            initial_delay_seconds = 180
            timeout_seconds       = 1
            period_seconds        = 3
            failure_threshold     = 3
          }
          readiness_probe {
            exec {
              command = ["/bin/bash", "-c", "curl --max-time 3 -s -f http://localhost:8081/nexus/service/local/status | grep -F \"<state>STARTED</state>\""]
            }
            timeout_seconds   = 1
            period_seconds    = 3
            failure_threshold = 3
          }
          lifecycle {
            post_start {
              exec {
                command = ["bash", "-c", "mkdir -p /sonatype-work/conf/ && cp /nexus-secrets/nexus.xml /sonatype-work/conf/nexus.xml"]
              }
            }
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
    create = "16m"
    update = "8m"
    delete = "15s"
  }
}

resource "kubernetes_service" "ep_nexus_service" {
  count      = terraform.workspace == "bootstrap" ? 1 : 0
  depends_on = [azurerm_kubernetes_cluster.hub]

  metadata {
    name = "ep-nexus-service"
    labels = {
      "app" = "ep-nexus"
    }
  }
  spec {
    port {
      name     = "ep-nexus-port-8081"
      protocol = "TCP"
      port     = 8081
    }
    selector = {
      "app" = "ep-nexus"
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_ingress" "ep_nexus_ingress" {
  count      = terraform.workspace == "bootstrap" ? 1 : 0

  metadata {
    name      = "ep-nexus-ingress"
    namespace = "default"

    annotations = {
      "ingress.kubernetes.io/load-balance"           = "least_conn"
      "ingress.kubernetes.io/secure-backends"        = "false"
      "ingress.kubernetes.io/use-proxy-protocol"     = "true"
      "ingress.kubernetes.io/whitelist-source-range" = "${var.nexus_allowed_cidr}"
      "kubernetes.io/ingress.class"                  = "haproxy"
    }
  }
  spec {
    tls {
      hosts = [local.nexus_domain_name]
    }
    rule {
      host = local.nexus_domain_name
      http {
        path {
          path = "/nexus"
          backend {
            service_name = "ep-nexus-service"
            service_port = "8081"
          }
        }
      }
    }
  }
}
