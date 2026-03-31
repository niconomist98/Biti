################################################################################
# AWS S3 Module
# Deploys S3 buckets with comprehensive configuration, security, versioning,
# lifecycle rules, logging, encryption, and monitoring.
################################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Create S3 bucket
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name

  tags = var.tags
}

# Enable bucket versioning
resource "aws_s3_bucket_versioning" "bucket" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  versioning_configuration {
    status     = "Enabled"
    mfa_delete = var.enable_mfa_delete
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm      = var.encryption_algorithm
      kms_master_key_id  = var.encryption_algorithm == "aws:kms" ? var.kms_key_id : null
    }
    bucket_key_enabled = var.encryption_algorithm == "aws:kms"
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

# Enable ACL
resource "aws_s3_bucket_acl" "bucket" {
  count  = var.acl != null ? 1 : 0
  bucket = aws_s3_bucket.bucket.id
  acl    = var.acl

  depends_on = [aws_s3_bucket_public_access_block.bucket]
}

# Bucket logging
resource "aws_s3_bucket_logging" "bucket" {
  count  = var.logging_bucket != null ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  target_bucket = var.logging_bucket
  target_prefix = var.logging_prefix
}

# CORS configuration
resource "aws_s3_bucket_cors_configuration" "bucket" {
  count  = var.cors_rules != null ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  dynamic "cors_rule" {
    for_each = var.cors_rules != null ? var.cors_rules : []

    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = cors_rule.value.expose_headers
      max_age_seconds = cors_rule.value.max_age_seconds
    }
  }
}

# Lifecycle rules
resource "aws_s3_bucket_lifecycle_configuration" "bucket" {
  count  = var.lifecycle_rules != null ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  dynamic "rule" {
    for_each = var.lifecycle_rules != null ? var.lifecycle_rules : []

    content {
      id     = rule.value.id
      status = rule.value.status != null ? rule.value.status : "Enabled"

      dynamic "transition" {
        for_each = rule.value.transitions != null ? rule.value.transitions : []

        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? [rule.value.expiration_days] : []

        content {
          days = expiration.value
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_transitions != null ? rule.value.noncurrent_transitions : []

        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_expiration_days != null ? [rule.value.noncurrent_expiration_days] : []

        content {
          noncurrent_days = noncurrent_version_expiration.value
        }
      }

      dynamic "filter" {
        for_each = rule.value.prefix != null ? [rule.value.prefix] : []

        content {
          prefix = filter.value
        }
      }
    }
  }
}

# Request metrics configuration
resource "aws_s3_bucket_metric" "bucket" {
  count  = var.enable_metrics ? 1 : 0
  bucket = aws_s3_bucket.bucket.id
  name   = "${var.bucket_name}-metrics"
}

# Bucket policy
resource "aws_s3_bucket_policy" "bucket" {
  count  = var.bucket_policy != null ? 1 : 0
  bucket = aws_s3_bucket.bucket.id
  policy = var.bucket_policy
}

# Website configuration
resource "aws_s3_bucket_website_configuration" "bucket" {
  count  = var.enable_website ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  index_document {
    suffix = var.index_document
  }

  dynamic "error_document" {
    for_each = var.error_document != null ? [var.error_document] : []

    content {
      key = error_document.value
    }
  }

  dynamic "routing_rule" {
    for_each = var.routing_rules != null ? var.routing_rules : []

    content {
      condition {
        http_error_code_returned_equals = routing_rule.value.error_code
        key_prefix_equals               = routing_rule.value.prefix
      }

      redirect {
        http_redirect_code = "301"
        host_name          = routing_rule.value.redirect_host
        protocol           = "https"
        replace_key_prefix_with = routing_rule.value.replace_prefix
      }
    }
  }
}

# CloudFront origin access control (for CDN)
resource "aws_cloudfront_origin_access_control" "bucket" {
  count           = var.enable_cloudfront_access ? 1 : 0
  name            = "${var.bucket_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Bucket replication configuration
resource "aws_s3_bucket_replication_configuration" "bucket" {
  count  = var.replication_config != null ? 1 : 0
  role   = aws_iam_role.replication[0].arn
  bucket = aws_s3_bucket.bucket.id

  depends_on = [aws_s3_bucket_versioning.bucket]

  dynamic "rule" {
    for_each = var.replication_config.rules

    content {
      id     = rule.value.id
      status = rule.value.status != null ? rule.value.status : "Enabled"

      filter {
        prefix = rule.value.prefix
      }

      destination {
        bucket       = "arn:aws:s3:::${rule.value.destination_bucket}"
        storage_class = rule.value.storage_class

        dynamic "replication_time" {
          for_each = rule.value.replication_time_minutes != null ? [rule.value.replication_time_minutes] : []

          content {
            status = "Enabled"
            time {
              minutes = replication_time.value
            }
          }
        }
      }
    }
  }
}

# IAM role for replication
resource "aws_iam_role" "replication" {
  count = var.replication_config != null ? 1 : 0
  name  = "${var.bucket_name}-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM policy for replication
resource "aws_iam_role_policy" "replication" {
  count  = var.replication_config != null ? 1 : 0
  name   = "${var.bucket_name}-replication-policy"
  role   = aws_iam_role.replication[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.bucket.arn
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.bucket.arn}/*"
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${var.replication_config.destination_bucket}/*"
      }
    ]
  })
}

# Access logs bucket (for storing logs)
resource "aws_s3_bucket" "access_logs" {
  count  = var.enable_logging && var.logging_bucket == null ? 1 : 0
  bucket = "${var.bucket_name}-logs"

  tags = merge(
    var.tags,
    { Name = "${var.bucket_name}-logs" }
  )
}

resource "aws_s3_bucket_versioning" "access_logs" {
  count  = var.enable_logging && var.logging_bucket == null ? 1 : 0
  bucket = aws_s3_bucket.access_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  count  = var.enable_logging && var.logging_bucket == null ? 1 : 0
  bucket = aws_s3_bucket.access_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  count  = var.enable_logging && var.logging_bucket == null ? 1 : 0
  bucket = aws_s3_bucket.access_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudWatch alarms for bucket metrics
resource "aws_cloudwatch_metric_alarm" "bucket_size" {
  count               = var.create_size_alarm ? 1 : 0
  alarm_name          = "${var.bucket_name}-size-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = 86400
  statistic           = "Average"
  threshold           = var.size_threshold
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName = aws_s3_bucket.bucket.id
    StorageType = "StandardStorageSize"
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "object_count" {
  count               = var.create_count_alarm ? 1 : 0
  alarm_name          = "${var.bucket_name}-object-count-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfObjects"
  namespace           = "AWS/S3"
  period              = 86400
  statistic           = "Average"
  threshold           = var.object_count_threshold
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName = aws_s3_bucket.bucket.id
    StorageType = "AllStorageTypes"
  }

  tags = var.tags
}

# Output CloudFront OAC for use with CDN
resource "aws_s3_bucket_policy" "cloudfront_access" {
  count  = var.enable_cloudfront_access ? 1 : 0
  bucket = aws_s3_bucket.bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/*"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.bucket]
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
