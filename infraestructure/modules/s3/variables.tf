################################################################################
# S3 Module - Input Variables
################################################################################

variable "bucket_name" {
  description = "S3 bucket name (must be globally unique)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name)) && length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be 3-63 characters, start and end with alphanumeric, contain only lowercase letters, numbers, and hyphens."
  }
}

variable "acl" {
  description = "Canned ACL to apply (private, public-read, public-read-write, etc.)"
  type        = string
  default     = null

  validation {
    condition     = var.acl == null || contains(["private", "public-read", "public-read-write", "aws-exec-read", "authenticated-read", "bucket-owner-read", "bucket-owner-full-control", "log-delivery-write"], var.acl)
    error_message = "ACL must be a valid S3 canned ACL."
  }
}

variable "block_public_access" {
  description = "Block all public access to the bucket"
  type        = bool
  default     = true
}

variable "enable_versioning" {
  description = "Enable bucket versioning"
  type        = bool
  default     = true
}

variable "enable_mfa_delete" {
  description = "Enable MFA delete protection"
  type        = bool
  default     = false
}

variable "encryption_algorithm" {
  description = "Server-side encryption algorithm (AES256 or aws:kms)"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_algorithm)
    error_message = "Encryption algorithm must be AES256 or aws:kms."
  }
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (required if encryption_algorithm is aws:kms)"
  type        = string
  default     = null
}

variable "enable_logging" {
  description = "Enable S3 access logging"
  type        = bool
  default     = true
}

variable "logging_bucket" {
  description = "Bucket name for access logs (creates one if null)"
  type        = string
  default     = null
}

variable "logging_prefix" {
  description = "Prefix for access logs"
  type        = string
  default     = "logs/"
}

variable "cors_rules" {
  description = "CORS rules for the bucket"
  type = list(object({
    allowed_headers = optional(list(string))
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string))
    max_age_seconds = optional(number, 3000)
  }))
  default = null
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for the bucket"
  type = list(object({
    id                          = string
    status                      = optional(string, "Enabled")
    prefix                      = optional(string, "")
    transitions                 = optional(list(object({
      days          = number
      storage_class = string
    })))
    expiration_days             = optional(number)
    noncurrent_transitions      = optional(list(object({
      days          = number
      storage_class = string
    })))
    noncurrent_expiration_days  = optional(number)
  }))
  default = null
}

variable "enable_website" {
  description = "Enable website hosting"
  type        = bool
  default     = false
}

variable "index_document" {
  description = "Index document for static website"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "Error document for static website"
  type        = string
  default     = null
}

variable "routing_rules" {
  description = "Routing rules for website"
  type = list(object({
    error_code      = string
    prefix          = optional(string)
    redirect_host   = string
    replace_prefix  = optional(string)
  }))
  default = null
}

variable "replication_config" {
  description = "Replication configuration for cross-region replication"
  type = object({
    destination_bucket         = string
    rules = list(object({
      id                          = string
      status                      = optional(string, "Enabled")
      prefix                      = optional(string, "")
      destination_bucket          = string
      storage_class               = optional(string, "STANDARD")
      replication_time_minutes    = optional(number, 15)
    }))
  })
  default = null
}

variable "enable_metrics" {
  description = "Enable S3 request metrics"
  type        = bool
  default     = false
}

variable "enable_cloudfront_access" {
  description = "Enable bucket access from CloudFront"
  type        = bool
  default     = false
}

variable "bucket_policy" {
  description = "Bucket policy JSON"
  type        = string
  default     = null
}

variable "create_size_alarm" {
  description = "Create CloudWatch alarm for bucket size"
  type        = bool
  default     = false
}

variable "size_threshold" {
  description = "Bucket size threshold in bytes for alarm"
  type        = number
  default     = 107374182400  # 100 GB
}

variable "create_count_alarm" {
  description = "Create CloudWatch alarm for object count"
  type        = bool
  default     = false
}

variable "object_count_threshold" {
  description = "Object count threshold for alarm"
  type        = number
  default     = 1000000
}

variable "alarm_actions" {
  description = "SNS topic ARNs for alarm actions"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
