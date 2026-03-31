# SageMaker Model Deployment Module - Outputs

output "model_name" {
  description = "Name of the created SageMaker model"
  value       = aws_sagemaker_model.model.name
}

output "model_arn" {
  description = "ARN of the created SageMaker model"
  value       = aws_sagemaker_model.model.arn
}

output "endpoint_name" {
  description = "Name of the created SageMaker endpoint"
  value       = aws_sagemaker_endpoint.endpoint.name
}

output "endpoint_arn" {
  description = "ARN of the created SageMaker endpoint"
  value       = aws_sagemaker_endpoint.endpoint.arn
}

output "endpoint_url" {
  description = "URL of the SageMaker endpoint for making predictions"
  value       = "https://runtime.sagemaker.${var.aws_region}.amazonaws.com"
}

output "endpoint_config_name" {
  description = "Name of the endpoint configuration"
  value       = aws_sagemaker_endpoint_configuration.config.name
}

output "endpoint_status" {
  description = "Status of the SageMaker endpoint"
  value       = aws_sagemaker_endpoint.endpoint.endpoint_status
}

output "model_package_group_arn" {
  description = "ARN of the model package group"
  value       = aws_sagemaker_model_package_group.package_group.arn
}

output "sagemaker_role_arn" {
  description = "ARN of the IAM role used by SageMaker"
  value       = aws_iam_role.sagemaker_role.arn
}

output "sagemaker_role_name" {
  description = "Name of the IAM role used by SageMaker"
  value       = aws_iam_role.sagemaker_role.name
}

output "cloudwatch_alarms" {
  description = "CloudWatch alarm names created for monitoring"
  value = var.enable_monitoring ? {
    cpu_alarm               = aws_cloudwatch_metric_alarm.endpoint_cpu[0].alarm_name
    gpu_memory_alarm        = aws_cloudwatch_metric_alarm.endpoint_gpu_memory[0].alarm_name
    invocation_errors_alarm = aws_cloudwatch_metric_alarm.endpoint_model_invocation_errors[0].alarm_name
  } : {}
}

output "autoscaling_target_arn" {
  description = "ARN of the autoscaling target (if enabled)"
  value = var.autoscaling_config != null ? try(
    aws_appautoscaling_target.sagemaker_target[0].arn,
    null
  ) : null
}

output "deployment_info" {
  description = "Complete deployment information"
  value = {
    project_name    = var.project_name
    environment     = var.environment
    model_name      = aws_sagemaker_model.model.name
    endpoint_name   = aws_sagemaker_endpoint.endpoint.name
    instance_type   = var.instance_type
    instance_count  = var.initial_instance_count
    vpc_enabled     = var.vpc_config != null
    monitoring      = var.enable_monitoring
    autoscaling     = var.autoscaling_config != null
    data_capture    = var.enable_data_capture
  }
}

output "prediction_command" {
  description = "Example AWS CLI command to invoke the endpoint"
  value = "aws sagemaker-runtime invoke-endpoint --endpoint-name ${aws_sagemaker_endpoint.endpoint.name} --region ${var.aws_region} --content-type application/json --body '{\"input\": \"your-data\"}' response.json && cat response.json"
}
