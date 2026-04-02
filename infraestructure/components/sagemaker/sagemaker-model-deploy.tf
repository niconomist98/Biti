variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Look up the SageMaker XGBoost container image for the region
data "aws_sagemaker_prebuilt_ecr_image" "xgboost" {
  repository_name = "sagemaker-xgboost"
  image_tag       = "1.7-1"
}

module "bitcoin_classifier" {
  source = "../../modules/sagemaker_model_deployment"

  project_name = "biti"
  environment  = var.environment
  aws_region   = var.aws_region

  model_name    = "bitcoin-classifier"
  endpoint_name = "bitcoin-classifier"

  model_artifact_s3_uri    = "s3://biti-data-dev/models/bitcoin-classifier/output/sagemaker-xgboost-2026-04-01-21-14-08-241/output/model.tar.gz"
  model_container_image_uri = data.aws_sagemaker_prebuilt_ecr_image.xgboost.registry_path

  instance_type          = "ml.m5.large"
  initial_instance_count = 1

  framework         = "xgboost"
  framework_version = "1.7-1"

  enable_data_capture = false
  enable_monitoring   = true
  enable_xray_tracing = false

  tags = {
    Project     = "Biti"
    Environment = var.environment
    Model       = "bitcoin-classifier"
  }
}

output "endpoint_name" {
  value = module.bitcoin_classifier.endpoint_name
}

output "endpoint_url" {
  value = module.bitcoin_classifier.endpoint_url
}

output "invoke_command" {
  value = module.bitcoin_classifier.prediction_command
}
