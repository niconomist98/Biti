################################################################################
# S3 Module - Basic Example
# Simple private bucket for application data
################################################################################

data "aws_caller_identity" "current" {}

# Create basic S3 bucket with versioning
module "app_data_bucket" {
  source = "../modules/s3"

  bucket_name = "app-data-${data.aws_caller_identity.current.account_id}"

  # Security settings
  block_public_access = true
  
  # Versioning for data protection
  enable_versioning = true
  
  # Encryption
  encryption_algorithm = "AES256"

  # Logging
  enable_logging  = true
  logging_prefix  = "logs/"

  tags = {
    Environment = "production"
    Owner       = "platform-team"
    Purpose     = "application-data"
  }
}

# Outputs
output "bucket_id" {
  value = module.app_data_bucket.bucket_id
}

output "bucket_arn" {
  value = module.app_data_bucket.bucket_arn
}

output "bucket_domain_name" {
  value = module.app_data_bucket.bucket_domain_name
}
