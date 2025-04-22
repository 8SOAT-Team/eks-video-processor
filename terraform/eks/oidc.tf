data "tls_certificate" "eks" {
  url = "https://oidc.eks.us-east-1.amazonaws.com/id/3B3D9AC7DA39D280541FF3C278EF3B84"
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = "https://oidc.eks.us-east-1.amazonaws.com/id/3B3D9AC7DA39D280541FF3C278EF3B84"
}

resource "aws_iam_role" "irsa_sqs_role" {
  name = "notificacao-api-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "oidc.eks.us-east-1.amazonaws.com/id/3B3D9AC7DA39D280541FF3C278EF3B84:sub" = "system:serviceaccount:fast-video:notificacao-api-sa",
            "oidc.eks.us-east-1.amazonaws.com/id/3B3D9AC7DA39D280541FF3C278EF3B84:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Policy com permissões para consumir SQS
resource "aws_iam_policy" "sqs_policy" {
  name = "notificacao-api-sqs-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = "*"
      }
    ]
  })
}

