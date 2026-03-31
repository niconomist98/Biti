# Example 1: Basic PyTorch Model Deployment
# Usage: terraform apply -var-file=examples/pytorch-basic.tfvars

module "pytorch_basic" {
  source = "../modules/sagemaker_model_deployment"

  project_name               = "biti"
  environment                = "dev"
  model_name                 = "crypto-predictor-v1"
  endpoint_name             = "crypto-predictor-dev"
  model_artifact_s3_uri     = "s3://biti-ml-models/models/crypto-predictor/model.tar.gz"
  model_container_image_uri = "382416733822.dkr.ecr.us-east-1.amazonaws.com/sagemaker-pytorch:2.1-cpu-py310"

  aws_region             = "us-east-1"
  instance_type         = "ml.t3.medium"
  initial_instance_count = 1

  enable_monitoring = true

  tags = {
    Project     = "Biti"
    Environment = "Development"
    Team        = "ML-Platform"
    CreatedBy   = "Terraform"
  }
}

output "pytorch_endpoint" {
  value = module.pytorch_basic.endpoint_name
}

output "pytorch_model" {
  value = module.pytorch_basic.model_name
}

output "pytorch_prediction_command" {
  value = module.pytorch_basic.prediction_command
}
