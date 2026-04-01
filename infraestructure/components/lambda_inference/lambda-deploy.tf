variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

# Lambda Function Deployment

module "my_lambda" {
  source = "../../modules/lambda"

  function_name = "biti-hello-world"
  source_dir    ="${path.module}/../../../src/lambda_inference"
  runtime       = "python3.11"
  handler       = "index.handler"
  timeout       = 30
  memory_size   = 128

  environment_variables = {
    LOG_LEVEL   = "INFO"
    S3_BUCKET   = "biti-data-dev"
  }

  custom_policies = {
    s3_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
          Resource = [
            "arn:aws:s3:::biti-data-dev",
            "arn:aws:s3:::biti-data-dev/*"
          ]
        }
      ]
    })
  }

  create_error_alarm     = false
  create_throttle_alarm  = false
  create_duration_alarm  = false
  create_composite_alarm = false

  tags = {
    Project     = "Biti"
    Environment = var.environment
  }
}

output "lambda_function_arn" {
  value = module.my_lambda.function_arn
}

output "lambda_function_name" {
  value = module.my_lambda.function_name
}