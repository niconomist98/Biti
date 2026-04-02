################################################################################
# Step Functions Module - Input Variables
################################################################################

variable "state_machine_name" {
  description = "Name of the Step Functions state machine"
  type        = string
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function to invoke"
  type        = string
}

variable "max_retry_attempts" {
  description = "Max retry attempts for Lambda invocation"
  type        = number
  default     = 3
}

variable "schedule_expression" {
  description = "EventBridge schedule expression (e.g. rate(5 minutes))"
  type        = string
  default     = null
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
