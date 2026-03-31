# SageMaker Model Deployment Module - IAM Roles and Policies

# Create IAM role for SageMaker to assume
resource "aws_iam_role" "sagemaker_role" {
  name = "${var.project_name}-${var.environment}-sagemaker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-${var.environment}-sagemaker-role"
      Environment = var.environment
      Project     = var.project_name
    }
  )
}

# Policy for S3 access to model artifacts and data capture
resource "aws_iam_role_policy" "sagemaker_s3_access" {
  name = "${var.project_name}-${var.environment}-sagemaker-s3-policy"
  role = aws_iam_role.sagemaker_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadModelArtifacts"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = [
          "${var.model_artifact_s3_uri}*",
          "arn:aws:s3:::${split("/", var.model_artifact_s3_uri)[2]}/*"
        ]
      },
      {
        Sid    = "ListModelBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning"
        ]
        Resource = "arn:aws:s3:::${split("/", var.model_artifact_s3_uri)[2]}"
      },
      # Data capture access (if enabled)
      {
        Sid    = "WriteDataCapture"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = var.enable_data_capture ? [
          "arn:aws:s3:::${split("/", var.data_capture_s3_prefix)[2]}/*"
        ] : []
        Condition = var.enable_data_capture ? {
          StringEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        } : {}
      },
      {
        Sid    = "ListDataCaptureBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning"
        ]
        Resource = var.enable_data_capture ? [
          "arn:aws:s3:::${split("/", var.data_capture_s3_prefix)[2]}"
        ] : []
      }
    ]
  })
}

# Policy for CloudWatch logs
resource "aws_iam_role_policy" "sagemaker_cloudwatch_logs" {
  name = "${var.project_name}-${var.environment}-sagemaker-logs-policy"
  role = aws_iam_role.sagemaker_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/sagemaker/*"
      }
    ]
  })
}

# Policy for ECR access (if using custom container image)
resource "aws_iam_role_policy" "sagemaker_ecr_access" {
  count = can(regex("dkr.ecr", var.model_container_image_uri)) ? 1 : 0
  name  = "${var.project_name}-${var.environment}-sagemaker-ecr-policy"
  role  = aws_iam_role.sagemaker_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRGetAuthorizationToken"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRGetDownloadArtifacts"
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "arn:aws:ecr:${var.aws_region}:*:repository/*"
      }
    ]
  })
}

# Policy for X-Ray tracing (if enabled)
resource "aws_iam_role_policy" "sagemaker_xray_access" {
  count = var.enable_xray_tracing ? 1 : 0
  name  = "${var.project_name}-${var.environment}-sagemaker-xray-policy"
  role  = aws_iam_role.sagemaker_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "XRayAccess"
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy for CloudWatch metrics (if monitoring enabled)
resource "aws_iam_role_policy" "sagemaker_cloudwatch_metrics" {
  count = var.enable_monitoring ? 1 : 0
  name  = "${var.project_name}-${var.environment}-sagemaker-metrics-policy"
  role  = aws_iam_role.sagemaker_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy for VPC access (if VPC config provided)
resource "aws_iam_role_policy" "sagemaker_vpc_access" {
  count = var.vpc_config != null ? 1 : 0
  name  = "${var.project_name}-${var.environment}-sagemaker-vpc-policy"
  role  = aws_iam_role.sagemaker_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "VPCAccess"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach SageMaker managed policy for basic execution
resource "aws_iam_role_policy_attachment" "sagemaker_execution_role" {
  role       = aws_iam_role.sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

# Output the role ARN for use in model creation
output "sagemaker_role_arn" {
  description = "ARN of the SageMaker IAM role"
  value       = aws_iam_role.sagemaker_role.arn
}
