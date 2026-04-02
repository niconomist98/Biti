################################################################################
# Glue Module - Input Variables
################################################################################

variable "job_name" {
  description = "Name of the Glue job"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,255}$", var.job_name))
    error_message = "Job name must be 1-255 characters and contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "script_location" {
  description = "S3 path to the Glue job script (e.g. s3://bucket/scripts/job.py)"
  type        = string

  validation {
    condition     = can(regex("^s3://", var.script_location))
    error_message = "Script location must be an S3 path starting with s3://."
  }
}

variable "job_type" {
  description = "Type of Glue job (glueetl or pythonshell)"
  type        = string
  default     = "glueetl"

  validation {
    condition     = contains(["glueetl", "pythonshell"], var.job_type)
    error_message = "Job type must be glueetl or pythonshell."
  }
}

variable "glue_version" {
  description = "Glue version to use"
  type        = string
  default     = "4.0"

  validation {
    condition     = contains(["2.0", "3.0", "4.0"], var.glue_version)
    error_message = "Glue version must be 2.0, 3.0, or 4.0."
  }
}

variable "python_version" {
  description = "Python version (3 or 3.9)"
  type        = string
  default     = "3"

  validation {
    condition     = contains(["3", "3.9"], var.python_version)
    error_message = "Python version must be 3 or 3.9."
  }
}

variable "worker_type" {
  description = "Worker type for ETL jobs (Standard, G.1X, G.2X, G.025X)"
  type        = string
  default     = "G.1X"

  validation {
    condition     = contains(["Standard", "G.1X", "G.2X", "G.025X"], var.worker_type)
    error_message = "Worker type must be Standard, G.1X, G.2X, or G.025X."
  }
}

variable "number_of_workers" {
  description = "Number of workers for ETL jobs (2-299)"
  type        = number
  default     = 2

  validation {
    condition     = var.number_of_workers >= 2 && var.number_of_workers <= 299
    error_message = "Number of workers must be between 2 and 299."
  }
}

variable "max_capacity" {
  description = "Max DPU capacity for Python Shell jobs (0.0625 or 1.0)"
  type        = number
  default     = 0.0625

  validation {
    condition     = contains([0.0625, 1.0], var.max_capacity)
    error_message = "Max capacity for Python Shell must be 0.0625 or 1.0."
  }
}

variable "timeout" {
  description = "Job timeout in minutes (1-2880)"
  type        = number
  default     = 60

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 2880
    error_message = "Timeout must be between 1 and 2880 minutes."
  }
}

variable "max_retries" {
  description = "Maximum number of retries (0-10)"
  type        = number
  default     = 0

  validation {
    condition     = var.max_retries >= 0 && var.max_retries <= 10
    error_message = "Max retries must be between 0 and 10."
  }
}

variable "max_concurrent_runs" {
  description = "Maximum concurrent job runs"
  type        = number
  default     = null
}

variable "default_arguments" {
  description = "Additional default arguments for the Glue job"
  type        = map(string)
  default     = {}
}

variable "connections" {
  description = "List of Glue connection names"
  type        = list(string)
  default     = []
}

variable "s3_access_arns" {
  description = "List of S3 ARNs the Glue job needs access to (buckets and prefixes)"
  type        = list(string)

  validation {
    condition     = alltrue([for arn in var.s3_access_arns : can(regex("^arn:aws:s3:::", arn))])
    error_message = "All S3 access ARNs must be valid S3 ARNs."
  }
}

variable "custom_policies" {
  description = "Map of custom IAM policies to attach"
  type        = map(string)
  default     = null
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

variable "schedule_expression" {
  description = "Cron expression for scheduled trigger (e.g. cron(0 2 * * ? *))"
  type        = string
  default     = null
}

variable "schedule_enabled" {
  description = "Whether the schedule trigger is enabled"
  type        = bool
  default     = true
}

variable "schedule_arguments" {
  description = "Arguments to pass when triggered by schedule"
  type        = map(string)
  default     = {}
}

variable "create_failure_alarm" {
  description = "Create CloudWatch alarm for job failures"
  type        = bool
  default     = true
}

variable "failure_threshold" {
  description = "Failure count threshold for alarm"
  type        = number
  default     = 1
}

variable "create_duration_alarm" {
  description = "Create CloudWatch alarm for high job duration"
  type        = bool
  default     = false
}

variable "duration_threshold" {
  description = "Duration threshold in milliseconds for alarm"
  type        = number
  default     = 3600000
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
