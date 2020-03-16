resource "kubernetes_secret" "jms" {
  metadata {
    name      = "ep-jms-${var.service_name}-secret"
    namespace = var.kubernetes_namespace
  }

  data = {
    # Commerce specific env vars
    EP_JMS_SERVER             = split(":", split("tcp://", var.jms_url)[1])[0]
    EP_JMS_PORT               = split(":", split("tcp://", var.jms_url)[1])[1]
    EP_JMS_TYPE               = "org.apache.activemq.pool.PooledConnectionFactory"
    EP_JMS_FACTORY            = "org.apache.activemq.jndi.JNDIReferenceFactory"
    EP_JMS_URL                = var.jms_url
    EP_JMS_XA_FACTORY         = "org.apache.activemq.jndi.JNDIReferenceFactory"
    EP_JMS_XA_TYPE            = "org.apache.activemq.ActiveMQXAConnectionFactory"
    EP_CONTAINER_MEM_ACTIVEMQ = "1024"

    # Account Management specific env vars
    API_JMS_URL      = var.jms_url
    API_JMS_ENDPOINT = "ep.accountmanagement"
  }
}
