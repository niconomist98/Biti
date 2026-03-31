# DynamoDB Module Variables

variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_.-]{3,255}$", var.table_name))
    error_message = "Table name must be 3-255 characters containing only alphanumeric characters, hyphens, underscores, and dots"
  }
}

variable "billing_mode" {
  description = "Billing mode for the table (PAY_PER_REQUEST or PROVISIONED)"
  type        = string
  default     = "PAY_PER_REQUEST"
  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "Billing mode must be PAY_PER_REQUEST or PROVISIONED"
  }
}

variable "hash_key" {
  description = "Name of the hash key (partition key)"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]{1,255}$", var.hash_key))
    error_message = "Hash key must be 1-255 characters"
  }
}

variable "range_key" {
  description = "Name of the range key (sort key)"
  type        = string
  default     = null
}

variable "read_capacity" {
  description = "Read capacity units (for PROVISIONED billing mode)"
  type        = number
  default     = 5
  validation {
    condition     = var.read_capacity >= 1 && var.read_capacity <= 40000
    error_message = "Read capacity must be between 1 and 40000"
  }
}

variable "write_capacity" {
  description = "Write capacity units (for PROVISIONED billing mode)"
  type        = number
  default     = 5
  validation {
    condition     = var.write_capacity >= 1 && var.write_capacity <= 40000
    error_message = "Write capacity must be between 1 and 40000"
  }
}

variable "additional_attributes" {
  description = "List of additional attributes (name and type combinations)"
  type = list(object({
    name = string
    type = string
  }))
  default = []
  # Example:
  # [
  #   { name = "user_id", type = "S" },
  #   { name = "email", type = "S" }
  # ]
  # Types: S = String, N = Number, B = Binary
}

variable "global_secondary_indexes" {
  description = "List of global secondary indexes"
  type = list(object({
    name            = string
    hash_key        = string
    range_key       = optional(string)
    projection_type = string
    read_capacity   = optional(number, 5)
    write_capacity  = optional(number, 5)
  }))
  default = []
  # Example:
  # [
  #   {
  #     name            = "email-index"
  #     hash_key        = "email"
  #     projection_type = "ALL"
  #     read_capacity   = 10
  #     write_capacity  = 10
  #   }
  # ]
}

variable "local_secondary_indexes" {
  description = "List of local secondary indexes"
  type = list(object({
    name            = string
    range_key       = string
    projection_type = string
  }))
  default = []
  # Example:
  # [
  #   {
  #     name            = "timestamp-index"
  #     range_key       = "timestamp"
  #     projection_type = "ALL"
  #   }
  # ]
}

variable "ttl_attribute_name" {
  description = "Name of attribute to use for TTL (item expiration)"
  type        = string
  default     = null
  # Example: "expiration_timestamp"
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = true
}

variable "enable_encryption" {
  description = "Enable server-side encryption"
  type        = bool
  default     = true
}

variable "encryption_key_arn" {
  description = "ARN of KMS key for encryption (uses AWS managed key if not specified)"
  type        = string
  default     = null
}

variable "enable_streams" {
  description = "Enable DynamoDB Streams"
  type        = bool
  default     = false
}

variable "stream_view_type" {
  description = "DynamoDB Streams view type (KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES)"
  type        = string
  default     = "NEW_AND_OLD_IMAGES"
  validation {
    condition     = contains(["KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES"], var.stream_view_type)
    error_message = "Stream view type must be KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, or NEW_AND_OLD_IMAGES"
  }
}

variable "stream_specification" {
  description = "Stream specification configuration"
  type = object({
    stream_enabled   = bool
    stream_view_type = string
  })
  default = null
}

variable "enable_autoscaling" {
  description = "Enable auto-scaling for provisioned capacity"
  type        = bool
  default     = true
}

variable "autoscaling_max_read_capacity" {
  description = "Maximum read capacity for auto-scaling"
  type        = number
  default     = 40000
  validation {
    condition     = var.autoscaling_max_read_capacity >= 1 && var.autoscaling_max_read_capacity <= 40000
    error_message = "Max read capacity must be between 1 and 40000"
  }
}

variable "autoscaling_max_write_capacity" {
  description = "Maximum write capacity for auto-scaling"
  type        = number
  default     = 40000
  validation {
    condition     = var.autoscaling_max_write_capacity >= 1 && var.autoscaling_max_write_capacity <= 40000
    error_message = "Max write capacity must be between 1 and 40000"
  }
}

variable "autoscaling_target_utilization" {
  description = "Target utilization for auto-scaling (as percentage)"
  type        = number
  default     = 70
  validation {
    condition     = var.autoscaling_target_utilization > 0 && var.autoscaling_target_utilization < 100
    error_message = "Target utilization must be between 0 and 100"
  }
}

variable "autoscaling_scale_out_cooldown" {
  description = "Scale-out cooldown period in seconds"
  type        = number
  default     = 60
}

variable "autoscaling_scale_in_cooldown" {
  description = "Scale-in cooldown period in seconds"
  type        = number
  default     = 300
}

variable "enable_alarms" {
  description = "Enable CloudWatch alarms for throttling and errors"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "List of SNS ARNs for alarm notifications"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Log retention must be a valid CloudWatch value"
  }
}

variable "enable_backup_vault" {
  description = "Enable AWS Backup for DynamoDB"
  type        = bool
  default     = false
}

variable "backup_schedule" {
  description = "Backup schedule in cron format"
  type        = string
  default     = "cron(0 5 ? * * *)"
  # Example: "cron(0 5 ? * * *)" = Daily at 5 AM UTC
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

variable "enable_global_table" {
  description = "Enable global table for cross-region replication"
  type        = bool
  default     = false
}

variable "replica_regions" {
  description = "List of AWS regions for global table replicas"
  type        = list(string)
  default     = []
  # Example: ["us-west-2", "eu-west-1"]
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
