# Main Terraform Configuration - Provider Setup
# This file sets up the AWS provider and backend configuration

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  # Uncomment to use S3 backend for state management in production
  # backend "s3" {
  #   bucket         = "biti-terraform-state"
  #   key            = "sagemaker/terraform.tfstate"
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
      Owner       = "ML-Platform"
      CreatedBy   = "Terraform"
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    }
  }
}
