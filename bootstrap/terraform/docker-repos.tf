locals {
  repo-names = [
    "ep/activemq",
    "ep/amazonlinux-java",
    "ep/batch",
    "ep/cm",
    "ep/cortex",
    "ep/data-pop-tool",
    "ep/data-sync",
    "ep/info-page",
    "ep/integration",
    "ep/mysql",
    "ep/search",
    "ep/tomcat",
    "am/am-ui",
    "am/am-api",
    "am/am-config",
    "jenkins/docker-agent",
    "jenkins/maven-agent",
    "bootstrap/kubernetes-bootstrap"
  ]
  ecr-repo-names = (var.cloud == "aws") && (terraform.workspace == "bootstrap") ? concat(local.repo-names, var.additional_ecr_repos) : []
}

resource "aws_ecr_repository" "ecr-repo" {
  for_each = toset(local.ecr-repo-names)
  name     = each.value

  depends_on = [null_resource.check_no_ecr_duplicates]
}

resource "null_resource" "check_no_ecr_duplicates" {
  count = (var.cloud != "aws") || (length(var.additional_ecr_repos) + length(local.repo-names) == length(toset(concat(local.repo-names, var.additional_ecr_repos)))) ? 0 : "invalid" # duplicate ecr repos
}

resource "azurerm_container_registry" "acr" {
  count = (var.cloud == "azure") && (terraform.workspace == "bootstrap") ? 1 : 0

  name                = var.azure_acr_instance_name
  resource_group_name = data.azurerm_resource_group.rg[0].name
  location            = data.azurerm_resource_group.rg[0].location
  sku                 = "Premium"
  admin_enabled       = true
}
