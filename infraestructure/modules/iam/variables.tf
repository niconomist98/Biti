# IAM Module Variables

variable "role_name" {
  description = "Name of the IAM role"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9+=,.@_-]{1,64}$", var.role_name))
    error_message = "Role name must be 1-64 characters and contain only alphanumeric characters and +=,.@_-"
  }
}

variable "role_description" {
  description = "Description of the IAM role"
  type        = string
  default     = ""
}

variable "trust_entity_type" {
  description = "Type of entity that can assume the role (Service, AWS, Federated, CanonicalUser)"
  type        = string
  validation {
    condition     = contains(["Service", "AWS", "Federated", "CanonicalUser"], var.trust_entity_type)
    error_message = "Trust entity type must be Service, AWS, Federated, or CanonicalUser"
  }
}

variable "trust_entity_identifiers" {
  description = "Identifiers for the trust relationship (ARNs or service principals)"
  type        = list(string)
  validation {
    condition     = length(var.trust_entity_identifiers) > 0
    error_message = "At least one trust entity identifier must be provided"
  }
}

variable "assume_role_conditions" {
  description = "Conditions for assuming the role (MFA, IP restrictions, etc.)"
  type = list(object({
    test     = string
    variable = string
    values   = list(string)
  }))
  default = []
  # Examples:
  # [{
  #   test     = "Bool"
  #   variable = "aws:MultiFactorAuthPresent"
  #   values   = ["true"]
  # }]
}

variable "inline_policies" {
  description = "Map of inline policies to attach to the role"
  type        = map(string)
  default     = {}
  # Example:
  # {
  #   "s3-read" = jsonencode({
  #     Version = "2012-10-17"
  #     Statement = [{
  #       Effect   = "Allow"
  #       Action   = "s3:GetObject"
  #       Resource = "arn:aws:s3:::my-bucket/*"
  #     }]
  #   })
  # }
}

variable "managed_policy_arns" {
  description = "List of managed policy ARNs to attach to the role"
  type        = list(string)
  default     = []
  # Examples:
  # ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
  # ["arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"]
}

variable "create_custom_policy" {
  description = "Whether to create a custom managed policy"
  type        = bool
  default     = false
}

variable "custom_policy_document" {
  description = "JSON policy document for custom managed policy"
  type        = string
  default     = ""
}

variable "create_instance_profile" {
  description = "Whether to create an instance profile for EC2 usage"
  type        = bool
  default     = false
}

variable "permission_boundary_arn" {
  description = "ARN of permission boundary to apply to the role"
  type        = string
  default     = ""
  # Example: "arn:aws:iam::aws:policy/PowerUserAccess"
}

variable "max_session_duration" {
  description = "Maximum session duration for the role in seconds"
  type        = number
  default     = 3600
  validation {
    condition     = var.max_session_duration >= 900 && var.max_session_duration <= 43200
    error_message = "Session duration must be between 15 minutes (900s) and 12 hours (43200s)"
  }
}

variable "session_tags" {
  description = "Session tags for Attribute Based Access Control (ABAC)"
  type        = map(string)
  default     = {}
  # Example:
  # {
  #   "department" = "finance"
  #   "environment" = "production"
  # }
}

variable "enable_iam_access_logging" {
  description = "Enable CloudWatch logging for IAM access"
  type        = bool
  default     = false
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail for detailed IAM activity logging"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention period in days"
  type        = number
  default     = 30
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch value: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, or 3653 days"
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
