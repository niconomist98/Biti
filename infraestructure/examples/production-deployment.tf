# Example 2: Production PyTorch Deployment with Auto-Scaling and Monitoring
# Usage: terraform apply -var-file=examples/pytorch-production.tfvars

module "pytorch_production" {
  source = "../modules/sagemaker_model_deployment"

  project_name               = "biti"
  environment                = "prod"
  model_name                 = "crypto-predictor-prod"
  endpoint_name             = "crypto-predictor-prod"
  model_artifact_s3_uri     = "s3://biti-ml-models/models/crypto-predictor-prod/v1.0/model.tar.gz"
  model_container_image_uri = "382416733822.dkr.ecr.us-east-1.amazonaws.com/sagemaker-pytorch:2.1-cpu-py310"

  aws_region = "us-east-1"

  # Instance Configuration - GPU for faster inference
  instance_type          = "ml.g4dn.xlarge"  # GPU instance
  initial_instance_count = 2

  # Auto-Scaling Configuration
  autoscaling_config = {
    min_capacity               = 2
    max_capacity               = 10
    target_value               = 70.0
    scale_in_cooldown_seconds  = 300
    scale_out_cooldown_seconds = 60
  }

  # Monitoring & Data Capture
  enable_monitoring       = true
  enable_data_capture     = true
  data_capture_s3_prefix = "s3://biti-ml-models/data-capture/crypto-predictor/"

  # X-Ray Tracing for debugging
  enable_xray_tracing = true

  # Environment Variables
  model_environment_variables = {
    MODEL_VERSION  = "1.0.0"
    INFERENCE_MODE = "production"
    LOG_LEVEL     = "INFO"
  }

  tags = {
    Project     = "Biti"
    Environment = "Production"
    Team        = "ML-Platform"
    CostCenter  = "Engineering"
    CreatedBy   = "Terraform"
    Owner       = "DataScience"
  }
}

output "prod_endpoint_name" {
  value       = module.pytorch_production.endpoint_name
  description = "Production SageMaker endpoint name"
}

output "prod_model_name" {
  value       = module.pytorch_production.model_name
  description = "Production SageMaker model name"
}

output "prod_deployment_info" {
  value       = module.pytorch_production.deployment_info
  description = "Complete production deployment information"
}

output "prod_prediction_command" {
  value       = module.pytorch_production.prediction_command
  description = "AWS CLI command to test the production endpoint"
}

output "prod_cloudwatch_alarms" {
  value       = module.pytorch_production.cloudwatch_alarms
  description = "CloudWatch alarm names for monitoring"
}
