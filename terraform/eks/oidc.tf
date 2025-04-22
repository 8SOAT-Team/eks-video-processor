data "aws_eks_cluster" "cluster" {
  name = "video-processor-eks-cluster"
}

data "tls_certificate" "eks" {
  url = data.aws_eks_cluster.cluster.identity.oidc.issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = data.aws_eks_cluster.cluster.identity.oidc.issuer
}
