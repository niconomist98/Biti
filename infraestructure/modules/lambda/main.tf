################################################################################
# AWS Lambda Function Module
# Deploys serverless Lambda functions with comprehensive configuration,
# monitoring, logging, and security controls.
################################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Create IAM role for Lambda execution
resource "aws_iam_role" "lambda_role" {
  name              = "${var.function_name}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Create ZIP archive from source code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/${var.function_name}.zip"
}

# Create Lambda function
resource "aws_lambda_function" "function" {
  filename            = data.archive_file.lambda_zip.output_path
  function_name       = var.function_name
  role                = aws_iam_role.lambda_role.arn
  handler             = var.handler
  runtime             = var.runtime
  timeout             = var.timeout
  memory_size         = var.memory_size
  publish             = var.publish
  architectures       = var.architectures
  source_code_hash    = data.archive_file.lambda_zip.output_base64sha256

  # Environment variables
  environment {
    variables = var.environment_variables
  }

  # VPC configuration
  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids            = vpc_config.value.subnet_ids
      security_group_ids    = vpc_config.value.security_group_ids
    }
  }

  # Ephemeral storage configuration (Lambda ephemeral /tmp storage)
  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage_size != null ? [var.ephemeral_storage_size] : []
    content {
      size = ephemeral_storage.value
    }
  }

  # CloudWatch Logs configuration
  logging_config {
    log_format = var.log_format
    log_group  = aws_cloudwatch_log_group.lambda_logs.name
  }

  # Layers for shared code/dependencies
  layers = var.layers

  # Reserved concurrent executions
  reserved_concurrent_executions = var.reserved_concurrent_executions

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution
  ]
}

# Lambda alias for blue-green deployments
resource "aws_lambda_alias" "live" {
  count             = var.enable_alias ? 1 : 0
  name              = var.alias_name
  description       = "Live alias for ${var.function_name}"
  function_name = aws_lambda_function.function.function_name
  function_version  = aws_lambda_function.function.version

}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# CloudWatch Alarm for function errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count               = var.create_error_alarm ? 1 : 0
  alarm_name          = "${var.function_name}-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = var.error_threshold
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.function.function_name
  }

  tags = var.tags
}

# CloudWatch Alarm for function throttles
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  count               = var.create_throttle_alarm ? 1 : 0
  alarm_name          = "${var.function_name}-throttles"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = var.throttle_threshold
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.function.function_name
  }

  tags = var.tags
}

# CloudWatch Alarm for high duration
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  count               = var.create_duration_alarm ? 1 : 0
  alarm_name          = "${var.function_name}-high-duration"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = var.duration_threshold
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.function.function_name
  }

  tags = var.tags
}

# EventBridge rule for scheduled invocations (if scheduled)
resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  count               = var.schedule_expression != null ? 1 : 0
  name                = "${var.function_name}-schedule"
  description         = "Scheduled invocation for ${var.function_name}"
  schedule_expression = var.schedule_expression

  tags = var.tags
}

# EventBridge target for Lambda
resource "aws_cloudwatch_event_target" "lambda_schedule_target" {
  count       = var.schedule_expression != null ? 1 : 0
  rule        = aws_cloudwatch_event_rule.lambda_schedule[0].name
  target_id   = "${var.function_name}-target"
  arn         = aws_lambda_function.function.arn
  role_arn    = aws_iam_role.eventbridge_invoke.arn

  input = var.schedule_input != null ? var.schedule_input : jsonencode({})
}

# Grant EventBridge permission to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  count         = var.schedule_expression != null ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_schedule[0].arn
}

# IAM role for EventBridge to invoke Lambda
resource "aws_iam_role" "eventbridge_invoke" {
  name = "${var.function_name}-eventbridge-invoke"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Grant EventBridge role permission to invoke Lambda
resource "aws_iam_role_policy" "eventbridge_invoke_policy" {
  name   = "${var.function_name}-eventbridge-invoke-policy"
  role   = aws_iam_role.eventbridge_invoke.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Resource = aws_lambda_function.function.arn
      }
    ]
  })
}

# Attach basic execution policy for CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach VPC execution policy if VPC is configured
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  count      = var.vpc_config != null ? 1 : 0
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Attach custom inline policies from list
resource "aws_iam_role_policy" "lambda_custom_policies" {
  for_each = var.custom_policies != null ? var.custom_policies : {}

  name   = "${var.function_name}-${each.key}"
  role   = aws_iam_role.lambda_role.id
  policy = each.value
}

# Lambda function URL (optional - for public HTTP endpoints)
resource "aws_lambda_function_url" "function_url" {
  count              = var.enable_function_url ? 1 : 0
  function_name      = aws_lambda_function.function.function_name
  authorization_type = var.function_url_auth_type
  cors {
    allow_credentials = var.cors_allow_credentials
    allow_headers     = var.cors_allow_headers
    allow_methods     = var.cors_allow_methods
    allow_origins     = var.cors_allow_origins
    expose_headers    = var.cors_expose_headers
    max_age           = var.cors_max_age
  }

  qualifier = var.enable_alias ? aws_lambda_alias.live[0].name : null
}

# CloudWatch Composite Alarm
resource "aws_cloudwatch_composite_alarm" "lambda_health" {
  count           = var.create_composite_alarm ? 1 : 0
  alarm_name      = "${var.function_name}-health"
  alarm_description = "Composite health check for ${var.function_name}"
  actions_enabled = true
  alarm_actions   = var.alarm_actions

  alarm_rule = join(" OR ", concat(
    var.create_error_alarm ? [aws_cloudwatch_metric_alarm.lambda_errors[0].arn] : [],
    var.create_throttle_alarm ? [aws_cloudwatch_metric_alarm.lambda_throttles[0].arn] : [],
    var.create_duration_alarm ? [aws_cloudwatch_metric_alarm.lambda_duration[0].arn] : []
  ))

  tags = var.tags
}

# X-Ray write access for tracing (optional)
resource "aws_iam_role_policy_attachment" "lambda_xray_write_access" {
  count      = var.enable_xray_tracing ? 1 : 0
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# Enable Lambda insights (requires lambda-insights-layer.zip in module directory)
# resource "aws_lambda_layer_version" "insights" {
#   count               = var.enable_insights ? 1 : 0
#   filename            = "${path.module}/lambda-insights-layer.zip"
#   layer_name          = "${var.function_name}-insights"
#   compatible_runtimes = [var.runtime]
#   source_code_hash    = filebase64sha256("${path.module}/lambda-insights-layer.zip")
#   skip_destroy        = true
# }
