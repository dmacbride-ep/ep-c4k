locals {
  haproxy_release_name = "haproxy-ingress-global"
}

data "helm_repository" "incubator" {
  name = "incubator"
  url  = "https://kubernetes-charts-incubator.storage.googleapis.com/"
}

resource "tls_private_key" "ingress_controller" {
  algorithm   = "RSA"
  ecdsa_curve = "2048"
}

resource "tls_self_signed_cert" "ingress_controller" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.ingress_controller.private_key_pem

  subject {
    common_name  = "*.${var.kubernetes_cluster_name}.${var.domain}"
    organization = "test1"
  }

  validity_period_hours = 87600

  allowed_uses = ["server_auth"]

  dns_names = concat("${var.self_signed_cert_sans}", ["*.${var.kubernetes_cluster_name}.${var.domain}"])
}

resource "kubernetes_namespace" "haproxy-namespace" {
  count      = terraform.workspace == "bootstrap" ? 1 : 0
  depends_on = [azurerm_kubernetes_cluster.hub]

  metadata {
    name = local.haproxy_release_name
  }

  timeouts {
    delete = "3m"
  }
}

resource "kubernetes_secret" "tls-secret" {
  count      = terraform.workspace == "bootstrap" ? 1 : 0
  depends_on = [kubernetes_namespace.haproxy-namespace, azurerm_kubernetes_cluster.hub]

  type = "kubernetes.io/tls"
  metadata {
    name      = "${local.haproxy_release_name}-cert"
    namespace = local.haproxy_release_name
  }
  data = {
    "tls.crt" = "${fileexists("${var.haproxy_cert_path}") ? file("${var.haproxy_cert_path}") : "${tls_self_signed_cert.ingress_controller.cert_pem}"}"
    "tls.key" = "${fileexists("${var.haproxy_key_path}") ? file("${var.haproxy_key_path}") : "${tls_private_key.ingress_controller.private_key_pem}"}"
  }
}

data "template_file" "haproxy-ingress-controller-helm-values" {
  count = "${terraform.workspace == "bootstrap" ? 1 : 0}"

  template = "${file("haproxy-ingress-controller-helm-values.yaml.tmpl")}"
  vars = {
    cert_namespace_and_secret = "${local.haproxy_release_name}/${local.haproxy_release_name}-cert"
  }
}

resource "helm_release" "haproxy" {
  count      = terraform.workspace == "bootstrap" ? 1 : 0
  depends_on = [kubernetes_deployment.tiller_deploy, kubernetes_namespace.haproxy-namespace, kubernetes_secret.tls-secret, kubernetes_deployment.metrics_server, azurerm_kubernetes_cluster.hub]

  name       = local.haproxy_release_name
  namespace  = local.haproxy_release_name
  repository = data.helm_repository.incubator.metadata.0.name
  chart      = "haproxy-ingress"
  version    = "0.0.15"
  timeout    = "2700"
  wait       = "true"

  values = [
    "${data.template_file.haproxy-ingress-controller-helm-values[count.index].rendered}"
  ]
}

data "kubernetes_service" "ingress-controller-service" {
  depends_on = [helm_release.haproxy]

  metadata {
    name      = "${local.haproxy_release_name}-controller"
    namespace = "${local.haproxy_release_name}"
  }
}
