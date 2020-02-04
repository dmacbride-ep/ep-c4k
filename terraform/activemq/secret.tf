locals {
  jms_port     = "61616"
  jms_hostname = "ep-activemq-${var.jms_name}-service.${var.kubernetes_namespace}"
  jms_url      = "tcp://${local.jms_hostname}:${local.jms_port}"
}

resource "kubernetes_secret" "jms" {
  metadata {
    name      = "ep-jms-${var.jms_name}-secret"
    namespace = var.kubernetes_namespace
  }

  data = {
    # Commerce specific env vars
    EP_JMS_SERVER             = local.jms_hostname
    EP_JMS_PORT               = local.jms_port
    EP_JMS_TYPE               = "org.apache.activemq.pool.PooledConnectionFactory"
    EP_JMS_FACTORY            = "org.apache.activemq.jndi.JNDIReferenceFactory"
    EP_JMS_URL                = local.jms_url
    EP_JMS_XA_FACTORY         = "org.apache.activemq.jndi.JNDIReferenceFactory"
    EP_JMS_XA_TYPE            = "org.apache.activemq.ActiveMQXAConnectionFactory"
    EP_CONTAINER_MEM_ACTIVEMQ = "512"

    # Account Management specific env vars
    API_JMS_URL      = local.jms_url
    API_JMS_ENDPOINT = "ep.accountmanagement"
  }
}
