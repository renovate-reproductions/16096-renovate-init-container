

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
          image = "amazon/aws-cli:2.6.4"
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

