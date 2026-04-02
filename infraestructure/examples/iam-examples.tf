# IAM Role Examples

# Example 1: Lambda execution role with S3 and DynamoDB access
module "lambda_execution_role" {
  source = "../modules/iam"

  role_name        = "lambda-s3-dynamodb-role"
  role_description = "Lambda execution role with S3 and DynamoDB permissions"
  trust_entity_type = "Service"
  trust_entity_identifiers = ["lambda.amazonaws.com"]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  inline_policies = {
    s3-read = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:ListBucket"
          ]
          Resource = [
            "arn:aws:s3:::input-bucket",
            "arn:aws:s3:::input-bucket/*"
          ]
        }
      ]
    })

    dynamodb-write = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "dynamodb:Query"
          ]
          Resource = "arn:aws:dynamodb:*:*:table/ProcessedData"
        }
      ]
    })
  }

  tags = {
    Environment = "production"
    Application = "data-processor"
  }
}

# Example 2: EC2 instance role with Systems Manager access
module "ec2_systems_manager_role" {
  source = "../modules/iam"

  role_name        = "ec2-systems-manager-role"
  role_description = "EC2 role for Systems Manager management"
  trust_entity_type = "Service"
  trust_entity_identifiers = ["ec2.amazonaws.com"]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]

  create_instance_profile = true

  tags = {
    Environment = "production"
    Type        = "web-server"
  }
}

# Example 3: Cross-account access role with MFA requirement
module "cross_account_admin_role" {
  source = "../modules/iam"

  role_name                       = "cross-account-admin"
  role_description                = "Cross-account admin access with MFA"
  trust_entity_type               = "AWS"
  trust_entity_identifiers        = ["arn:aws:iam::111111111111:root"]
  enable_cloudtrail               = true
  log_retention_days              = 90

  assume_role_conditions = [
    {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  ]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]

  tags = {
    Security   = "high"
    Compliance = "required"
  }
}

# Example 4: CI/CD deployment role with permission boundary
module "cicd_deployment_role" {
  source = "../modules/iam"

  role_name                = "cicd-deployment-role"
  role_description         = "CI/CD role with permission boundary"
  trust_entity_type        = "AWS"
  trust_entity_identifiers = ["arn:aws:iam::123456789012:role/GitHubActionsRole"]

  permission_boundary_arn = "arn:aws:iam::aws:policy/PowerUserAccess"

  inline_policies = {
    ec2-deployment = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ec2:*",
            "autoscaling:*",
            "elb:*"
          ]
          Resource = "*"
        }
      ]
    })

    iam-management = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "iam:PassRole",
            "iam:GetRole",
            "iam:ListRoles"
          ]
          Resource = "arn:aws:iam::*:role/app-*"
        }
      ]
    })
  }

  tags = {
    Application = "ci-cd"
    Team        = "platform"
  }
}

# Example 5: SageMaker execution role with specialized permissions
module "sagemaker_execution_role" {
  source = "../modules/iam"

  role_name        = "sagemaker-execution-role"
  role_description = "SageMaker execution with model and ECR access"
  trust_entity_type = "Service"
  trust_entity_identifiers = ["sagemaker.amazonaws.com"]

  inline_policies = {
    s3-access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
            "s3:ListBucket"
          ]
          Resource = [
            "arn:aws:s3:::sagemaker-models/*",
            "arn:aws:s3:::sagemaker-models"
          ]
        }
      ]
    })

    ecr-access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ecr:GetAuthorizationToken",
            "ecr:BatchGetImage",
            "ecr:GetDownloadUrlForLayer"
          ]
          Resource = "*"
        }
      ]
    })

    cloudwatch-logs = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams"
          ]
          Resource = "arn:aws:logs:*:*:log-group:/aws/sagemaker/*"
        }
      ]
    })
  }

  tags = {
    Application = "ml-models"
    Team        = "data-science"
  }
}
