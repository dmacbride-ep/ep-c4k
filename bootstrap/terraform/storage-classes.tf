locals {
  storage_class_provisioners = {
    "azure" = "kubernetes.io/azure-disk"
    "aws"   = "kubernetes.io/aws-ebs"
  }
}

resource "kubernetes_storage_class" "fast-local" {
  count      = terraform.workspace == "bootstrap" ? 1 : 0
  depends_on = [azurerm_kubernetes_cluster.hub]

  metadata {
    name = "fast-local"
  }
  storage_provisioner = lookup(local.storage_class_provisioners, var.cloud)
  reclaim_policy      = "Delete"
  parameters = {
    # AWS
    "type"      = "${var.cloud == "aws" ? "io1" : null}"
    "iopsPerGB" = "${var.cloud == "aws" ? "50" : null}"
    "fsType"    = "${var.cloud == "aws" ? "ext4" : null}"

    # Azure
    "cachingmode"        = "${var.cloud == "azure" ? "ReadOnly" : null}"
    "kind"               = "${var.cloud == "azure" ? "Managed" : null}"
    "storageaccounttype" = "${var.cloud == "azure" ? "Premium_LRS" : null}"
  }
}

resource "kubernetes_storage_class" "slow-local" {
  count      = terraform.workspace == "bootstrap" ? 1 : 0
  depends_on = [azurerm_kubernetes_cluster.hub]

  metadata {
    name = "slow-local"
  }
  storage_provisioner = lookup(local.storage_class_provisioners, var.cloud)
  reclaim_policy      = "Delete"
  parameters = {
    # AWS
    "type"   = "${var.cloud == "aws" ? "gp2" : null}"
    "fsType" = "${var.cloud == "aws" ? "ext4" : null}"

    # Azure
    "cachingmode"        = "${var.cloud == "azure" ? "ReadOnly" : null}"
    "kind"               = "${var.cloud == "azure" ? "Managed" : null}"
    "storageaccounttype" = "${var.cloud == "azure" ? "Standard_LRS" : null}"
  }
}

