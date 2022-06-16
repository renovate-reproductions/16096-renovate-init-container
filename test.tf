

resource "kubernetes_deployment" "octant" {
  count = 1
  metadata {
    name      = "octant"
  }
  spec {
    replicas = 2
    selector {
      match_labels = { app = "octant" }
    }
    template {
      spec {
       
        init_container {
          name    = "init-sh"
          image   = "amazon/aws-cli:2.7.7"
        }

        container {
          name  = "node"
          image = "python:3.6"
        }

        container {
          name  = "octant"
          image = "amazon/aws-cli:2.7.7"
         
        }

        init_container {
          name  = "node"
          image = "node:14"
        }
       
      }
    }
   
  }
}

