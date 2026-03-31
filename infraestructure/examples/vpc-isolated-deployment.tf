# Example 3: Deployment with VPC Isolation
# Usage: terraform apply -var-file=examples/vpc-deployment.tfvars

# This example assumes VPC infrastructure is already created
# Modify the subnet and security group IDs to match your VPC setup

module "pytorch_vpc_isolated" {
  source = "../modules/sagemaker_model_deployment"

  project_name               = "biti"
  environment                = "prod"
  model_name                 = "crypto-predictor-vpc"
  endpoint_name             = "crypto-predictor-vpc"
  model_artifact_s3_uri     = "s3://biti-ml-models/models/crypto-predictor-prod/v1.0/model.tar.gz"
  model_container_image_uri = "382416733822.dkr.ecr.us-east-1.amazonaws.com/sagemaker-pytorch:2.1-cpu-py310"

  aws_region = "us-east-1"

  # Instance Configuration
  instance_type          = "ml.p3.2xlarge"  # GPU instance for high performance
  initial_instance_count = 1

  # VPC Configuration - Network Isolation
  vpc_config = {
    # Must be private subnets with NAT Gateway for S3 access
    subnet_ids = [
      "subnet-12345678",  # Private subnet in AZ-a
      "subnet-87654321"   # Private subnet in AZ-b
    ]
    # Security group must allow outbound HTTPS (443) to S3
    security_group_ids = [
      "sg-sagemaker-12345"
    ]
  }

  # Auto-Scaling
  autoscaling_config = {
    min_capacity               = 1
    max_capacity               = 5
    target_value               = 75.0
    scale_in_cooldown_seconds  = 600
    scale_out_cooldown_seconds = 300
  }

  # Monitoring
  enable_monitoring       = true
  enable_data_capture     = true
  data_capture_s3_prefix = "s3://biti-ml-models/data-capture/vpc-isolated/"
  enable_xray_tracing     = true

  # Security Tags
  tags = {
    Project        = "Biti"
    Environment    = "Production"
    SecurityLevel  = "High"
    NetworkScope   = "VPC"
    Team           = "ML-Platform"
    CreatedBy      = "Terraform"
  }
}

output "vpc_endpoint_name" {
  value       = module.pytorch_vpc_isolated.endpoint_name
  description = "VPC-isolated SageMaker endpoint name"
}

output "vpc_endpoint_arn" {
  value       = module.pytorch_vpc_isolated.endpoint_arn
  description = "VPC-isolated endpoint ARN"
}

output "vpc_sagemaker_role_arn" {
  value       = module.pytorch_vpc_isolated.sagemaker_role_arn
  description = "IAM role ARN used by SageMaker"
}
