################################################################################
# AWS Step Functions Module
# Orchestrates Lambda inference function with retry logic and scheduling.
################################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# --- IAM Role for Step Functions ---

resource "aws_iam_role" "step_functions_role" {
  name = "${var.state_machine_name}-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "states.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "invoke_lambda" {
  name = "${var.state_machine_name}-invoke-lambda"
  role = aws_iam_role.step_functions_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "lambda:InvokeFunction"
      Resource = var.lambda_function_arn
    }]
  })
}

# --- State Machine ---

resource "aws_sfn_state_machine" "inference_orchestrator" {
  name     = var.state_machine_name
  role_arn = aws_iam_role.step_functions_role.arn

  definition = jsonencode({
    Comment = "Orchestrates the Biti crypto inference Lambda"
    StartAt = "InvokeLambdaInference"
    States = {
      InvokeLambdaInference = {
        Type     = "Task"
        Resource = "arn:aws:states:::lambda:invoke"
        Parameters = {
          FunctionName = var.lambda_function_arn
          Payload      = { "source" = "step-functions" }
        }
        OutputPath = "$.Payload"
        Retry = [{
          ErrorEquals     = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException", "States.TaskFailed"]
          IntervalSeconds = 5
          MaxAttempts     = var.max_retry_attempts
          BackoffRate     = 2.0
        }]
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "InferenceFailed"
          ResultPath  = "$.error"
        }]
        Next = "InferenceSucceeded"
      }
      InferenceSucceeded = {
        Type = "Succeed"
      }
      InferenceFailed = {
        Type  = "Fail"
        Error = "InferenceError"
        Cause = "Lambda inference invocation failed after retries"
      }
    }
  })

  tags = var.tags
}

# --- EventBridge Schedule ---

resource "aws_cloudwatch_event_rule" "schedule" {
  count               = var.schedule_expression != null ? 1 : 0
  name                = "${var.state_machine_name}-schedule"
  description         = "Triggers ${var.state_machine_name} on schedule"
  schedule_expression = var.schedule_expression

  tags = var.tags
}

resource "aws_iam_role" "eventbridge_sfn_role" {
  count = var.schedule_expression != null ? 1 : 0
  name  = "${var.state_machine_name}-eb-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "events.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "eventbridge_start_execution" {
  count = var.schedule_expression != null ? 1 : 0
  name  = "${var.state_machine_name}-eb-start-exec"
  role  = aws_iam_role.eventbridge_sfn_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "states:StartExecution"
      Resource = aws_sfn_state_machine.inference_orchestrator.arn
    }]
  })
}

resource "aws_cloudwatch_event_target" "step_functions" {
  count    = var.schedule_expression != null ? 1 : 0
  rule     = aws_cloudwatch_event_rule.schedule[0].name
  arn      = aws_sfn_state_machine.inference_orchestrator.arn
  role_arn = aws_iam_role.eventbridge_sfn_role[0].arn
}
