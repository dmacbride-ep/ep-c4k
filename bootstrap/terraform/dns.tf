resource "aws_route53_zone" "zone" {
  count = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0

  name = var.domain
}

resource "aws_route53_record" "eks-cluster-ingress-controller-record" {
  count      = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? 1 : 0
  depends_on = [helm_release.haproxy, aws_route53_zone.zone]

  zone_id = aws_route53_zone.zone[0].zone_id
  name    = "*.${var.kubernetes_cluster_name}.${var.domain}"
  type    = "CNAME"
  ttl     = "60"
  records = ["${data.kubernetes_service.ingress-controller-service.load_balancer_ingress[0].hostname}"]
}

resource "azurerm_dns_zone" "zone" {
  count = (var.cloud == "azure") && (terraform.workspace == "bootstrap") ? 1 : 0

  name                = var.domain
  resource_group_name = data.azurerm_resource_group.rg[0].name
}

resource "azurerm_dns_a_record" "record-for-hub" {
  count      = (var.cloud == "azure") && (terraform.workspace == "bootstrap") ? 1 : 0
  depends_on = [helm_release.haproxy, azurerm_dns_zone.zone]

  name                = "*.${var.kubernetes_cluster_name}"
  zone_name           = azurerm_dns_zone.zone[0].name
  resource_group_name = data.azurerm_resource_group.rg[0].name
  ttl                 = 60
  records             = ["${data.kubernetes_service.ingress-controller-service.load_balancer_ingress[0].ip}"]
}

output "cluster_ingress_controller_address" {
  value = "${var.cloud == "aws" ? "${aws_route53_record.eks-cluster-ingress-controller-record[0].fqdn}" : "*.${var.kubernetes_cluster_name}.${azurerm_dns_zone.zone[0].name}"}"
}

output "aws_route53_zone_id" {
  value     = "${var.cloud == "aws" ? "${aws_route53_zone.zone[0].zone_id}" : ""}"
  sensitive = true
}
