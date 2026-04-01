variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

# DynamoDB Table Deployment

module "biti_predictions" {
  source = "../../modules/dynamodb"

  table_name   = "biti-predictions-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "symbol"
  range_key    = "timestamp"

  enable_point_in_time_recovery = true
  enable_encryption             = true
  enable_streams                = false
  enable_alarms                 = false
  enable_backup_vault           = false

  tags = {
    Project     = "Biti"
    Environment = var.environment
  }
}

output "table_name" {
  value = module.biti_predictions.table_name
}

output "table_arn" {
  value = module.biti_predictions.table_arn
}
