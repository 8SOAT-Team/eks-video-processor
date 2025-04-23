resource "aws_iam_role" "irsa_sqs_role" {
#   name = "notificacao-api-irsa-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Federated = "arn:aws:iam::585008076257:oidc.eks.us-east-1.amazonaws.com/id/CBED507BC69DD79D5BD204812F1E0533"
#         },
#         Action = "sts:AssumeRoleWithWebIdentity",
#         Condition = {
#           StringEquals = {
#             "oidc.eks.us-east-1.amazonaws.com/id/7A537DEE0765B3CB34001EEAE1288D8D:sub" = "system:serviceaccount:fast-video:notificacao-api-sa",
#             "oidc.eks.us-east-1.amazonaws.com/id/7A537DEE0765B3CB34001EEAE1288D8D:aud" = "sts.amazonaws.com"
#           }
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_policy" "sqs_policy" {
#   name = "notificacao-api-sqs-policy"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "sqs:ReceiveMessage",
#           "sqs:DeleteMessage",
#           "sqs:GetQueueAttributes"
#         ],
#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "attach_sqs_policy" {
#   role       = aws_iam_role.irsa_sqs_role.name
#   policy_arn = aws_iam_policy.sqs_policy.arn
# }
