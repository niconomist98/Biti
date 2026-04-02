variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

# S3 Bucket Deployment

module "biti_s3" {
  source = "../../modules/s3"

  bucket_name        = "biti-data-${var.environment}"
  enable_versioning  = true
  block_public_access = true
  enable_logging     = false

  tags = {
    Project     = "Biti"
    Environment = var.environment
  }
}

output "s3_bucket_id" {
  value = module.biti_s3.bucket_id
}

output "s3_bucket_arn" {
  value = module.biti_s3.bucket_arn
}
