################################################################################
# S3 Module - Advanced Example
# Data lake with lifecycle management and cross-region replication
################################################################################

data "aws_caller_identity" "current" {}

# SNS topic for S3 alarms
resource "aws_sns_topic" "s3_alerts" {
  name = "s3-alerts"

  tags = {
    Environment = "production"
  }
}

# KMS key for encryption
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Environment = "production"
  }
}

# Primary data lake bucket (US East)
module "data_lake_primary" {
  source = "../modules/s3"

  bucket_name = "data-lake-primary-${data.aws_caller_identity.current.account_id}"

  # Security
  block_public_access = true
  
  # Encryption with KMS
  encryption_algorithm = "aws:kms"
  kms_key_id          = aws_kms_key.s3.id

  # Versioning for data protection
  enable_versioning = true
  enable_mfa_delete = false  # Set to true if using MFA

  # Logging
  enable_logging  = true
  logging_prefix  = "logs/"

  # Lifecycle rules for cost optimization
  lifecycle_rules = [
    {
      id     = "archive_old_data"
      status = "Enabled"
      prefix = "archive/"

      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        },
        {
          days          = 365
          storage_class = "DEEP_ARCHIVE"
        }
      ]

      expiration_days = 2555  # 7 years
    },
    {
      id     = "delete_temp_files"
      status = "Enabled"
      prefix = "temp/"

      expiration_days = 7
    },
    {
      id     = "cleanup_incomplete_uploads"
      status = "Enabled"

      transitions = [
        {
          days          = 30
          storage_class = "GLACIER"
        }
      ]

      noncurrent_expiration_days = 90
    }
  ]

  # Replication to backup region
  replication_config = {
    destination_bucket = "data-lake-backup-${data.aws_caller_identity.current.account_id}"
    rules = [
      {
        id     = "replicate_all"
        status = "Enabled"
        prefix = ""
        storage_class = "STANDARD_IA"
        replication_time_minutes = 15
      }
    ]
  }

  # CORS for web access
  cors_rules = [
    {
      allowed_methods = ["GET", "PUT", "POST"]
      allowed_origins = ["https://example.com"]
      allowed_headers = ["*"]
      expose_headers  = ["ETag", "x-amz-version-id"]
      max_age_seconds = 3000
    }
  ]

  # Metrics and monitoring
  enable_metrics      = true
  create_size_alarm   = true
  size_threshold      = 1099511627776  # 1 TB
  create_count_alarm  = true
  object_count_threshold = 5000000  # 5 million objects
  alarm_actions       = [aws_sns_topic.s3_alerts.arn]

  tags = {
    Environment = "production"
    Service     = "data-lake"
    Team        = "data-engineering"
    Purpose     = "primary"
  }
}

# Replica/backup bucket (US West)
module "data_lake_replica" {
  source = "../modules/s3"
  providers = {
    aws = aws.us-west-2
  }

  bucket_name = "data-lake-backup-${data.aws_caller_identity.current.account_id}"

  # Security
  block_public_access = true
  
  # Encryption
  encryption_algorithm = "aws:kms"
  kms_key_id          = aws_kms_key.s3_replica.id

  # Versioning
  enable_versioning = true

  # Lifecycle for backup cost optimization
  lifecycle_rules = [
    {
      id     = "archive_old_backups"
      status = "Enabled"

      transitions = [
        {
          days          = 90
          storage_class = "GLACIER"
        },
        {
          days          = 365
          storage_class = "DEEP_ARCHIVE"
        }
      ]

      expiration_days = 2555
    }
  ]

  # Metrics and monitoring
  enable_metrics      = true
  create_size_alarm   = true
  size_threshold      = 1099511627776
  alarm_actions       = [aws_sns_topic.s3_alerts_replica.arn]

  tags = {
    Environment = "production"
    Service     = "data-lake"
    Team        = "data-engineering"
    Purpose     = "backup"
  }
}

# KMS key for replica region
resource "aws_kms_key" "s3_replica" {
  provider                = aws.us-west-2
  description             = "KMS key for S3 encryption in US West"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Environment = "production"
  }
}

# SNS topic for replica region alarms
resource "aws_sns_topic" "s3_alerts_replica" {
  provider = aws.us-west-2
  name     = "s3-alerts-replica"

  tags = {
    Environment = "production"
  }
}

# Static website bucket (separate)
module "website_bucket" {
  source = "../modules/s3"

  bucket_name = "website-${data.aws_caller_identity.current.account_id}"

  # Public-read for website
  block_public_access = true  # Still block but use CloudFront
  
  # Website configuration
  enable_website  = true
  index_document  = "index.html"
  error_document  = "404.html"

  # CORS for web access
  cors_rules = [
    {
      allowed_methods = ["GET"]
      allowed_origins = ["*"]
      max_age_seconds = 86400
    }
  ]

  # CloudFront distribution access
  enable_cloudfront_access = true

  # Lifecycle for website assets
  lifecycle_rules = [
    {
      id     = "cache_busting"
      status = "Enabled"
      prefix = "temp/"

      expiration_days = 1
    }
  ]

  tags = {
    Environment = "production"
    Service     = "website"
  }
}

# Configure providers for multi-region
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  alias  = "us-west-2"
  region = "us-west-2"
}

# Outputs for primary region
output "data_lake_primary_bucket" {
  value = module.data_lake_primary.bucket_id
}

output "data_lake_primary_arn" {
  value = module.data_lake_primary.bucket_arn
}

output "data_lake_replica_bucket" {
  value = module.data_lake_replica.bucket_id
}

output "website_bucket" {
  value = module.website_bucket.bucket_id
}

output "website_endpoint" {
  value = module.website_bucket.bucket_website_endpoint
}

output "cloudfront_oac_id" {
  value = module.website_bucket.cloudfront_oac_id
}
