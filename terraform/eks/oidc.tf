# Acessa os dados do cluster já existente
data "aws_eks_cluster" "cluster" {
  name = "video-processor-eks-cluster"
}

# Captura o certificado TLS do issuer do OIDC
data "tls_certificate" "eks" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc.issuer
}

# Cria o OIDC provider no IAM com o issuer e thumbprint do certificado
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = data.aws_eks_cluster.cluster.identity[0].oidc.issuer
}
