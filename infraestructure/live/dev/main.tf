################################################################################
# Biti Infrastructure - Unified Deployment
#
# Dependency graph:
#   L1: S3, DynamoDB                    (no deps)
#   L2: SageMaker                       (← S3)
#   L3: Lambda Inference                (← S3, DynamoDB, SageMaker endpoint name)
#   L4: Step Functions                  (← Lambda Inference)
#   L5: Webapp                          (← DynamoDB)
#   L6: EC2                             (standalone, optional)
#
# Usage:
#   make plan | make apply | make destroy
################################################################################

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  # Uncomment for shared remote state (recommended for CI/CD)
  # backend "s3" {
  #   bucket         = "biti-terraform-state"
  #   key            = "live/dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "Biti"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# ─── VARIABLES ─────────────────────────────────────────────────────────────────

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "deploy_sagemaker" {
  description = "Deploy SageMaker endpoint (ml.m5.large costs ~$0.115/hr)"
  type        = bool
  default     = true
}

variable "deploy_ec2" {
  description = "Deploy EC2 test instance"
  type        = bool
  default     = false
}

variable "deploy_webapp" {
  description = "Deploy webapp (CloudFront + API GW + Lambda)"
  type        = bool
  default     = true
}

locals {
  tags = { Project = "Biti", Environment = var.environment }

  # SageMaker endpoint name — used by both SageMaker module and Lambda Inference
  sagemaker_endpoint_name = "biti-${var.environment}-bitcoin-classifier"
}

# ──────────────────────────────────────────────────────────────────────────────
# LAYER 1: FOUNDATIONAL — S3 + DynamoDB (no dependencies)
# ──────────────────────────────────────────────────────────────────────────────

module "s3" {
  source = "../../modules/s3"

  bucket_name         = "biti-ml-pipeline-${var.environment}"
  enable_versioning   = true
  block_public_access = true
  enable_logging      = false

  tags = local.tags
}

module "dynamodb" {
  source = "../../modules/dynamodb"

  table_name   = "biti-predictions-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "symbol"
  range_key    = "timestamp"

  enable_point_in_time_recovery = true
  enable_encryption             = true
  enable_streams                = false
  enable_alarms                 = false
  enable_backup_vault           = false

  tags = local.tags
}

# ──────────────────────────────────────────────────────────────────────────────
# LAYER 2: SAGEMAKER — depends on S3 (model artifact in bucket)
# ──────────────────────────────────────────────────────────────────────────────

data "aws_sagemaker_prebuilt_ecr_image" "xgboost" {
  count           = var.deploy_sagemaker ? 1 : 0
  repository_name = "sagemaker-xgboost"
  image_tag       = "1.7-1"
}

module "sagemaker" {
  count  = var.deploy_sagemaker ? 1 : 0
  source = "../../modules/sagemaker_model_deployment"

  project_name = "biti"
  environment  = var.environment
  aws_region   = var.aws_region

  model_name    = "bitcoin-classifier"
  endpoint_name = "bitcoin-classifier"

  model_artifact_s3_uri     = "s3://biti-data-dev/models/bitcoin-classifier/output/sagemaker-xgboost-2026-04-01-21-14-08-241/output/model.tar.gz"
  model_container_image_uri = data.aws_sagemaker_prebuilt_ecr_image.xgboost[0].registry_path

  instance_type          = "ml.m5.large"
  initial_instance_count = 1

  framework         = "xgboost"
  framework_version = "1.7-1"

  enable_data_capture = false
  enable_monitoring   = true
  enable_xray_tracing = false

  tags = merge(local.tags, { Model = "bitcoin-classifier" })
}

# ──────────────────────────────────────────────────────────────────────────────
# LAYER 3: LAMBDA INFERENCE — depends on S3, DynamoDB, SageMaker endpoint name
# ──────────────────────────────────────────────────────────────────────────────

module "lambda_inference" {
  source = "../../modules/lambda"

  function_name = "biti-btc-5mins-inference"
  source_dir    = "${path.module}/../../../src/lambda_inference"
  runtime       = "python3.11"
  handler       = "index.handler"
  timeout       = 30
  memory_size   = 128

  environment_variables = {
    LOG_LEVEL      = "INFO"
    S3_BUCKET      = module.s3.bucket_id
    ENDPOINT_NAME  = local.sagemaker_endpoint_name
    DYNAMODB_TABLE = module.dynamodb.table_name
  }

  custom_policies = {
    s3_access = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
        Resource = [module.s3.bucket_arn, "${module.s3.bucket_arn}/*"]
      }]
    })
    sagemaker_invoke = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = "sagemaker:InvokeEndpoint"
        Resource = "arn:aws:sagemaker:${var.aws_region}:${data.aws_caller_identity.current.account_id}:endpoint/${local.sagemaker_endpoint_name}"
      }]
    })
    dynamodb_access = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:GetItem", "dynamodb:Query"]
        Resource = module.dynamodb.table_arn
      }]
    })
  }

  create_error_alarm     = false
  create_throttle_alarm  = false
  create_duration_alarm  = false
  create_composite_alarm = false

  tags = local.tags
}

# ──────────────────────────────────────────────────────────────────────────────
# LAYER 4: STEP FUNCTIONS — depends on Lambda Inference (function_arn)
# ──────────────────────────────────────────────────────────────────────────────

module "step_functions" {
  source = "../../modules/step_functions"

  state_machine_name  = "biti-inference-orchestrator-${var.environment}"
  lambda_function_arn = module.lambda_inference.function_arn
  max_retry_attempts  = 3
  schedule_expression = "rate(5 minutes)"

  tags = local.tags
}

# ──────────────────────────────────────────────────────────────────────────────
# LAYER 5: WEBAPP — depends on DynamoDB (table_name)
# ──────────────────────────────────────────────────────────────────────────────

# --- Webapp S3 bucket (frontend hosting) ---

resource "aws_s3_bucket" "webapp_frontend" {
  count         = var.deploy_webapp ? 1 : 0
  bucket        = "biti-webapp-${var.environment}"
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_public_access_block" "webapp_frontend" {
  count                   = var.deploy_webapp ? 1 : 0
  bucket                  = aws_s3_bucket.webapp_frontend[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_website_configuration" "webapp_frontend" {
  count  = var.deploy_webapp ? 1 : 0
  bucket = aws_s3_bucket.webapp_frontend[0].id
  index_document { suffix = "index.html" }
  error_document { key = "index.html" }
}

resource "aws_s3_object" "index_html" {
  count        = var.deploy_webapp ? 1 : 0
  bucket       = aws_s3_bucket.webapp_frontend[0].id
  key          = "index.html"
  source       = "${path.module}/../../../src/webapp/frontend/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/../../../src/webapp/frontend/index.html")
}

# --- Webapp Lambda (API backend) ---

data "aws_iam_policy_document" "webapp_lambda_assume" {
  count = var.deploy_webapp ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "webapp_lambda" {
  count              = var.deploy_webapp ? 1 : 0
  name               = "biti-webapp-api-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.webapp_lambda_assume[0].json
}

resource "aws_iam_role_policy" "webapp_lambda_dynamodb" {
  count = var.deploy_webapp ? 1 : 0
  name  = "dynamodb-read"
  role  = aws_iam_role.webapp_lambda[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:Query", "dynamodb:Scan", "dynamodb:GetItem"]
      Resource = module.dynamodb.table_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "webapp_lambda_logs" {
  count      = var.deploy_webapp ? 1 : 0
  role       = aws_iam_role.webapp_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "webapp_api" {
  count       = var.deploy_webapp ? 1 : 0
  type        = "zip"
  source_file = "${path.module}/../../../src/webapp/api/index.py"
  output_path = "${path.module}/webapp_api.zip"
}

resource "aws_lambda_function" "webapp_api" {
  count            = var.deploy_webapp ? 1 : 0
  function_name    = "biti-webapp-api-${var.environment}"
  role             = aws_iam_role.webapp_lambda[0].arn
  handler          = "index.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.webapp_api[0].output_path
  source_code_hash = data.archive_file.webapp_api[0].output_base64sha256
  timeout          = 10

  environment {
    variables = {
      DYNAMODB_TABLE = module.dynamodb.table_name
    }
  }

  tags = local.tags
}

# --- API Gateway ---

resource "aws_apigatewayv2_api" "webapp" {
  count         = var.deploy_webapp ? 1 : 0
  name          = "biti-webapp-api-${var.environment}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "OPTIONS"]
    allow_headers = ["Content-Type"]
  }
}

resource "aws_apigatewayv2_integration" "webapp_lambda" {
  count                  = var.deploy_webapp ? 1 : 0
  api_id                 = aws_apigatewayv2_api.webapp[0].id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.webapp_api[0].invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "predictions" {
  count     = var.deploy_webapp ? 1 : 0
  api_id    = aws_apigatewayv2_api.webapp[0].id
  route_key = "GET /api/predictions"
  target    = "integrations/${aws_apigatewayv2_integration.webapp_lambda[0].id}"
}

resource "aws_apigatewayv2_stage" "webapp" {
  count       = var.deploy_webapp ? 1 : 0
  api_id      = aws_apigatewayv2_api.webapp[0].id
  name        = var.environment
  auto_deploy = true
}

resource "aws_lambda_permission" "webapp_apigw" {
  count         = var.deploy_webapp ? 1 : 0
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.webapp_api[0].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.webapp[0].execution_arn}/*/*"
}

# --- CloudFront ---

resource "aws_cloudfront_origin_access_control" "webapp" {
  count                             = var.deploy_webapp ? 1 : 0
  name                              = "biti-oac-${var.environment}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "webapp" {
  count               = var.deploy_webapp ? 1 : 0
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_100"

  origin {
    domain_name              = aws_s3_bucket.webapp_frontend[0].bucket_regional_domain_name
    origin_id                = "s3-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.webapp[0].id
  }

  origin {
    domain_name = replace(aws_apigatewayv2_api.webapp[0].api_endpoint, "https://", "")
    origin_id   = "api-gateway"
    origin_path = "/${var.environment}"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "api-gateway"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    forwarded_values {
      query_string = true
      headers      = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]
      cookies { forward = "none" }
    }
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  default_cache_behavior {
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.tags
}

resource "aws_s3_bucket_policy" "webapp_frontend" {
  count  = var.deploy_webapp ? 1 : 0
  bucket = aws_s3_bucket.webapp_frontend[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFront"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.webapp_frontend[0].arn}/*"
      Condition = {
        StringEquals = { "AWS:SourceArn" = aws_cloudfront_distribution.webapp[0].arn }
      }
    }]
  })
}

# ──────────────────────────────────────────────────────────────────────────────
# LAYER 6: EC2 (optional, standalone)
# ──────────────────────────────────────────────────────────────────────────────

data "aws_vpc" "default" {
  count   = var.deploy_ec2 ? 1 : 0
  default = true
}

data "aws_subnets" "default" {
  count = var.deploy_ec2 ? 1 : 0
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default[0].id]
  }
}

module "ec2" {
  count  = var.deploy_ec2 ? 1 : 0
  source = "../../modules/ec2"

  instance_name = "biti-test"
  vpc_id        = data.aws_vpc.default[0].id
  subnet_id     = data.aws_subnets.default[0].ids[0]
  instance_type = "t3.micro"

  root_volume_size    = 8
  associate_public_ip = true

  create_cpu_alarm       = false
  create_status_alarm    = false
  create_composite_alarm = false

  tags = local.tags
}

# ──────────────────────────────────────────────────────────────────────────────
# DATA SOURCES
# ──────────────────────────────────────────────────────────────────────────────

data "aws_caller_identity" "current" {}

# ──────────────────────────────────────────────────────────────────────────────
# OUTPUTS
# ──────────────────────────────────────────────────────────────────────────────

output "s3_bucket_id" {
  value = module.s3.bucket_id
}

output "s3_bucket_arn" {
  value = module.s3.bucket_arn
}

output "dynamodb_table_name" {
  value = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  value = module.dynamodb.table_arn
}

output "lambda_inference_arn" {
  value = module.lambda_inference.function_arn
}

output "step_function_arn" {
  value = module.step_functions.state_machine_arn
}

output "step_function_name" {
  value = module.step_functions.state_machine_name
}

output "sagemaker_endpoint_name" {
  value = var.deploy_sagemaker ? module.sagemaker[0].endpoint_name : "not deployed"
}

output "webapp_cloudfront_url" {
  value = var.deploy_webapp ? "https://${aws_cloudfront_distribution.webapp[0].domain_name}" : "not deployed"
}

output "webapp_api_url" {
  value = var.deploy_webapp ? "${aws_apigatewayv2_api.webapp[0].api_endpoint}/${var.environment}/api/predictions" : "not deployed"
}

output "ec2_public_ip" {
  value = var.deploy_ec2 ? module.ec2[0].instance_public_ip : "not deployed"
}
