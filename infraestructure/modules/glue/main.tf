################################################################################
# AWS Glue Job Module
# Deploys Glue ETL/Python Shell jobs with IAM roles, CloudWatch logging,
# monitoring alarms, and scheduling via EventBridge.
################################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# IAM role for Glue job execution
resource "aws_iam_role" "glue_role" {
  name = "${var.job_name}-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach AWS managed Glue service role policy
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# S3 access policy for script and data locations
resource "aws_iam_role_policy" "glue_s3_access" {
  name = "${var.job_name}-s3-access"
  role = aws_iam_role.glue_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = var.s3_access_arns
      }
    ]
  })
}

# Attach custom inline policies
resource "aws_iam_role_policy" "glue_custom_policies" {
  for_each = var.custom_policies != null ? var.custom_policies : {}

  name   = "${var.job_name}-${each.key}"
  role   = aws_iam_role.glue_role.id
  policy = each.value
}

# Glue Job
resource "aws_glue_job" "job" {
  name     = var.job_name
  role_arn = aws_iam_role.glue_role.arn

  command {
    name            = var.job_type == "pythonshell" ? "pythonshell" : "glueetl"
    script_location = var.script_location
    python_version  = var.python_version
  }

  glue_version      = var.glue_version
  max_retries       = var.max_retries
  timeout           = var.timeout
  worker_type       = var.job_type != "pythonshell" ? var.worker_type : null
  number_of_workers = var.job_type != "pythonshell" ? var.number_of_workers : null
  max_capacity      = var.job_type == "pythonshell" ? var.max_capacity : null

  default_arguments = merge(
    {
      "--job-language"                     = "python"
      "--continuous-log-logGroup"          = aws_cloudwatch_log_group.glue_logs.name
      "--enable-continuous-cloudwatch-log" = "true"
      "--enable-metrics"                   = "true"
    },
    var.default_arguments
  )

  dynamic "execution_property" {
    for_each = var.max_concurrent_runs != null ? [var.max_concurrent_runs] : []
    content {
      max_concurrent_runs = execution_property.value
    }
  }

  connections = length(var.connections) > 0 ? var.connections : null

  tags = var.tags
}

# CloudWatch Log Group for Glue
resource "aws_cloudwatch_log_group" "glue_logs" {
  name              = "/aws-glue/jobs/${var.job_name}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Glue Trigger (scheduled)
resource "aws_glue_trigger" "schedule" {
  count    = var.schedule_expression != null ? 1 : 0
  name     = "${var.job_name}-schedule"
  type     = "SCHEDULED"
  schedule = var.schedule_expression
  enabled  = var.schedule_enabled

  actions {
    job_name  = aws_glue_job.job.name
    arguments = var.schedule_arguments
  }

  tags = var.tags
}

# CloudWatch Alarm for job failures
resource "aws_cloudwatch_metric_alarm" "glue_failures" {
  count               = var.create_failure_alarm ? 1 : 0
  alarm_name          = "${var.job_name}-failures"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "glue.driver.aggregate.numFailedTasks"
  namespace           = "Glue"
  period              = 300
  statistic           = "Sum"
  threshold           = var.failure_threshold
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    JobName = aws_glue_job.job.name
    JobRunId = "ALL"
    Type     = "count"
  }

  tags = var.tags
}

# CloudWatch Alarm for job duration
resource "aws_cloudwatch_metric_alarm" "glue_duration" {
  count               = var.create_duration_alarm ? 1 : 0
  alarm_name          = "${var.job_name}-high-duration"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "glue.driver.aggregate.elapsedTime"
  namespace           = "Glue"
  period              = 300
  statistic           = "Maximum"
  threshold           = var.duration_threshold
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    JobName = aws_glue_job.job.name
    JobRunId = "ALL"
    Type     = "gauge"
  }

  tags = var.tags
}
