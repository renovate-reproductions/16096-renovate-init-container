resource "kubernetes_cron_job" "cmo_reporting" {
  count = 1
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
              name  = "node"
              image = "node:14"
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
