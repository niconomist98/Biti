################################################################################
# Glue Module - Outputs
################################################################################

output "job_name" {
  description = "Name of the Glue job"
  value       = aws_glue_job.job.name
}

output "job_arn" {
  description = "ARN of the Glue job"
  value       = aws_glue_job.job.arn
}

output "role_arn" {
  description = "ARN of the Glue execution role"
  value       = aws_iam_role.glue_role.arn
}

output "role_name" {
  description = "Name of the Glue execution role"
  value       = aws_iam_role.glue_role.name
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.glue_logs.name
}

output "log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.glue_logs.arn
}

output "schedule_trigger_name" {
  description = "Name of the schedule trigger"
  value       = var.schedule_expression != null ? aws_glue_trigger.schedule[0].name : null
}

output "failure_alarm_arn" {
  description = "ARN of the failure CloudWatch alarm"
  value       = var.create_failure_alarm ? aws_cloudwatch_metric_alarm.glue_failures[0].arn : null
}

output "duration_alarm_arn" {
  description = "ARN of the duration CloudWatch alarm"
  value       = var.create_duration_alarm ? aws_cloudwatch_metric_alarm.glue_duration[0].arn : null
}
