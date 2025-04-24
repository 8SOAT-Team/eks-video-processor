resource "aws_iam_role" "irsa_sqs_role" {
  name = "notificacao-api-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::585008076257:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/82DA2C40F79BA121CDD7B264E92BAE8D"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "oidc.eks.us-east-1.amazonaws.com/id/82DA2C40F79BA121CDD7B264E92BAE8D:sub" = "system:serviceaccount:fast-video:notificacao-api-sa",
            "oidc.eks.us-east-1.amazonaws.com/id/82DA2C40F79BA121CDD7B264E92BAE8D:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "sqs_policy" {
  name = "notificacao-api-sqs-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:*",
          "sns:*",
          "rds:*"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_sqs_policy" {
  role       = aws_iam_role.irsa_sqs_role.name
  policy_arn = aws_iam_policy.sqs_policy.arn
}
