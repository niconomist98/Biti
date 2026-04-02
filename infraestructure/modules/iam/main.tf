# AWS IAM Module - Role and Policy Management
# Provides comprehensive IAM role management with fine-grained permissions

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# IAM Role
resource "aws_iam_role" "main" {
  name                 = var.role_name
  description          = var.role_description
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  max_session_duration = var.max_session_duration

  tags = merge(
    var.tags,
    {
      Name = var.role_name
    }
  )
}

# AssumeRole Trust Policy
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = var.trust_entity_type
      identifiers = var.trust_entity_identifiers
    }

    dynamic "condition" {
      for_each = var.assume_role_conditions
      content {
        test     = condition.value.test
        variable = condition.value.variable
        values   = condition.value.values
      }
    }
  }
}

# Inline Policies
resource "aws_iam_role_policy" "inline" {
  for_each = var.inline_policies

  name   = "${var.role_name}-${each.key}"
  role   = aws_iam_role.main.id
  policy = each.value
}

# Managed Policy Attachments
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.main.name
  policy_arn = each.value
}

# Custom Managed Policy
resource "aws_iam_policy" "custom" {
  count = var.create_custom_policy ? 1 : 0

  name        = "${var.role_name}-policy"
  description = "Custom policy for ${var.role_name}"
  policy      = var.custom_policy_document

  tags = merge(
    var.tags,
    {
      Name = "${var.role_name}-policy"
    }
  )
}

# Attach Custom Managed Policy
resource "aws_iam_role_policy_attachment" "custom" {
  count = var.create_custom_policy ? 1 : 0

  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.custom[0].arn
}

# Instance Profile (for EC2)
resource "aws_iam_instance_profile" "main" {
  count = var.create_instance_profile ? 1 : 0

  name = "${var.role_name}-profile"
  role = aws_iam_role.main.name
}

# Permission Boundary
resource "aws_iam_role" "main_with_boundary" {
  count = var.permission_boundary_arn != "" ? 1 : 0

  name                 = "${var.role_name}-bounded"
  description          = "${var.role_description} (with permission boundary)"
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  max_session_duration = var.max_session_duration
  permissions_boundary = var.permission_boundary_arn

  tags = merge(
    var.tags,
    {
      Name = "${var.role_name}-bounded"
    }
  )
}

# Session Tags for ABAC
resource "aws_iam_role_policy" "session_tags" {
  count = length(var.session_tags) > 0 ? 1 : 0

  name   = "${var.role_name}-session-tags"
  role   = aws_iam_role.main.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:TagSession"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:PrincipalTag/session" = values(var.session_tags)
          }
        }
      }
    ]
  })
}

# CloudWatch Logging for IAM Activity
resource "aws_cloudwatch_log_group" "iam_access" {
  count = var.enable_iam_access_logging ? 1 : 0

  name              = "/aws/iam/${var.role_name}/access"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name = "${var.role_name}-access-logs"
    }
  )
}

# CloudTrail for IAM Activity (optional)
resource "aws_cloudtrail" "iam_activity" {
  count = var.enable_cloudtrail ? 1 : 0

  name                          = "${var.role_name}-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail[0].id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  depends_on                    = [aws_s3_bucket_policy.cloudtrail[0]]

  tags = merge(
    var.tags,
    {
      Name = "${var.role_name}-trail"
    }
  )
}

# S3 Bucket for CloudTrail
resource "aws_s3_bucket" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = "${var.role_name}-cloudtrail-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name = "${var.role_name}-cloudtrail-bucket"
    }
  )
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  count = var.enable_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail[0].arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
