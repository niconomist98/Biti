# DynamoDB Table Examples

# Example 1: Simple user profile table
module "users_table" {
  source = "../modules/dynamodb"

  table_name   = "user-profiles"
  hash_key     = "user_id"
  billing_mode = "PAY_PER_REQUEST"

  additional_attributes = [
    { name = "email", type = "S" }
  ]

  global_secondary_indexes = [
    {
      name            = "email-index"
      hash_key        = "email"
      projection_type = "ALL"
    }
  ]

  enable_point_in_time_recovery = true
  enable_streams = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = {
    Application = "user-service"
    Environment = "production"
  }
}

# Example 2: Order table with provisioned capacity and auto-scaling
module "orders_table" {
  source = "../modules/dynamodb"

  table_name      = "e-commerce-orders"
  hash_key        = "order_id"
  range_key       = "order_date"
  billing_mode    = "PROVISIONED"
  read_capacity   = 20
  write_capacity  = 20

  additional_attributes = [
    { name = "customer_id", type = "S" },
    { name = "status", type = "S" }
  ]

  global_secondary_indexes = [
    {
      name            = "customer-id-index"
      hash_key        = "customer_id"
      range_key       = "order_date"
      projection_type = "ALL"
      read_capacity   = 15
      write_capacity  = 15
    },
    {
      name            = "status-index"
      hash_key        = "status"
      range_key       = "order_date"
      projection_type = "KEYS_ONLY"
      read_capacity   = 10
      write_capacity  = 5
    }
  ]

  enable_autoscaling = true
  autoscaling_max_read_capacity  = 1000
  autoscaling_max_write_capacity = 500
  autoscaling_target_utilization = 70

  enable_alarms = true
  alarm_actions = [] # Add SNS topic ARN for notifications

  enable_point_in_time_recovery = true
  enable_encryption = true

  tags = {
    Application = "e-commerce"
    Environment = "production"
  }
}

# Example 3: Session table with TTL (automatic expiration)
module "sessions_table" {
  source = "../modules/dynamodb"

  table_name           = "web-sessions"
  hash_key             = "session_id"
  billing_mode         = "PAY_PER_REQUEST"
  ttl_attribute_name   = "expiration_timestamp"

  enable_streams = true
  stream_view_type = "KEYS_ONLY"

  tags = {
    Application = "web-portal"
    Environment = "production"
  }
}

# Example 4: Real-time events table with streams for Lambda processing
module "events_table" {
  source = "../modules/dynamodb"

  table_name   = "real-time-events"
  hash_key     = "event_id"
  range_key    = "timestamp"
  billing_mode = "PAY_PER_REQUEST"

  additional_attributes = [
    { name = "event_type", type = "S" },
    { name = "user_id", type = "S" }
  ]

  global_secondary_indexes = [
    {
      name            = "user-id-timestamp-index"
      hash_key        = "user_id"
      range_key       = "timestamp"
      projection_type = "ALL"
    },
    {
      name            = "event-type-timestamp-index"
      hash_key        = "event_type"
      range_key       = "timestamp"
      projection_type = "KEYS_ONLY"
    }
  ]

  enable_streams = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  enable_point_in_time_recovery = true

  tags = {
    Application = "analytics"
    Environment = "production"
  }
}

# Example 5: Analytics table with backup and global replication
module "analytics_global_table" {
  source = "../modules/dynamodb"

  table_name   = "global-analytics"
  hash_key     = "metric_id"
  range_key    = "timestamp"
  billing_mode = "PAY_PER_REQUEST"

  additional_attributes = [
    { name = "region", type = "S" },
    { name = "metric_type", type = "S" }
  ]

  global_secondary_indexes = [
    {
      name            = "region-timestamp-index"
      hash_key        = "region"
      range_key       = "timestamp"
      projection_type = "ALL"
    }
  ]

  enable_point_in_time_recovery = true
  enable_encryption = true
  enable_streams = true

  # Enable global table for multi-region
  enable_global_table = true
  replica_regions = [
    "us-west-2",
    "eu-west-1"
  ]

  # Enable backups
  enable_backup_vault = true
  backup_schedule     = "cron(0 2 ? * * *)"  # 2 AM UTC daily
  backup_retention_days = 90

  enable_alarms = true

  tags = {
    Application = "global-analytics"
    Environment = "production"
    Compliance  = "data-retention"
  }
}

# Example 6: Sensitive data table with encryption and audit logs
module "encrypted_audit_table" {
  source = "../modules/dynamodb"

  table_name   = "audit-logs"
  hash_key     = "entity_id"
  range_key    = "timestamp"
  billing_mode = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 10

  additional_attributes = [
    { name = "action", type = "S" },
    { name = "user_id", type = "S" }
  ]

  local_secondary_indexes = [
    {
      name            = "user-action-index"
      range_key       = "action"
      projection_type = "ALL"
    }
  ]

  enable_autoscaling = true
  autoscaling_max_read_capacity  = 100
  autoscaling_max_write_capacity = 200

  # Security
  enable_encryption = true
  enable_point_in_time_recovery = true

  # Backup and retention
  enable_backup_vault = true
  backup_schedule     = "cron(0 1 ? * ? *)"  # Daily at 1 AM UTC
  backup_retention_days = 365  # 1 year retention

  enable_alarms = true
  alarm_actions = []  # Add SNS topic for compliance notifications

  tags = {
    Application = "audit"
    Environment = "production"
    Compliance  = "sox"
    Encryption  = "required"
  }
}

# Example 7: Development/Testing table
module "dev_test_table" {
  source = "../modules/dynamodb"

  table_name   = "dev-test-data"
  hash_key     = "test_id"
  billing_mode = "PAY_PER_REQUEST"

  # TTL for automatic cleanup
  ttl_attribute_name = "ttl"

  enable_point_in_time_recovery = false  # Not needed for dev
  enable_backup_vault = false

  tags = {
    Application = "testing"
    Environment = "development"
  }
}
