#
# This file contains parameters for the context XML files in Tomcat
# and parameters for the setenv.sh script in the Tomcat bin directory
#

resource "random_string" "jmx_username_suffix" {
  length  = 8
  upper   = true
  lower   = true
  number  = true
  special = false
}

resource "random_string" "jmx_password" {
  length  = 32
  upper   = true
  lower   = true
  number  = true
  special = false
}

locals {
  jmx_user     = "epJmxUser-${random_string.jmx_username_suffix.result}"
  jmx_password = "${random_string.jmx_password.result}"
}

resource "kubernetes_secret" "ep-stack-secret" {
  metadata {
    name      = "ep-stack-secret"
    namespace = var.kubernetes_namespace
  }

  data = {
    # Set EP Config Version
    EP_CONFIG_VERSION = "1"

    # DB configuration
    EP_DB_VALIDATION_INTERVAL = "60000"
    EP_DB_FACTORY             = "org.apache.tomcat.jdbc.pool.DataSourceFactory"
    EP_DB_TYPE                = "javax.sql.DataSource"
    EP_DB_XA_TYPE             = "com.mysql.jdbc.jdbc2.optional.MysqlXADataSource"
    EP_DB_XA_FACTORY          = "org.apache.tomcat.jdbc.naming.GenericNamingResourcesFactory"
    EP_DB_VALIDATION_QUERY    = "/* ping */"

    # CM specific database connection property
    # Must match the EP database timezone
    EP_DB_CM_CONNECTION_PROPERTIES = "serverTimezone=UTC;useLegacyDatetimeCode=false"

    # Memory settings
    EP_CONTAINER_MEM_CM           = local.ep_stack_resourcing_proflies["cm"][var.ep_resourcing_profile]["jvm-memory"]
    EP_CONTAINER_MEM_CORTEX       = local.ep_stack_resourcing_proflies["cortex"][var.ep_resourcing_profile]["jvm-memory"]
    EP_CONTAINER_MEM_SEARCH       = local.ep_stack_resourcing_proflies["searchmaster"][var.ep_resourcing_profile]["jvm-memory"]
    EP_CONTAINER_MEM_SEARCH_SLAVE = local.ep_stack_resourcing_proflies["searchslave"][var.ep_resourcing_profile]["jvm-memory"]
    EP_CONTAINER_MEM_BATCH        = local.ep_stack_resourcing_proflies["batch"][var.ep_resourcing_profile]["jvm-memory"]
    EP_CONTAINER_MEM_INTEGRATION  = local.ep_stack_resourcing_proflies["integration"][var.ep_resourcing_profile]["jvm-memory"]
    EP_CONTAINER_MEM_SYNC         = local.ep_stack_resourcing_proflies["data-sync"][var.ep_resourcing_profile]["jvm-memory"]

    #Tomcat cache size
    EP_CONTAINER_CACHESIZE = "100000"

    # CORS settings for Tomcat's CORS filter (only for Cortex)
    EP_CORS_ALLOWED_ORIGINS = "*"
    EP_CORS_ALLOWED_METHODS = "DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT"
    EP_CORS_ALLOWED_HEADERS = "Content-Type,X-Requested-With,accept,Origin,Access-Control-Request-Method,Access-Control-Request-Headers,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,x-ep-user-id,x-ep-user-roles,x-ep-user-scopes,x-ep-user-traits,x-forwarded-base"
    EP_CORS_EXPOSED_HEADERS = "Access-Control-Allow-Origin,Access-Control-Allow-Credentials"

    # SMTP settings
    EP_SMTP_HOST   = "${var.ep_smtp_host}"
    EP_SMTP_PORT   = "${var.ep_smtp_port}"
    EP_SMTP_SCHEME = "${var.ep_smtp_scheme}"
    EP_SMTP_USER   = "${var.ep_smtp_user}"
    EP_SMTP_PASS   = "${var.ep_smtp_pass}"

    # UI Tests
    EP_TESTS_ENABLE_UI = "${var.ep_tests_enable_ui}"

    # Changeset enabled
    EP_CHANGESETS_ENABLED = "${var.ep_changesets_enabled}"

    # EP Commerce environment
    EP_COMMERCE_ENVNAME = "${var.ep_commerce_envname}"

    # EP Integration role
    EP_INTEGRATION_ROLE = "standalone"

    # EP cloud provider
    EP_CLOUD_PROVIDER = "azure"

    EP_X_JVM_ARGS = "${var.ep_x_jvm_args}"

    ENABLE_JMX   = "${var.enable_jmx}"
    JMX_AUTH     = "${var.jmx_auth}"
    JMX_USER     = "${local.jmx_user}"
    JMX_PASSWORD = "${local.jmx_password}"

    ENABLE_DEBUG = "${var.enable_debug}"

    # Search entity loader and document creator queue size
    # The params are used to override the OOTB value - 10K entries
    EP_SEARCH_ENTITY_LOADER_QUEUE_CAPACITY    = ""
    EP_SEARCH_DOCUMENT_CREATOR_QUEUE_CAPACITY = ""
  }
}

resource "kubernetes_secret" "ep_searchslave_secret" {
  metadata {
    name      = "ep-searchslave-secret"
    namespace = var.kubernetes_namespace
  }

  data = {
    EP_SEARCH_ROLE       = "slave"
    EP_SEARCH_SLAVE_URL  = "http://ep-searchslave-service:8082/search"
    EP_SEARCH_MASTER_URL = "http://ep-searchmaster-service:8082/search"
  }
}

resource "kubernetes_secret" "ep_searchmaster_secret" {
  metadata {
    name      = "ep-searchmaster-secret"
    namespace = var.kubernetes_namespace
  }

  data = {
    EP_SEARCH_ROLE       = "master"
    EP_SEARCH_MASTER_URL = "http://localhost:8082/search"
  }
}
