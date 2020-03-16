resource "azurerm_mysql_server" "external-azure-server" {
  count = var.cloud == "azure" ? 1 : 0
  administrator_login = var.root_username
  administrator_login_password = var.root_password
  location            = var.azure_location
  name                = var.database_hostname
  resource_group_name = var.target_resource_group
  ssl_enforcement     = "Enabled"
  tags                = {}
  version             = "5.7"

  sku {
    capacity = 4
    family   = "Gen5"
    name     = "GP_Gen5_4"
    tier     = "GeneralPurpose"
  }

  storage_profile {
    auto_grow             = "Enabled"
    backup_retention_days = 7
    geo_redundant_backup  = "Enabled"
    storage_mb            = 1048576
  }
}

resource "azurerm_mysql_database" "external-azure-database" {
  depends_on = [kubernetes_secret.external_database_secret]
  count = var.cloud == "azure" ? 1 : 0
  name                = local.db-database-name
  resource_group_name = var.target_resource_group
  server_name         = var.database_hostname
  charset             = "utf8"
  collation           = "utf8_general_ci"
}

resource "aws_rds_cluster" "external-aws-database" {
  count = var.cloud == "aws" ? 1 : 0
  cluster_identifier      = var.database_hostname
  backup_retention_period = 14
  engine                  = "aurora"
  engine_version          = "5.6.mysql_aurora.1.22.1"
  master_username         = var.root_username
  master_password         = var.root_password
  skip_final_snapshot     = true
  storage_encrypted       = true
}

resource "null_resource" "create-new-user" {
  depends_on = [azurerm_mysql_database.external-azure-database, aws_rds_cluster.external-aws-database, kubernetes_secret.external_database_secret]
  provisioner "local-exec" {
    command = "bash ./create-user-creds-in-database.sh"
    environment = {
      cloud               = var.cloud
      mysql_hostname      = var.database_hostname
      mysql_server_url    = var.database_server_url
      mysql_database      = local.db-database-name
      mysql_root_user     = var.root_username
      mysql_root_password = var.root_password
      mysql_new_user      = local.db-username
      mysql_new_password  = local.db-password
    }
  }
}