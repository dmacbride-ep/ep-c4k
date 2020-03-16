resource "kubernetes_namespace" "overprovisioning" {
  count = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0

  metadata {
    annotations = {
      name = "overprovisioning"
    }

    name = "overprovisioning"
  }
}

resource "kubernetes_deployment" "overprovisioning" {
  count      = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0
  depends_on = [kubernetes_namespace.overprovisioning, kubernetes_priority_class.overprovisioning]
  lifecycle {
    ignore_changes = [
      spec[0].replicas
    ]
  }

  metadata {
    name      = "overprovisioning"
    namespace = "overprovisioning"
  }
  spec {
    replicas = 1
    selector {
      match_labels = { run = "overprovisioning" }
    }
    template {
      metadata {
        labels = { run = "overprovisioning" }
      }
      spec {
        container {
          name  = "reserve-resources"
          image = "k8s.gcr.io/pause"
          resources {
            requests {
              cpu = "1"
            }
          }
        }
        priority_class_name = "overprovisioning"
      }
    }
  }
}

resource "kubernetes_deployment" "overprovisioning_autoscaler" {
  count = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0
  depends_on = [
    kubernetes_namespace.overprovisioning,
    kubernetes_deployment.overprovisioning,
    kubernetes_service_account.cluster_proportional_autoscaler,
    kubernetes_cluster_role_binding.cluster_proportional_autoscaler
  ]

  metadata {
    name      = "overprovisioning-autoscaler"
    namespace = "overprovisioning"
    labels    = { app = "overprovisioning-autoscaler" }
  }
  spec {
    replicas = 1
    selector {
      match_labels = { app = "overprovisioning-autoscaler" }
    }
    template {
      metadata {
        labels = { app = "overprovisioning-autoscaler" }
      }
      spec {
        container {
          name  = "autoscaler"
          image = "k8s.gcr.io/cluster-proportional-autoscaler-amd64:1.1.2"
          command = [
            "./cluster-proportional-autoscaler",
            "--namespace=overprovisioning",
            "--configmap=overprovisioning-autoscaler",
            "--default-params={\"ladder\":{ \"nodesToReplicas\": [ [ 1, 4 ] ] }}",
            "--target=deployment/overprovisioning",
            "--logtostderr=true",
            "--v=2"
          ]
        }
        service_account_name            = "cluster-proportional-autoscaler"
        automount_service_account_token = true
      }
    }
  }
}

resource "kubernetes_priority_class" "overprovisioning" {
  count = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0

  metadata {
    name = "overprovisioning"
  }
  value       = -1
  description = "Priority class used by overprovisioning."
}

resource "kubernetes_service_account" "cluster_proportional_autoscaler" {
  count      = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0
  depends_on = [kubernetes_namespace.overprovisioning]

  metadata {
    name      = "cluster-proportional-autoscaler"
    namespace = "overprovisioning"
  }
}

resource "kubernetes_cluster_role" "cluster_proportional_autoscaler" {
  count = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0

  metadata {
    name = "cluster-proportional-autoscaler"
  }
  rule {
    verbs      = ["list", "watch"]
    api_groups = [""]
    resources  = ["nodes"]
  }
  rule {
    verbs      = ["get", "update"]
    api_groups = [""]
    resources  = ["replicationcontrollers/scale"]
  }
  rule {
    verbs      = ["get", "update"]
    api_groups = ["extensions", "apps"]
    resources  = ["deployments/scale", "replicasets/scale"]
  }
  rule {
    verbs      = ["get", "create"]
    api_groups = [""]
    resources  = ["configmaps"]
  }
}

resource "kubernetes_cluster_role_binding" "cluster_proportional_autoscaler" {
  count = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0
  depends_on = [
    kubernetes_service_account.cluster_proportional_autoscaler,
    kubernetes_cluster_role.cluster_proportional_autoscaler
  ]

  metadata {
    name = "cluster-proportional-autoscaler"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "cluster-proportional-autoscaler"
    namespace = "overprovisioning"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-proportional-autoscaler"
  }
}