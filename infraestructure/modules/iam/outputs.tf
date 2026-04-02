# IAM Module Outputs

output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.main.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.main.name
}

output "role_id" {
  description = "ID (stable and unique identifier) of the IAM role"
  value       = aws_iam_role.main.id
}

output "assume_role_policy" {
  description = "Assume role policy document"
  value       = aws_iam_role.main.assume_role_policy
  sensitive   = true
}

output "instance_profile_arn" {
  description = "ARN of the instance profile (if created)"
  value       = var.create_instance_profile ? aws_iam_instance_profile.main[0].arn : null
}

output "instance_profile_name" {
  description = "Name of the instance profile (if created)"
  value       = var.create_instance_profile ? aws_iam_instance_profile.main[0].name : null
}

output "custom_policy_arn" {
  description = "ARN of the custom managed policy (if created)"
  value       = var.create_custom_policy ? aws_iam_policy.custom[0].arn : null
}

output "custom_policy_name" {
  description = "Name of the custom managed policy (if created)"
  value       = var.create_custom_policy ? aws_iam_policy.custom[0].name : null
}

output "inline_policies" {
  description = "Map of inline policy names"
  value       = { for k, v in aws_iam_role_policy.inline : k => v.name }
}

output "managed_policies" {
  description = "List of managed policy ARNs attached to the role"
  value       = var.managed_policy_arns
}

output "bounded_role_arn" {
  description = "ARN of the role with permission boundary (if created)"
  value       = var.permission_boundary_arn != "" ? aws_iam_role.main_with_boundary[0].arn : null
}

output "cloudwatch_log_group_name" {
  description = "Name of CloudWatch log group for IAM access logs"
  value       = var.enable_iam_access_logging ? aws_cloudwatch_log_group.iam_access[0].name : null
}

output "cloudtrail_name" {
  description = "Name of CloudTrail trail (if created)"
  value       = var.enable_cloudtrail ? aws_cloudtrail.iam_activity[0].name : null
}

output "cloudtrail_s3_bucket" {
  description = "S3 bucket name for CloudTrail logs"
  value       = var.enable_cloudtrail ? aws_s3_bucket.cloudtrail[0].id : null
}

output "role_session_duration" {
  description = "Maximum session duration for the role in seconds"
  value       = aws_iam_role.main.max_session_duration
}

output "trust_entity_type" {
  description = "Type of entity that can assume the role"
  value       = var.trust_entity_type
}

output "trust_entity_identifiers" {
  description = "Identifiers for the trust relationship"
  value       = var.trust_entity_identifiers
}
