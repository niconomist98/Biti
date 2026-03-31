################################################################################
# S3 Module - Outputs
################################################################################

output "bucket_id" {
  description = "S3 bucket ID"
  value       = aws_s3_bucket.bucket.id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.bucket.arn
}

output "bucket_domain_name" {
  description = "S3 bucket domain name"
  value       = aws_s3_bucket.bucket.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "S3 bucket regional domain name"
  value       = aws_s3_bucket.bucket.bucket_regional_domain_name
}

output "bucket_region" {
  description = "S3 bucket region"
  value       = aws_s3_bucket.bucket.region
}

output "bucket_versioning_enabled" {
  description = "Whether versioning is enabled"
  value       = var.enable_versioning
}

output "bucket_encryption_algorithm" {
  description = "Server-side encryption algorithm"
  value       = var.encryption_algorithm
}

output "bucket_logging_enabled" {
  description = "Whether logging is enabled"
  value       = var.enable_logging
}

output "bucket_website_endpoint" {
  description = "Website endpoint"
  value       = var.enable_website ? aws_s3_bucket_website_configuration.bucket[0].website_endpoint : null
}

output "bucket_website_domain" {
  description = "Website domain name"
  value       = var.enable_website ? aws_s3_bucket_website_configuration.bucket[0].website_domain : null
}

output "bucket_policy_applied" {
  description = "Whether bucket policy is applied"
  value       = var.bucket_policy != null ? true : false
}

output "access_logs_bucket" {
  description = "Access logs bucket name"
  value       = var.enable_logging && var.logging_bucket == null ? aws_s3_bucket.access_logs[0].id : var.logging_bucket
}

output "cloudfront_oac_id" {
  description = "CloudFront Origin Access Control ID"
  value       = var.enable_cloudfront_access ? aws_cloudfront_origin_access_control.bucket[0].id : null
}

output "cloudfront_oac_arn" {
  description = "CloudFront Origin Access Control ARN"
  value       = var.enable_cloudfront_access ? aws_cloudfront_origin_access_control.bucket[0].arn : null
}

output "replication_enabled" {
  description = "Whether replication is enabled"
  value       = var.replication_config != null ? true : false
}

output "replication_role_arn" {
  description = "IAM role ARN for replication"
  value       = var.replication_config != null ? aws_iam_role.replication[0].arn : null
}

output "metrics_enabled" {
  description = "Whether metrics are enabled"
  value       = var.enable_metrics
}

output "size_alarm_arn" {
  description = "Size alarm ARN"
  value       = var.create_size_alarm ? aws_cloudwatch_metric_alarm.bucket_size[0].arn : null
}

output "count_alarm_arn" {
  description = "Object count alarm ARN"
  value       = var.create_count_alarm ? aws_cloudwatch_metric_alarm.object_count[0].arn : null
}

output "public_access_blocked" {
  description = "Whether public access is blocked"
  value       = var.block_public_access
}

output "bucket_cors_configured" {
  description = "Whether CORS is configured"
  value       = var.cors_rules != null ? true : false
}

output "lifecycle_rules_count" {
  description = "Number of lifecycle rules"
  value       = var.lifecycle_rules != null ? length(var.lifecycle_rules) : 0
}
