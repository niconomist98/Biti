variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "lambda_inference_arn" {
  description = "ARN of the inference Lambda function"
  type        = string
  default     = "arn:aws:lambda:us-east-1:910661001517:function:biti-btc-5mins-inference"
}

module "inference_step_function" {
  source = "../../modules/step_functions"

  state_machine_name  = "biti-inference-orchestrator-${var.environment}"
  lambda_function_arn = var.lambda_inference_arn
  max_retry_attempts  = 3
  schedule_expression = "rate(5 minutes)"

  tags = {
    Project     = "Biti"
    Environment = var.environment
  }
}

output "state_machine_arn" {
  value = module.inference_step_function.state_machine_arn
}

output "state_machine_name" {
  value = module.inference_step_function.state_machine_name
}
