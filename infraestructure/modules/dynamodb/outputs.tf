# DynamoDB Module Outputs

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.main.arn
}

output "table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.main.name
}

output "table_id" {
  description = "ID of the DynamoDB table"
  value       = aws_dynamodb_table.main.id
}

output "table_stream_arn" {
  description = "ARN of the DynamoDB Streams endpoint"
  value       = var.enable_streams ? aws_dynamodb_table.main.stream_arn : null
}

output "table_stream_label" {
  description = "DynamoDB Streams label for streams"
  value       = var.enable_streams ? aws_dynamodb_table.main.stream_label : null
}

output "billing_mode" {
  description = "Billing mode of the table"
  value       = aws_dynamodb_table.main.billing_mode
}

output "read_capacity" {
  description = "Read capacity units (if provisioned)"
  value       = aws_dynamodb_table.main.read_capacity
}

output "write_capacity" {
  description = "Write capacity units (if provisioned)"
  value       = aws_dynamodb_table.main.write_capacity
}

output "hash_key" {
  description = "Hash key (partition key) of the table"
  value       = aws_dynamodb_table.main.hash_key
}

output "range_key" {
  description = "Range key (sort key) of the table"
  value       = aws_dynamodb_table.main.range_key
}

output "global_secondary_indexes" {
  description = "Information about global secondary indexes"
  value       = aws_dynamodb_table.main.global_secondary_index
}

output "local_secondary_indexes" {
  description = "Information about local secondary indexes"
  value       = aws_dynamodb_table.main.local_secondary_index
}



output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for DynamoDB Streams"
  value       = var.enable_streams ? aws_cloudwatch_log_group.dynamodb_streams[0].name : null
}

output "backup_vault_arn" {
  description = "ARN of the backup vault (if enabled)"
  value       = var.enable_backup_vault ? aws_backup_vault.dynamodb[0].arn : null
}

output "backup_plan_id" {
  description = "ID of the backup plan (if enabled)"
  value       = var.enable_backup_vault ? aws_backup_plan.dynamodb[0].id : null
}

output "global_table_arn" {
  description = "ARN of the global table (if enabled)"
  value       = var.enable_global_table ? aws_dynamodb_global_table.main[0].arn : null
}

output "autoscaling_enabled" {
  description = "Whether auto-scaling is enabled"
  value       = var.enable_autoscaling && var.billing_mode == "PROVISIONED"
}

output "encryption_enabled" {
  description = "Whether server-side encryption is enabled"
  value       = length(aws_dynamodb_table.main.server_side_encryption) > 0 ? aws_dynamodb_table.main.server_side_encryption[0].enabled : false
}

output "point_in_time_recovery_enabled" {
  description = "Whether point-in-time recovery is enabled"
  value       = length(aws_dynamodb_table.main.point_in_time_recovery) > 0 ? aws_dynamodb_table.main.point_in_time_recovery[0].enabled : false
}

output "ttl_attribute_name" {
  description = "TTL attribute name (if configured)"
  value       = var.ttl_attribute_name
}


