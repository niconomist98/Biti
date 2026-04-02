################################################################################
# Lambda Module - Basic Example
# Simple Python Lambda function deployment
################################################################################

module "hello_world" {
  source = "../modules/lambda"

  function_name = "hello-world"
  source_dir    = "${path.module}/lambda_code"
  runtime       = "python3.11"
  handler       = "index.handler"
  timeout       = 30
  memory_size   = 128

  environment_variables = {
    LOG_LEVEL = "INFO"
  }

  create_error_alarm  = true
  error_threshold     = 5
  create_throttle_alarm = true
  alarm_actions       = []  # Add SNS topic ARN for notifications

  tags = {
    Environment = "development"
    Service     = "demo"
  }
}

# Outputs
output "lambda_function_arn" {
  value = module.hello_world.function_arn
}

output "lambda_function_url" {
  value = module.hello_world.function_name
}
