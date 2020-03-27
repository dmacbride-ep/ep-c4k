resource "kubernetes_namespace" "cloudwatch-namespace" {
  count = (var.cloud == "aws") && (terraform.workspace == "bootstrap") && (var.aws_enable_cloudwatch_logging) ? 1 : 0

  metadata {
    labels = {
      name = "amazon-cloudwatch"
    }

    name = "amazon-cloudwatch"
  }
  timeouts {
    delete = "3m"
  }
}

resource "kubernetes_config_map" "cluster-info-config-map" {
  count      = (var.cloud == "aws") && (terraform.workspace == "bootstrap") && (var.aws_enable_cloudwatch_logging) ? 1 : 0
  depends_on = [kubernetes_namespace.cloudwatch-namespace]

  metadata {
    name      = "cluster-info"
    namespace = "amazon-cloudwatch"
  }
  data = {
    "cluster.name" = var.kubernetes_cluster_name
    "logs.region"  = (var.cloud == "aws") ? var.aws_region : null
  }
}

resource "kubernetes_service_account" "fluentd" {
  count      = (var.cloud == "aws") && (terraform.workspace == "bootstrap") && (var.aws_enable_cloudwatch_logging) ? 1 : 0
  depends_on = [kubernetes_namespace.cloudwatch-namespace]

  metadata {
    name      = "fluentd"
    namespace = "amazon-cloudwatch"
  }
}

resource "kubernetes_cluster_role" "fluentd-role" {
  count = (var.cloud == "aws") && (terraform.workspace == "bootstrap") && (var.aws_enable_cloudwatch_logging) ? 1 : 0

  metadata {
    name = "fluentd-role"
  }
  rule {
    api_groups = [""]
    resources  = ["namespaces", "pods", "pods/logs"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "fluentd-role-binding" {
  count      = (var.cloud == "aws") && (terraform.workspace == "bootstrap") && (var.aws_enable_cloudwatch_logging) ? 1 : 0
  depends_on = [kubernetes_service_account.fluentd, kubernetes_cluster_role.fluentd-role]

  metadata {
    name = "fluentd-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "fluentd-role"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "fluentd"
    namespace = "amazon-cloudwatch"
  }
}

resource "kubernetes_config_map" "fluentd-config" {
  count      = (var.cloud == "aws") && (terraform.workspace == "bootstrap") && (var.aws_enable_cloudwatch_logging) ? 1 : 0
  depends_on = [kubernetes_namespace.cloudwatch-namespace]

  metadata {
    name      = "fluentd-config"
    namespace = "amazon-cloudwatch"

    labels = {
      "k8s-app" = "fluentd-cloudwatch"
    }

  }
  data = {
    "fluent.conf"     = <<EOF
@include containers.conf
@include systemd.conf
@include host.conf

<match fluent.**>
  @type null
</match>
EOF
    "containers.conf" = <<EOF
<source>
  @type tail
  @id in_tail_container_logs
  @label @containers
  path /var/log/containers/*.log
  exclude_path ["/var/log/containers/cloudwatch-agent*", "/var/log/containers/fluentd*"]
  pos_file /var/log/fluentd-containers.log.pos
  tag *
  read_from_head true
  <parse>
    @type json
    time_format %Y-%m-%dT%H:%M:%S.%NZ
  </parse>
</source>

<source>
  @type tail
  @id in_tail_cwagent_logs
  @label @cwagentlogs
  path /var/log/containers/cloudwatch-agent*
  pos_file /var/log/cloudwatch-agent.log.pos
  tag *
  read_from_head true
  <parse>
    @type json
    time_format %Y-%m-%dT%H:%M:%S.%NZ
  </parse>
</source>

<label @containers>
  <filter **>
    @type kubernetes_metadata
    @id filter_kube_metadata
  </filter>

  <filter **>
    @type record_transformer
    @id filter_containers_stream_transformer
    <record>
      stream_name $${tag_parts[3]}
    </record>
  </filter>

  <filter **>
    @type concat
    key log
    multiline_start_regexp /^\S/
    separator ""
    flush_interval 5
    timeout_label @NORMAL
  </filter>

  <match **>
    @type relabel
    @label @NORMAL
  </match>
</label>

<label @cwagentlogs>
  <filter **>
    @type kubernetes_metadata
    @id filter_kube_metadata_cwagent
  </filter>

  <filter **>
    @type record_transformer
    @id filter_cwagent_stream_transformer
    <record>
      stream_name $${tag_parts[3]}
    </record>
  </filter>

  <filter **>
    @type concat
    key log
    multiline_start_regexp /^\d{4}[-/]\d{1,2}[-/]\d{1,2}/
    separator ""
    flush_interval 5
    timeout_label @NORMAL
  </filter>

  <match **>
    @type relabel
    @label @NORMAL
  </match>
</label>

<label @NORMAL>
  <match **>
    @type cloudwatch_logs
    @id out_cloudwatch_logs_containers
    region "#{ENV.fetch('REGION')}"
    log_group_name "/aws/containerinsights/#{ENV.fetch('CLUSTER_NAME')}/application"
    log_stream_name_key stream_name
    remove_log_stream_name_key true
    auto_create_stream true
    <buffer>
      flush_interval 5
      chunk_limit_size 2m
      queued_chunks_limit_size 32
      retry_forever true
    </buffer>
  </match>
</label>
EOF
    "systemd.conf"    = <<EOF
<source>
  @type systemd
  @id in_systemd_kubelet
  @label @systemd
  filters [{ "_SYSTEMD_UNIT": "kubelet.service" }]
  <entry>
    field_map {"MESSAGE": "message", "_HOSTNAME": "hostname", "_SYSTEMD_UNIT": "systemd_unit"}
    field_map_strict true
  </entry>
  path /var/log/journal
  <storage>
    @type local
    persistent true
    path /var/log/fluentd-journald-kubelet-pos.json
  </storage>
  read_from_head true
  tag kubelet.service
</source>

<source>
  @type systemd
  @id in_systemd_kubeproxy
  @label @systemd
  filters [{ "_SYSTEMD_UNIT": "kubeproxy.service" }]
  <entry>
    field_map {"MESSAGE": "message", "_HOSTNAME": "hostname", "_SYSTEMD_UNIT": "systemd_unit"}
    field_map_strict true
  </entry>
  path /var/log/journal
  <storage>
    @type local
    persistent true
    path /var/log/fluentd-journald-kubeproxy-pos.json
  </storage>
  read_from_head true
  tag kubeproxy.service
</source>

<source>
  @type systemd
  @id in_systemd_docker
  @label @systemd
  filters [{ "_SYSTEMD_UNIT": "docker.service" }]
  <entry>
    field_map {"MESSAGE": "message", "_HOSTNAME": "hostname", "_SYSTEMD_UNIT": "systemd_unit"}
    field_map_strict true
  </entry>
  path /var/log/journal
  <storage>
    @type local
    persistent true
    path /var/log/fluentd-journald-docker-pos.json
  </storage>
  read_from_head true
  tag docker.service
</source>

<label @systemd>
  <filter **>
    @type kubernetes_metadata
    @id filter_kube_metadata_systemd
  </filter>

  <filter **>
    @type record_transformer
    @id filter_systemd_stream_transformer
    <record>
      stream_name $${tag}-$${record["hostname"]}
    </record>
  </filter>

  <match **>
    @type cloudwatch_logs
    @id out_cloudwatch_logs_systemd
    region "#{ENV.fetch('REGION')}"
    log_group_name "/aws/containerinsights/#{ENV.fetch('CLUSTER_NAME')}/dataplane"
    log_stream_name_key stream_name
    auto_create_stream true
    remove_log_stream_name_key true
    <buffer>
      flush_interval 5
      chunk_limit_size 2m
      queued_chunks_limit_size 32
      retry_forever true
    </buffer>
  </match>
</label>
EOF
    "host.conf"       = <<EOF
<source>
  @type tail
  @id in_tail_secure
  @label @hostlogs
  path /var/log/secure
  pos_file /var/log/secure.log.pos
  tag host.secure
  read_from_head true
  <parse>
    @type syslog
  </parse>
</source>

<source>
  @type tail
  @id in_tail_messages
  @label @hostlogs
  path /var/log/messages
  pos_file /var/log/messages.log.pos
  tag host.messages
  read_from_head true
  <parse>
    @type syslog
  </parse>
</source>

<label @hostlogs>
  <filter **>
    @type kubernetes_metadata
    @id filter_kube_metadata_host
  </filter>

  <filter **>
    @type record_transformer
    @id filter_containers_stream_transformer_host
    <record>
      stream_name $${tag}-$${record["host"]}
    </record>
  </filter>

  <match host.**>
    @type cloudwatch_logs
    @id out_cloudwatch_logs_host_logs
    region "#{ENV.fetch('REGION')}"
    log_group_name "/aws/containerinsights/#{ENV.fetch('CLUSTER_NAME')}/host"
    log_stream_name_key stream_name
    remove_log_stream_name_key true
    auto_create_stream true
    <buffer>
      flush_interval 5
      chunk_limit_size 2m
      queued_chunks_limit_size 32
      retry_forever true
    </buffer>
  </match>
</label>
EOF
  }
}

resource "kubernetes_daemonset" "fluentd-cloudwatch" {
  count      = (var.cloud == "aws") && (terraform.workspace == "bootstrap") && (var.aws_enable_cloudwatch_logging) ? 1 : 0
  depends_on = [kubernetes_config_map.cluster-info-config-map, kubernetes_cluster_role_binding.fluentd-role-binding, kubernetes_config_map.fluentd-config]

  metadata {
    name      = "fluentd-cloudwatch"
    namespace = "amazon-cloudwatch"
  }

  spec {
    selector {
      match_labels = {
        "k8s-app" = "fluentd-cloudwatch"
      }
    }

    template {
      metadata {
        labels = {
          "k8s-app" = "fluentd-cloudwatch"
        }
      }

      spec {
        service_account_name             = "fluentd"
        termination_grace_period_seconds = 30
        automount_service_account_token  = true

        container {
          image = "fluent/fluentd-kubernetes-daemonset:v1.8.1-debian-cloudwatch-1.1"
          name  = "fluentd-cloudwatch"

          env {
            name = "REGION"
            value_from {
              config_map_key_ref {
                name = "cluster-info"
                key  = "logs.region"
              }
            }
          }
          env {
            name = "CLUSTER_NAME"
            value_from {
              config_map_key_ref {
                name = "cluster-info"
                key  = "cluster.name"
              }
            }
          }
          env {
            name  = "CI_VERSION"
            value = "k8s/1.0.1"
          }
          resources {
            limits {
              memory = "400Mi"
            }
            requests {
              cpu    = "100m"
              memory = "200Mi"
            }
          }
          volume_mount {
            name       = "fluentdconf"
            mount_path = "/fluentd/etc"
          }
          volume_mount {
            name       = "varlog"
            mount_path = "/var/log"
          }
          volume_mount {
            name       = "varlibdockercontainers"
            mount_path = "/var/lib/docker/containers"
            read_only  = true
          }
          volume_mount {
            name       = "runlogjournal"
            mount_path = "/run/log/journal"
            read_only  = true
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
        volume {
          name = "fluentdconf"
          config_map {
            name = "fluentd-config"
          }
        }
        volume {
          name = "varlog"
          host_path {
            path = "/var/log"
          }
        }
        volume {
          name = "varlibdockercontainers"
          host_path {
            path = "/var/lib/docker/containers"
          }
        }
        volume {
          name = "runlogjournal"
          host_path {
            path = "/run/log/journal"
          }
        }
      }
    }
  }
}
