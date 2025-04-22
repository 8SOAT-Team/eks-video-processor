resource "aws_iam_role" "irsa_sqs_role" {
  name = "notificacao-api-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::585008076257:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/3B3D9AC7DA39D280541FF3C278EF3B84"
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

resource "aws_iam_role_policy_attachment" "attach_sqs_policy" {
  role       = aws_iam_role.irsa_sqs_role.name
  policy_arn = aws_iam_policy.sqs_policy.arn
}