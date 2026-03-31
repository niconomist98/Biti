################################################################################
# IAM Policies and Roles for EC2 Module
################################################################################

# Example: S3 access policy
# Uncomment and customize based on your needs
#
# resource "aws_iam_role_policy" "ec2_s3_access" {
#   name   = "${var.instance_name}-s3-access"
#   role   = aws_iam_role.ec2_role.id
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
# resource "aws_iam_role_policy" "ec2_dynamodb_access" {
#   name   = "${var.instance_name}-dynamodb-access"
#   role   = aws_iam_role.ec2_role.id
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

# Example: RDS database access
# resource "aws_iam_role_policy" "ec2_rds_auth" {
#   name   = "${var.instance_name}-rds-auth"
#   role   = aws_iam_role.ec2_role.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "rds-db:connect"
#         ]
#         Effect   = "Allow"
#         Resource = "arn:aws:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:db:*"
#       }
#     ]
#   })
# }

# Example: EC2 describe policy for auto-discovery
# resource "aws_iam_role_policy" "ec2_describe" {
#   name   = "${var.instance_name}-ec2-describe"
#   role   = aws_iam_role.ec2_role.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "ec2:DescribeInstances",
#           "ec2:DescribeTags"
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#       }
#     ]
#   })
# }

# Example: Secrets Manager access policy
# resource "aws_iam_role_policy" "ec2_secrets_access" {
#   name   = "${var.instance_name}-secrets-access"
#   role   = aws_iam_role.ec2_role.id
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

# Example: SNS publish policy
# resource "aws_iam_role_policy" "ec2_sns_publish" {
#   name   = "${var.instance_name}-sns-publish"
#   role   = aws_iam_role.ec2_role.id
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
# resource "aws_iam_role_policy" "ec2_sqs_access" {
#   name   = "${var.instance_name}-sqs-access"
#   role   = aws_iam_role.ec2_role.id
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

# Data source for current AWS account
data "aws_caller_identity" "current" {}
