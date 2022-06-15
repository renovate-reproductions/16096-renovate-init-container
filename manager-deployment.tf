
resource "kubernetes_config_map" "init" {
  count = 1
  metadata {
    name      = "init-sh"
    namespace = "default"
  }
  data = {
    "init.sh" = "Script"
  }
}

resource "kubernetes_config_map" "reporting" {
  count = 1
  metadata {
    name      = "reporting"
    namespace = "default"
  }
  data = {
    "reporting.sh" = "Report"
  }
}

resource "kubernetes_deployment" "octant" {
  count = 1
  metadata {
    name      = "octant"
    namespace = "default"
    labels    = { app = "octant" }
  }
  spec {
    replicas = 2
    selector {
      match_labels = { app = "octant" }
    }
    template {
      metadata {}
      spec {
        volume {
          name = "data"
          secret {
            secret_name  = "data"
            default_mode = "0400"
          }
        }
        volume {
          name = "init-sh"
          config_map {
            name         = "init-sh"
            default_mode = "0750"
          }
        }
        volume {
          name = "share"
          empty_dir {
            medium = "Memory"
          }
        }
        init_container {
          name    = "init-sh"
          image   = "amazon/aws-cli:2.6.4"
          command = ["/init/init.sh"]
          env {
            name  = "USE_CONTEXT"
            value = "PROD"
          }
          env {
            name  = "KUBE_ACCESS_FILE"
            value = "/access"
          }
          volume_mount {
            name       = "init-sh"
            read_only  = true
            mount_path = "/init"
          }
          volume_mount {
            name              = "data"
            read_only         = true
            mount_path        = "/tmp/data"
            mount_propagation = "None"
          }
          volume_mount {
            name       = "share"
            mount_path = "/kube"
          }
          termination_message_path = "/dev/termination-log"
          image_pull_policy        = "IfNotPresent"
        }
        container {
          name  = "octant"
          image = "amazon/aws-cli:2.7.7"
          volume_mount {
            name       = "share"
            read_only  = true
            mount_path = "/kubeconfig"
          }
          termination_message_path = "/dev/termination-log"
          image_pull_policy        = "Always"
        }
        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        dns_policy                       = "ClusterFirst"
        service_account_name             = "default"
        security_context {
          run_as_user     = 1000
          run_as_group    = 1000
          run_as_non_root = true
          fs_group        = 1000
        }
        node_selector = { "kubernetes.io/os" = "linux", "kubernetes.io/arch" = "amd64" }
      }
    }
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_unavailable = "25%"
        max_surge       = "25%"
      }
    }
    revision_history_limit    = 10
    progress_deadline_seconds = 600
  }
}

resource "kubernetes_cron_job" "cmo_reporting" {
  count = var.activate_reporting ? 1 : 0
  metadata {
    name      = "cmo-reporting"
    namespace = "octant"
  }
  spec {
    schedule                  = "0 0 * * *"
    starting_deadline_seconds = 500
    job_template {
      metadata {
      }
      spec {
        template {
          metadata {
          }
          spec {
            volume {
              name = "reporting-sh"
              config_map {
                name         = "reporting"
                default_mode = "0750"
              }
            }
            volume {
              name = "data"
              secret {
                secret_name  = "data"
                default_mode = "0400"
              }
            }
            volume {
              name = "init-sh"
              config_map {
                name         = "init-sh"
                default_mode = "0750"
              }
            }
            volume {
              name = "share"
              empty_dir {
                medium = "Memory"
              }
            }
            init_container {
              name  = "init-sh"
              image = "amazon/aws-cli:2.6.4"
              args  = ["/init/init.sh"]
              env {
                name  = "USE_CONTEXT"
                value = "PORD"
              }
              env {
                name  = "KUBE_ACCESS_FILE"
                value = "access.secret"
              }
              volume_mount {
                name              = "init-sh"
                read_only         = true
                mount_path        = "/init"
                mount_propagation = "None"
              }
              volume_mount {
                name              = "data"
                read_only         = true
                mount_path        = "/tmp/data"
                mount_propagation = "None"
              }
              volume_mount {
                name              = "share"
                mount_path        = "/kube"
                mount_propagation = "None"
              }
              image_pull_policy = "IfNotPresent"
            }
            container {
              name  = "cmo-reporting"
              image = "amazon/aws-cli:2.7.7"
              args  = ["/init/reporting.sh"]
              env {
                name  = "HOME"
                value = "/tmp"
              }
              env {
                name  = "RECIPIENT"
                value = "blablub@googlemail.com"
              }
              volume_mount {
                name              = "reporting-sh"
                read_only         = true
                mount_path        = "/init"
                mount_propagation = "None"
              }
              volume_mount {
                name              = "share"
                read_only         = true
                mount_path        = "/kubeconfig"
                mount_propagation = "None"
              }
            }
            restart_policy       = "OnFailure"
            service_account_name = "octant"
            security_context {
              run_as_user     = 1000
              run_as_group    = 1000
              run_as_non_root = true
              fs_group        = 1000
            }
            node_selector = { "kubernetes.io/os" = "linux", "kubernetes.io/arch" = "amd64" }
          }
        }
      }
    }
  }
}
