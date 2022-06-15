provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.interface.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.interface.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.region]
      command     = "aws"
    }
  }
}
