################################################################################
# Step Functions Module - Outputs
################################################################################

output "state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.inference_orchestrator.arn
}

output "state_machine_name" {
  description = "Name of the Step Functions state machine"
  value       = aws_sfn_state_machine.inference_orchestrator.name
}

output "role_arn" {
  description = "ARN of the Step Functions execution role"
  value       = aws_iam_role.step_functions_role.arn
}

output "schedule_rule_arn" {
  description = "ARN of the EventBridge schedule rule"
  value       = var.schedule_expression != null ? aws_cloudwatch_event_rule.schedule[0].arn : null
}
