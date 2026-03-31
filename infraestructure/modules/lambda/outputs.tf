################################################################################
# Lambda Module - Outputs
################################################################################

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.function.arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.function.function_name
}

output "function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.function.invoke_arn
}

output "function_version" {
  description = "Latest version of the Lambda function"
  value       = aws_lambda_function.function.version
}

output "function_last_modified" {
  description = "Last modified timestamp of the function"
  value       = aws_lambda_function.function.last_modified
}

output "function_code_size" {
  description = "Size of the Lambda function code in bytes"
  value       = aws_lambda_function.function.code_size
}

output "role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_role.arn
}

output "role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda_role.name
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.lambda_logs.arn
}

output "alias_name" {
  description = "Lambda alias name"
  value       = var.enable_alias ? aws_lambda_alias.live[0].name : null
}

output "alias_arn" {
  description = "Lambda alias ARN"
  value       = var.enable_alias ? aws_lambda_alias.live[0].arn : null
}

output "function_url" {
  description = "Lambda function URL"
  value       = var.enable_function_url ? aws_lambda_function_url.function_url[0].function_url : null
}

output "error_alarm_arn" {
  description = "ARN of the error CloudWatch alarm"
  value       = var.create_error_alarm ? aws_cloudwatch_metric_alarm.lambda_errors[0].arn : null
}

output "throttle_alarm_arn" {
  description = "ARN of the throttle CloudWatch alarm"
  value       = var.create_throttle_alarm ? aws_cloudwatch_metric_alarm.lambda_throttles[0].arn : null
}

output "duration_alarm_arn" {
  description = "ARN of the duration CloudWatch alarm"
  value       = var.create_duration_alarm ? aws_cloudwatch_metric_alarm.lambda_duration[0].arn : null
}

output "composite_alarm_arn" {
  description = "ARN of the composite health alarm"
  value       = var.create_composite_alarm ? aws_cloudwatch_composite_alarm.lambda_health[0].arn : null
}

output "schedule_rule_arn" {
  description = "ARN of the EventBridge schedule rule"
  value       = var.schedule_expression != null ? aws_cloudwatch_event_rule.lambda_schedule[0].arn : null
}
