resource "aws_iam_role" "irsa_sqs_role" {
  name = "notificacao-api-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::585008076257:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/BDADA465F58847FCCD04B087060C4552"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "oidc.eks.us-east-1.amazonaws.com/id/BDADA465F58847FCCD04B087060C4552:aud" = "sts.amazonaws.com"
          },
          "StringLike" = {
            "oidc.eks.us-east-1.amazonaws.com/id/BDADA465F58847FCCD04B087060C4552:sub" = [
              "system:serviceaccount:fast-video:notificacao-api-sa",
              "system:serviceaccount:fast-video:curl-debug-sa"
            ]
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
