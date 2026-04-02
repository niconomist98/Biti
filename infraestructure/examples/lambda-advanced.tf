################################################################################
# Lambda Module - Advanced Example
# Production Lambda with VPC, custom policies, and monitoring
################################################################################

# Example VPC references (replace with your actual VPC)
variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = "vpc-xxxxxxxx"
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
  default     = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"]
}

# Create Lambda with database access
module "api_handler" {
  source = "../modules/lambda"

  function_name = "api-request-handler"
  source_dir    = "${path.module}/lambda_code/api"
  runtime       = "python3.11"
  handler       = "app.lambda_handler"
  timeout       = 60
  memory_size   = 512

  # VPC for database access
  vpc_config = {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  # Environment for database connection
  environment_variables = {
    DB_HOST       = aws_db_instance.main.endpoint
    DB_NAME       = "myapp"
    LOG_LEVEL     = "INFO"
    ENVIRONMENT   = "production"
  }

  # Custom policies for AWS services
  custom_policies = {
    secrets_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "secretsmanager:GetSecretValue"
          ]
          Effect   = "Allow"
          Resource = aws_secretsmanager_secret.db_password.arn
        }
      ]
    })
    
    s3_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:GetObject",
            "s3:PutObject"
          ]
          Effect   = "Allow"
          Resource = "arn:aws:s3:::my-bucket/*"
        }
      ]
    })

    dynamodb_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "dynamodb:PutItem",
            "dynamodb:GetItem",
            "dynamodb:UpdateItem"
          ]
          Effect   = "Allow"
          Resource = aws_dynamodb_table.sessions.arn
        }
      ]
    })

    cloudwatch_logs = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Effect   = "Allow"
          Resource = "arn:aws:logs:*:*:*"
        }
      ]
    })
  }

  # Scheduling for periodic tasks
  schedule_expression = "cron(0 * * * ? *)"  # Every hour
  schedule_input = jsonencode({
    action = "hourly_cleanup"
  })

  # Monitoring
  create_error_alarm     = true
  error_threshold        = 3
  create_throttle_alarm  = true
  throttle_threshold     = 1
  create_duration_alarm  = true
  duration_threshold     = 50000  # 50 seconds
  create_composite_alarm = true

  enable_xray_tracing = true

  tags = {
    Environment = "production"
    Service     = "api"
    Team        = "platform"
  }
}

# Security group for Lambda
resource "aws_security_group" "lambda" {
  name        = "api-lambda-sg"
  description = "Security group for Lambda API"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = []  # No inbound (Lambda calls outbound)
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "api-lambda-sg"
  }
}

# Example database reference
resource "aws_db_instance" "main" {
  # Database configuration
}

# Example RDS secret
resource "aws_secretsmanager_secret" "db_password" {
  name = "db-password"
}

# Example DynamoDB table
resource "aws_dynamodb_table" "sessions" {
  name = "sessions"
}

# Outputs
output "lambda_api_arn" {
  value = module.api_handler.function_arn
}

output "lambda_api_name" {
  value = module.api_handler.function_name
}

output "lambda_log_group" {
  value = module.api_handler.log_group_name
}
