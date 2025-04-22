data "tls_certificate" "eks" {
  url = "https://oidc.eks.us-east-1.amazonaws.com/id/3B3D9AC7DA39D280541FF3C278EF3B84"
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = "https://oidc.eks.us-east-1.amazonaws.com/id/3B3D9AC7DA39D280541FF3C278EF3B84"
}
