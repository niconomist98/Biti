# SageMaker Model Deployment Module - Main Resources

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Create SageMaker Model
resource "aws_sagemaker_model" "model" {
  name               = "${var.project_name}-${var.environment}-${var.model_name}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  execution_role_arn = aws_iam_role.sagemaker_role.arn

  primary_container {
    image              = var.model_container_image_uri
    model_data_url     = var.custom_model_data_url != null ? var.custom_model_data_url : var.model_artifact_s3_uri
    model_data_version = "1"

    environment = var.model_environment_variables

    content_type = "application/octet-stream"
    accept_types = ["application/json", "text/csv", "application/x-recordio-protobuf"]
  }

  vpc_config {
    subnets            = var.vpc_config != null ? var.vpc_config.subnet_ids : []
    security_group_ids = var.vpc_config != null ? var.vpc_config.security_group_ids : []
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.model_name}"
      Environment = var.environment
      Project     = var.project_name
      Framework   = var.framework
      Version     = var.framework_version
    }
  )

  depends_on = [aws_iam_role_policy.sagemaker_s3_access]
}

# Create Model Package Group (optional but recommended for model versioning)
resource "aws_sagemaker_model_package_group" "package_group" {
  model_package_group_name = "${var.project_name}-${var.environment}-model-package-group"

  model_package_group_description = "Model package group for ${var.project_name} ${var.environment} environment"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-model-package-group"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

# Create SageMaker Endpoint Configuration
resource "aws_sagemaker_endpoint_configuration" "config" {
  name = "${var.project_name}-${var.environment}-${var.endpoint_name}-config-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  production_variants {
    variant_name           = "default"
    model_name             = aws_sagemaker_model.model.name
    initial_instance_count = var.initial_instance_count
    instance_type          = var.instance_type
    initial_variant_weight = 1.0

    core_dump_config {
      destination_s3_uri = "s3://${split("/", var.model_artifact_s3_uri)[2]}/core-dumps/"
      kms_key_id         = null
    }

    container_startup_health_check_timeout_in_seconds = 600
  }

  # Data capture configuration
  dynamic "data_capture_config" {
    for_each = var.enable_data_capture ? [1] : []
    content {
      enabled                = true
      initial_sampling_percentage = 100
      destination_s3_uri     = var.data_capture_s3_prefix
      capture_options = [
        {
          capture_mode = "InputAndOutput"
        }
      ]
    }
  }

  # Enable X-Ray tracing
  dynamic "shadow_production_variants" {
    for_each = var.enable_xray_tracing ? [1] : []
    content {
      variant_name           = "debug"
      model_name             = aws_sagemaker_model.model.name
      initial_instance_count = 0
      instance_type          = var.instance_type
    }
  }

  kms_key_arn = null

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.endpoint_name}-config"
      Environment = var.environment
      Project     = var.project_name
    }
  )

  depends_on = [aws_sagemaker_model.model]
}

# Create SageMaker Endpoint
resource "aws_sagemaker_endpoint" "endpoint" {
  name                 = "${var.project_name}-${var.environment}-${var.endpoint_name}"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.config.name

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.endpoint_name}"
      Environment = var.environment
      Project     = var.project_name
    }
  )

  depends_on = [aws_sagemaker_endpoint_configuration.config]
}

# Auto Scaling for the endpoint (if configured)
resource "aws_appautoscaling_target" "sagemaker_target" {
  count              = var.autoscaling_config != null ? 1 : 0
  max_capacity       = var.autoscaling_config.max_capacity
  min_capacity       = var.autoscaling_config.min_capacity
  resource_id        = "endpoint/${aws_sagemaker_endpoint.endpoint.name}/variant/default"
  scalable_dimension = "sagemaker:variant:DesiredInstanceCount"
  service_namespace  = "sagemaker"

  depends_on = [aws_sagemaker_endpoint.endpoint]
}

# Auto Scaling Policy - Target Tracking
resource "aws_appautoscaling_policy" "sagemaker_policy" {
  count              = var.autoscaling_config != null ? 1 : 0
  name               = "${var.project_name}-${var.environment}-sagemaker-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = "endpoint/${aws_sagemaker_endpoint.endpoint.name}/variant/default"
  scalable_dimension = "sagemaker:variant:DesiredInstanceCount"
  service_namespace  = "sagemaker"

  target_tracking_scaling_policy_configuration {
    target_value = var.autoscaling_config.target_value

    predefined_metric_specification {
      predefined_metric_type = "SageMakerVariantInvocationsPerInstance"
    }

    scale_in_cooldown  = var.autoscaling_config.scale_in_cooldown_seconds
    scale_out_cooldown = var.autoscaling_config.scale_out_cooldown_seconds
  }

  depends_on = [aws_appautoscaling_target.sagemaker_target]
}

# CloudWatch Alarms for monitoring
resource "aws_cloudwatch_metric_alarm" "endpoint_cpu" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-${var.endpoint_name}-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/SageMaker"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alert when SageMaker endpoint CPU exceeds 80%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.endpoint.name
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.endpoint_name}-cpu-alarm"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "endpoint_gpu_memory" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-${var.endpoint_name}-gpu-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "GPUMemoryUtilization"
  namespace           = "AWS/SageMaker"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "Alert when SageMaker endpoint GPU memory exceeds 85%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.endpoint.name
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.endpoint_name}-gpu-memory-alarm"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "endpoint_model_invocation_errors" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-${var.endpoint_name}-invocation-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ModelInvocation4XXErrors"
  namespace           = "AWS/SageMaker"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alert when SageMaker endpoint has 4XX errors"
  treat_missing_data  = "notBreaching"

  dimensions = {
    EndpointName = aws_sagemaker_endpoint.endpoint.name
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-${var.endpoint_name}-errors-alarm"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}
