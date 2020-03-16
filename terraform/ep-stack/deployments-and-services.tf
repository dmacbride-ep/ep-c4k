locals {
  commerce_profiles = {
    "cm" = {
      "prod-small" = {
        "cpu-cores"  = "3"
        "memory"     = "3072Mi"
        "jvm-memory" = "2048"
      }
      "dev" = {
        "cpu-cores"  = "0.5"
        "memory"     = "3072Mi"
        "jvm-memory" = "2048"
      }
    }
    "integration" = {
      "prod-small" = {
        "cpu-cores"  = "3"
        "memory"     = "3072Mi"
        "jvm-memory" = "2048"
      }
      "dev" = {
        "cpu-cores"  = "0.5"
        "memory"     = "3072Mi"
        "jvm-memory" = "2048"
      }
    }
    "searchmaster" = {
      "prod-small" = {
        "cpu-cores"     = "3"
        "memory"        = "3072Mi"
        "jvm-memory"    = "2048"
        "storage-class" = "fast-local"
        "pvc-size"      = "10Gi"
      }
      "dev" = {
        "cpu-cores"     = "0.5"
        "memory"        = "3072Mi"
        "jvm-memory"    = "2048"
        "storage-class" = "fast-local"
        "pvc-size"      = "5Gi"
      }
    }
    "searchslave" = {
      "prod-small" = {
        "cpu-cores"              = "2"
        "memory"                 = "3072Mi"
        "jvm-memory"             = "2048"
        "min-replicas"           = 1
        "max-replicas"           = 10
        "target-cpu-utilization" = 50
      }
      "dev" = {
        "cpu-cores"              = "0.5"
        "memory"                 = "3072Mi"
        "jvm-memory"             = "2048"
        "min-replicas"           = 1
        "max-replicas"           = 1
        "target-cpu-utilization" = 50
      }
    }
    "cortex" = {
      "prod-small" = {
        "cpu-cores"              = "3"
        "memory"                 = "5120Mi"
        "jvm-memory"             = "3584"
        "min-replicas"           = 2
        "max-replicas"           = 6
        "target-cpu-utilization" = 50
      }
      "dev" = {
        "cpu-cores"              = "1"
        "memory"                 = "4608Mi"
        "jvm-memory"             = "3584"
        "min-replicas"           = 1
        "max-replicas"           = 1
        "target-cpu-utilization" = 50
      }
    }
    "batch" = {
      "prod-small" = {
        "cpu-cores"  = "1"
        "memory"     = "4096Mi"
        "jvm-memory" = "2048"
      }
      "dev" = {
        "cpu-cores"  = "0.25"
        "memory"     = "3072Mi"
        "jvm-memory" = "2048"
      }
    }
    "data-sync" = {
      "prod-small" = {
        "cpu-cores"  = "3"
        "memory"     = "3Gi"
        "jvm-memory" = "2048"
      }
      "dev" = {
        "cpu-cores"  = "1"
        "memory"     = "3072Mi"
        "jvm-memory" = "2048"
      }
    }
  }
  deployments_and_services = {
    "cm" = {
      "image-name"                           = "cm"
      "ports"                                = ["8080"]
      "search-secret"                        = "ep-searchslave-secret"
      "probe-command"                        = ["/bin/bash", "-c", "curl -s -f localhost:8080/cm/?servicehandler=status | head -n 1 | grep OK"]
      "liveness-probe-initial-delay-seconds" = "960"
      "volumes"                              = []
    }
    "integration" = {
      "image-name"                           = "integration"
      "ports"                                = ["8080"]
      "search-secret"                        = "ep-searchslave-secret"
      "probe-command"                        = ["/bin/bash", "-c", "curl -s -f localhost:8080/integration/status | head -n 1 | grep OK"]
      "liveness-probe-initial-delay-seconds" = "180"
      "volumes"                              = []
    }
    "searchmaster" = {
      "image-name"                           = "search"
      "ports"                                = ["8082"]
      "search-secret"                        = "ep-searchmaster-secret"
      "probe-command"                        = ["/bin/bash", "-c", "curl -s -f localhost:8082/search/status | head -n 1 | grep OK"]
      "liveness-probe-initial-delay-seconds" = "180"
      "volumes"                              = [{ "pvc" : "solr-index-volume", "path" : "/ep/solrHome-master/data" }]
    }
    "searchslave" = {
      "image-name"                           = "search"
      "ports"                                = ["8082"]
      "search-secret"                        = "ep-searchslave-secret"
      "probe-command"                        = ["/bin/bash", "-c", "curl -s -f localhost:8082/search/status | head -n 1 | grep OK"]
      "liveness-probe-initial-delay-seconds" = "540"
      "volumes"                              = []
    }
    "cortex" = {
      "image-name"                           = "cortex"
      "ports"                                = ["8080", "1081"]
      "search-secret"                        = "ep-searchslave-secret"
      "probe-command"                        = ["/bin/bash", "-c", "curl -s -f localhost:8080/cortex/healthcheck"]
      "liveness-probe-initial-delay-seconds" = "960"
      "volumes"                              = []
    }
    "batch" = {
      "image-name"                           = "batch"
      "ports"                                = ["8080", "1081"]
      "search-secret"                        = "ep-searchslave-secret"
      "probe-command"                        = ["/bin/bash", "-c", "curl -s -f localhost:8080/batch/status | head -n 1 | grep OK"]
      "liveness-probe-initial-delay-seconds" = "960"
      "volumes"                              = []
    }
  }
}

resource "kubernetes_deployment" "ep_deployment" {
  for_each = local.deployments_and_services
  timeouts {
    create = "40m"
    delete = "20m"
    update = "2h"
  }

  metadata {
    name      = "ep-${each.key}-deployment"
    namespace = var.kubernetes_namespace

    labels = {
      app = "ep-${each.key}"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "ep-${each.key}"
      }
    }
    template {
      metadata {
        labels = {
          app = "ep-${each.key}"
        }
      }
      spec {
        container {
          name  = each.key
          image = "${var.registry_address}${var.namespace}/${each.value["image-name"]}:${var.docker_image_tag}"

          # see https://www.terraform.io/docs/configuration/expressions.html#dynamic-blocks
          dynamic "port" {
            for_each = each.value["ports"]
            content {
              container_port = port.value
            }
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
              name = each.value["search-secret"]
            }
          }
          resources {
            limits {
              cpu    = local.commerce_profiles[each.key][var.ep_resourcing_profile]["cpu-cores"]
              memory = local.commerce_profiles[each.key][var.ep_resourcing_profile]["memory"]
            }
            requests {
              cpu    = local.commerce_profiles[each.key][var.ep_resourcing_profile]["cpu-cores"]
              memory = local.commerce_profiles[each.key][var.ep_resourcing_profile]["memory"]
            }
          }
          liveness_probe {
            exec {
              command = each.value["probe-command"]
            }
            initial_delay_seconds = each.value["liveness-probe-initial-delay-seconds"]
            timeout_seconds       = 4
            period_seconds        = 10
            failure_threshold     = 3
          }
          readiness_probe {
            exec {
              command = each.value["probe-command"]
            }
            initial_delay_seconds = 1
            timeout_seconds       = 2
            period_seconds        = 10
            failure_threshold     = 3
          }
          dynamic "volume_mount" {
            for_each = each.value["volumes"]
            content {
              name       = volume_mount.value["pvc"]
              mount_path = volume_mount.value["path"]
            }
          }
          image_pull_policy = "Always"
          tty               = true
        }
        dynamic "volume" {
          for_each = each.value["volumes"]
          content {
            name = volume.value["pvc"]
            persistent_volume_claim {
              claim_name = volume.value["pvc"]
            }
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
    progress_deadline_seconds = 1200
  }
}

resource "kubernetes_service" "ep_service" {
  for_each = local.deployments_and_services

  metadata {
    name      = "ep-${each.key}-service"
    namespace = var.kubernetes_namespace

    labels = {
      app = "ep-${each.key}"
    }
  }
  spec {
    # see https://www.terraform.io/docs/configuration/expressions.html#dynamic-blocks
    dynamic "port" {
      for_each = each.value["ports"]
      content {
        name     = "ep-${each.key}-port-${port.value}"
        protocol = "TCP"
        port     = port.value
      }
    }

    selector = {
      app = "ep-${each.key}"
    }
    type = "ClusterIP"
  }
}
