# SageMaker Model Deployment Module - Variables

variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project - used to tag and name resources"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{3,32}$", var.project_name))
    error_message = "Project name must be 3-32 characters, lowercase letters, numbers and hyphens only."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "model_name" {
  description = "Name of the SageMaker model"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,63}$", var.model_name))
    error_message = "Model name must be 1-63 characters, alphanumeric and hyphens only."
  }
}

variable "model_artifact_s3_uri" {
  description = "S3 URI of the model artifact (e.g., s3://my-bucket/path/to/model.tar.gz)"
  type        = string
  validation {
    condition     = can(regex("^s3://[a-z0-9-]+/.*", var.model_artifact_s3_uri))
    error_message = "Must be a valid S3 URI format (s3://bucket-name/path)."
  }
}

variable "model_container_image_uri" {
  description = "Container image URI for the model framework (ECR URI or SageMaker built-in algorithm URI)"
  type        = string
  example     = "382416733822.dkr.ecr.us-east-1.amazonaws.com/pca:latest"
}

variable "endpoint_name" {
  description = "Name of the SageMaker endpoint"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,63}$", var.endpoint_name))
    error_message = "Endpoint name must be 1-63 characters, alphanumeric and hyphens only."
  }
}

variable "instance_type" {
  description = "SageMaker instance type for the endpoint"
  type        = string
  default     = "ml.t3.medium"
  validation {
    condition     = can(regex("^ml\\.[a-z0-9]+\\.[a-z0-9]+$", var.instance_type))
    error_message = "Instance type must be valid SageMaker instance type (e.g., ml.t3.medium)."
  }
}

variable "initial_instance_count" {
  description = "Initial number of instances for the endpoint"
  type        = number
  default     = 1
  validation {
    condition     = var.initial_instance_count > 0 && var.initial_instance_count <= 100
    error_message = "Initial instance count must be between 1 and 100."
  }
}

variable "model_memory_size_in_mb" {
  description = "Amount of memory in MB allocated to model container"
  type        = number
  default     = 512
  validation {
    condition     = var.model_memory_size_in_mb >= 128 && var.model_memory_size_in_mb <= 30720
    error_message = "Model memory size must be between 128 MB and 30720 MB."
  }
}

variable "vpc_config" {
  description = "VPC configuration for the endpoint (optional)"
  type = object({
    subnet_ids             = list(string)
    security_group_ids     = list(string)
  })
  default = null
}

variable "enable_data_capture" {
  description = "Enable data capture for model monitoring"
  type        = bool
  default     = false
}

variable "data_capture_s3_prefix" {
  description = "S3 prefix for captured data (optional, only if enable_data_capture is true)"
  type        = string
  default     = null
}

variable "autoscaling_config" {
  description = "Auto scaling configuration for the endpoint"
  type = object({
    min_capacity               = number
    max_capacity               = number
    target_value               = number
    scale_in_cooldown_seconds  = number
    scale_out_cooldown_seconds = number
  })
  default = null
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing for the endpoint"
  type        = bool
  default     = false
}

variable "model_environment_variables" {
  description = "Environment variables to pass to the model container"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring for the endpoint"
  type        = bool
  default     = true
}

variable "custom_model_data_url" {
  description = "Custom model data S3 URL (optional, different from model artifact)"
  type        = string
  default     = null
}

variable "framework" {
  description = "ML framework used (pytorch, tensorflow, sklearn, xgboost, etc.)"
  type        = string
  default     = "pytorch"
}

variable "framework_version" {
  description = "Framework version"
  type        = string
  default     = "1.12"
}

variable "py_version" {
  description = "Python version"
  type        = string
  default     = "py38"
}
