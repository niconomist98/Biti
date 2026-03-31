################################################################################
# Lambda Module - Input Variables
################################################################################

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,64}$", var.function_name))
    error_message = "Function name must be 1-64 characters and contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "source_dir" {
  description = "Path to the source code directory to be zipped and deployed"
  type        = string

  validation {
    condition     = fileexists(var.source_dir) || can(file("${var.source_dir}/index.py")) || can(file("${var.source_dir}/index.js"))
    error_message = "Source directory must exist and contain Lambda handler code."
  }
}

variable "handler" {
  description = "Lambda handler in the format index.handler (filename.function)"
  type        = string
  default     = "index.handler"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]+\\.[a-zA-Z0-9_-]+$", var.handler))
    error_message = "Handler must be in format: filename.function"
  }
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.11"

  validation {
    condition = contains([
      "python3.9", "python3.10", "python3.11", "python3.12",
      "nodejs18.x", "nodejs20.x",
      "java11", "java17", "java21",
      "go1.x",
      "ruby3.2", "ruby3.3",
      "dotnet6", "dotnet8"
    ], var.runtime)
    error_message = "Runtime must be a supported Lambda runtime."
  }
}

variable "timeout" {
  description = "Lambda function timeout in seconds (1-900)"
  type        = number
  default     = 60

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "Timeout must be between 1 and 900 seconds."
  }
}

variable "memory_size" {
  description = "Lambda memory allocation in MB (128-10240)"
  type        = number
  default     = 256

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240 && var.memory_size % 1 == 0
    error_message = "Memory size must be between 128 and 10240 MB."
  }
}

variable "publish" {
  description = "Whether to publish version after update"
  type        = bool
  default     = true
}

variable "architectures" {
  description = "Lambda architectures (x86_64 or arm64)"
  type        = list(string)
  default     = ["x86_64"]

  validation {
    condition     = alltrue([for arch in var.architectures : contains(["x86_64", "arm64"], arch)])
    error_message = "Architectures must be x86_64 or arm64."
  }
}

variable "environment_variables" {
  description = "Environment variables to pass to the Lambda function"
  type        = map(string)
  default     = {}
}

variable "vpc_config" {
  description = "VPC configuration for Lambda"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "ephemeral_storage_size" {
  description = "Ephemeral storage size in MB (512-10240)"
  type        = number
  default     = null

  validation {
    condition     = var.ephemeral_storage_size == null || (var.ephemeral_storage_size >= 512 && var.ephemeral_storage_size <= 10240)
    error_message = "Ephemeral storage size must be between 512 and 10240 MB."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch value."
  }
}

variable "log_format" {
  description = "CloudWatch log format (Text or JSON)"
  type        = string
  default     = "Text"

  validation {
    condition     = contains(["Text", "JSON"], var.log_format)
    error_message = "Log format must be Text or JSON."
  }
}

variable "layers" {
  description = "List of Lambda layer ARNs"
  type        = list(string)
  default     = null
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions (-1 for no limit)"
  type        = number
  default     = -1

  validation {
    condition     = var.reserved_concurrent_executions == -1 || var.reserved_concurrent_executions >= 0
    error_message = "Reserved concurrent executions must be -1 or non-negative."
  }
}

variable "enable_alias" {
  description = "Enable Lambda alias for blue-green deployments"
  type        = bool
  default     = false
}

variable "alias_name" {
  description = "Name of the Lambda alias"
  type        = string
  default     = "live"
}

variable "enable_function_url" {
  description = "Enable Lambda function URL for public HTTP endpoints"
  type        = bool
  default     = false
}

variable "function_url_auth_type" {
  description = "Function URL authorization type (AWS_IAM or NONE)"
  type        = string
  default     = "AWS_IAM"

  validation {
    condition     = contains(["AWS_IAM", "NONE"], var.function_url_auth_type)
    error_message = "Authorization type must be AWS_IAM or NONE."
  }
}

variable "cors_allow_credentials" {
  description = "Allow credentials in CORS requests"
  type        = bool
  default     = false
}

variable "cors_allow_headers" {
  description = "CORS allowed headers"
  type        = list(string)
  default     = ["x-custom-header"]
}

variable "cors_allow_methods" {
  description = "CORS allowed methods"
  type        = list(string)
  default     = ["GET", "POST"]
}

variable "cors_allow_origins" {
  description = "CORS allowed origins"
  type        = list(string)
  default     = ["*"]
}

variable "cors_expose_headers" {
  description = "CORS expose headers"
  type        = list(string)
  default     = ["x-custom-header"]
}

variable "cors_max_age" {
  description = "CORS max age in seconds"
  type        = number
  default     = 86400
}

variable "create_error_alarm" {
  description = "Create CloudWatch alarm for function errors"
  type        = bool
  default     = true
}

variable "error_threshold" {
  description = "Error threshold for alarm"
  type        = number
  default     = 5
}

variable "create_throttle_alarm" {
  description = "Create CloudWatch alarm for function throttles"
  type        = bool
  default     = true
}

variable "throttle_threshold" {
  description = "Throttle threshold for alarm"
  type        = number
  default     = 1
}

variable "create_duration_alarm" {
  description = "Create CloudWatch alarm for high function duration"
  type        = bool
  default     = true
}

variable "duration_threshold" {
  description = "Duration threshold in milliseconds for alarm"
  type        = number
  default     = 30000
}

variable "create_composite_alarm" {
  description = "Create composite alarm for overall Lambda health"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "SNS topic ARNs for alarm actions"
  type        = list(string)
  default     = []
}

variable "schedule_expression" {
  description = "EventBridge schedule expression for periodic invocation"
  type        = string
  default     = null
}

variable "schedule_input" {
  description = "JSON input for scheduled invocation"
  type        = string
  default     = null
}

variable "enable_xray_tracing" {
  description = "Enable X-Ray tracing"
  type        = bool
  default     = false
}

variable "enable_insights" {
  description = "Enable Lambda Insights monitoring"
  type        = bool
  default     = false
}

variable "custom_policies" {
  description = "Map of custom IAM policies to attach"
  type        = map(string)
  default     = null
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
