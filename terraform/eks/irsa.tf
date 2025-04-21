resource "aws_iam_role" "irsa_sqs_role" {
  name = "video-processor-irsa-sqs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${data.aws_eks_cluster.cluster.identity[0].oidc.issuer}"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(data.aws_eks_cluster.cluster.identity[0].oidc.issuer, "https://", "")}:sub" = "system:serviceaccount:fast-video:notificacao-api-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "irsa_sqs_policy" {
  name = "video-processor-irsa-sqs-policy"
  role = aws_iam_role.irsa_sqs_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:*"
        ],
        Resource = "*"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.video_processor_cluster.name
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.video_processor_cluster.name
}
