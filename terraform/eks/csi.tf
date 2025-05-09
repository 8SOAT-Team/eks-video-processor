resource "aws_iam_role" "ebs_csi_irsa_role" {
  name = "ebs-csi-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::585008076257:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/2B8CC646D06164A5E063E9AAEB1A7736"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "oidc.eks.us-east-1.amazonaws.com/id/2B8CC646D06164A5E063E9AAEB1A7736:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            "oidc.eks.us-east-1.amazonaws.com/id/2B8CC646D06164A5E063E9AAEB1A7736:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ebs_csi_driver_policy" {
  name = "ebs-csi-driver-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:*"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ebs_policy" {
  role       = aws_iam_role.ebs_csi_irsa_role.name
  policy_arn = aws_iam_policy.ebs_csi_driver_policy.arn
}

