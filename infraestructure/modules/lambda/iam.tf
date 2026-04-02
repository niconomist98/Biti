################################################################################
# IAM Policies and Roles for Lambda Module
################################################################################

# Example: S3 access policy
# Uncomment and customize based on your needs
#
# resource "aws_iam_role_policy" "lambda_s3_access" {
#   name   = "${var.function_name}-s3-access"
#   role   = aws_iam_role.lambda_role.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:ListBucket"
#         ]
#         Effect   = "Allow"
#         Resource = [
#           "arn:aws:s3:::my-bucket",
#           "arn:aws:s3:::my-bucket/*"
#         ]
#       }
#     ]
#   })
# }

# Example: DynamoDB access policy
# resource "aws_iam_role_policy" "lambda_dynamodb_access" {
#   name   = "${var.function_name}-dynamodb-access"
#   role   = aws_iam_role.lambda_role.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "dynamodb:GetItem",
#           "dynamodb:PutItem",
#           "dynamodb:UpdateItem",
#           "dynamodb:Query",
#           "dynamodb:Scan"
#         ]
#         Effect   = "Allow"
#         Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/my-table"
#       }
#     ]
#   })
# }

# Example: SNS publish policy
# resource "aws_iam_role_policy" "lambda_sns_publish" {
#   name   = "${var.function_name}-sns-publish"
#   role   = aws_iam_role.lambda_role.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "sns:Publish"
#         ]
#         Effect   = "Allow"
#         Resource = "arn:aws:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:my-topic"
#       }
#     ]
#   })
# }

# Example: SQS permissions policy
# resource "aws_iam_role_policy" "lambda_sqs_access" {
#   name   = "${var.function_name}-sqs-access"
#   role   = aws_iam_role.lambda_role.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "sqs:SendMessage",
#           "sqs:ReceiveMessage",
#           "sqs:DeleteMessage",
#           "sqs:GetQueueAttributes"
#         ]
#         Effect   = "Allow"
#         Resource = "arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:my-queue"
#       }
#     ]
#   })
# }

# Example: Secrets Manager access policy
# resource "aws_iam_role_policy" "lambda_secrets_access" {
#   name   = "${var.function_name}-secrets-access"
#   role   = aws_iam_role.lambda_role.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "secretsmanager:GetSecretValue"
#         ]
#         Effect   = "Allow"
#         Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:my-secret-*"
#       }
#     ]
#   })
# }

# Data source for current AWS account
data "aws_caller_identity" "current" {}
