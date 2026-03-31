# AWS DynamoDB Module

Comprehensive Terraform module for deploying AWS DynamoDB tables with advanced features including global secondary indexes, auto-scaling, encryption, point-in-time recovery, backup and restore, and global tables for multi-region deployment.

## Features

✅ **Table Management**
- PAY_PER_REQUEST or PROVISIONED billing modes
- Hash (partition) and Range (sort) keys
- TTL (Time to Live) for automatic item expiration
- Global and Local Secondary Indexes (GSI/LSI)

✅ **Performance & Scaling**
- Auto-scaling for read/write capacity
- Adjustable target utilization
- Configurable scale-out and scale-in cooldowns
- Support for serverless (on-demand) billing

✅ **Security & Encryption**
- Server-side encryption (AWS managed or KMS)
- Point-in-time recovery (PITR) enabled by default
- DynamoDB Streams for real-time data capture
- Data capture for ML model training

✅ **Backup & Disaster Recovery**
- AWS Backup integration
- Configurable backup schedules (daily, weekly, etc.)
- Backup retention policies
- Point-in-time recovery to any second

✅ **Multi-Region Deployment**
- Global tables for active-active replication
- Cross-region disaster recovery
- Automatic conflict resolution
- Eventually consistent reads across regions

✅ **Monitoring & Alarms**
- CloudWatch alarms for read/write throttling
- User error tracking
- DynamoDB Streams logging
- Comprehensive metrics

## Module Structure

```
modules/dynamodb/
├── main.tf          # DynamoDB table, indexes, scaling, and backup resources
├── variables.tf     # Input parameters with validation
├── outputs.tf       # Output values for integration
└── README.md        # This file
```

## Basic Usage

### Simple On-Demand Table

```hcl
module "users_table" {
  source = "./modules/dynamodb"

  table_name  = "users"
  hash_key    = "user_id"
  billing_mode = "PAY_PER_REQUEST"

  additional_attributes = [
    { name = "email", type = "S" }
  ]

  enable_point_in_time_recovery = true

  tags = {
    Application = "user-service"
    Environment = "production"
  }
}
```

### Provisioned Table with Auto-Scaling

```hcl
module "events_table" {
  source = "./modules/dynamodb"

  table_name      = "events"
  hash_key        = "event_id"
  range_key       = "timestamp"
  billing_mode    = "PROVISIONED"
  read_capacity   = 10
  write_capacity  = 10

  enable_autoscaling = true
  autoscaling_max_read_capacity  = 1000
  autoscaling_max_write_capacity = 1000
  autoscaling_target_utilization = 70

  enable_alarms  = true
  alarm_actions  = ["arn:aws:sns:us-east-1:123456789012:alarms"]

  enable_point_in_time_recovery = true
  enable_encryption = true

  tags = {
    Application = "event-stream"
    Environment = "production"
  }
}
```

### Table with Global Secondary Index

```hcl
module "orders_table" {
  source = "./modules/dynamodb"

  table_name  = "orders"
  hash_key    = "order_id"
  range_key   = "created_at"
  billing_mode = "PAY_PER_REQUEST"

  additional_attributes = [
    { name = "customer_id", type = "S" },
    { name = "status", type = "S" }
  ]

  # Query orders by customer_id
  global_secondary_indexes = [
    {
      name            = "customer-id-index"
      hash_key        = "customer_id"
      range_key       = "created_at"
      projection_type = "ALL"
    },
    {
      name            = "status-index"
      hash_key        = "status"
      range_key       = "created_at"
      projection_type = "KEYS_ONLY"
    }
  ]

  enable_streams = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = {
    Application = "order-system"
  }
}
```

### Table with DynamoDB Streams

```hcl
module "transactions_table" {
  source = "./modules/dynamodb"

  table_name  = "transactions"
  hash_key    = "transaction_id"
  billing_mode = "PAY_PER_REQUEST"

  enable_streams = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = {
    Application = "payment-service"
  }
}

# Use streams with Lambda
module "stream_processor_lambda" {
  source = "./modules/lambda"

  function_name = "transaction-stream-processor"
  handler       = "index.handler"
  runtime       = "python3.11"
  
  environment_variables = {
    STREAM_ARN = module.transactions_table.table_stream_arn
  }
}
```

### Table with TTL (Automatic Expiration)

```hcl
module "sessions_table" {
  source = "./modules/dynamodb"

  table_name           = "sessions"
  hash_key             = "session_id"
  billing_mode         = "PAY_PER_REQUEST"
  ttl_attribute_name   = "expiration_timestamp"

  tags = {
    Application = "web-sessions"
  }
}

# In your application
import time
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('sessions')

# Set expiration to 24 hours from now
expiration = int(time.time()) + 86400

table.put_item(Item={
    'session_id': 'sess-12345',
    'user_data': {...},
    'expiration_timestamp': expiration
})
```

### Table with Backup Vault

```hcl
module "critical_data_table" {
  source = "./modules/dynamodb"

  table_name = "critical-data"
  hash_key   = "data_id"
  billing_mode = "PAY_PER_REQUEST"

  enable_point_in_time_recovery = true

  # Enable backups
  enable_backup_vault = true
  backup_schedule     = "cron(0 5 ? * * *)"  # Daily at 5 AM UTC
  backup_retention_days = 90

  tags = {
    Application = "analytics"
    Compliance  = "soc2"
  }
}
```

### Global Table for Multi-Region

```hcl
module "global_catalog_table" {
  source = "./modules/dynamodb"

  table_name  = "product-catalog"
  hash_key    = "product_id"
  billing_mode = "PAY_PER_REQUEST"

  enable_global_table = true
  replica_regions = [
    "us-west-2",
    "eu-west-1",
    "ap-southeast-1"
  ]

  enable_point_in_time_recovery = true
  enable_streams = true

  tags = {
    Application = "catalog"
    GlobalReplication = "enabled"
  }
}
```

### Table with Encryption and PITR

```hcl
module "encrypted_table" {
  source = "./modules/dynamodb"

  table_name = "sensitive-data"
  hash_key   = "record_id"
  billing_mode = "PAY_PER_REQUEST"

  # Encryption with customer-managed key
  enable_encryption = true
  encryption_key_arn = aws_kms_key.dynamodb.arn

  # Recovery options
  enable_point_in_time_recovery = true

  tags = {
    Compliance = "hipaa"
    Encryption = "kms"
  }
}

resource "aws_kms_key" "dynamodb" {
  description = "KMS key for DynamoDB encryption"
  enable_key_rotation = true

  tags = {
    Application = "encrypted-data"
  }
}
```

## Input Variables

### Core Table Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `table_name` | string | - | DynamoDB table name (required) |
| `hash_key` | string | - | Partition key name (required) |
| `range_key` | string | null | Sort key name (optional) |
| `billing_mode` | string | "PAY_PER_REQUEST" | PROVISIONED or PAY_PER_REQUEST |

### Capacity Variables (PROVISIONED mode)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `read_capacity` | number | 5 | Read capacity units |
| `write_capacity` | number | 5 | Write capacity units |
| `enable_autoscaling` | bool | true | Enable auto-scaling |
| `autoscaling_max_read_capacity` | number | 40000 | Max read capacity |
| `autoscaling_max_write_capacity` | number | 40000 | Max write capacity |
| `autoscaling_target_utilization` | number | 70 | Target utilization % |

### Index Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `additional_attributes` | list(object) | [] | Additional attributes for indexes |
| `global_secondary_indexes` | list(object) | [] | Global secondary indexes |
| `local_secondary_indexes` | list(object) | [] | Local secondary indexes |

### Stream Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_streams` | bool | false | Enable DynamoDB Streams |
| `stream_view_type` | string | "NEW_AND_OLD_IMAGES" | KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, or NEW_AND_OLD_IMAGES |

### Security & Recovery Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_encryption` | bool | true | Enable server-side encryption |
| `encryption_key_arn` | string | null | KMS key ARN (uses AWS managed if null) |
| `enable_point_in_time_recovery` | bool | true | Enable PITR |
| `ttl_attribute_name` | string | null | Attribute name for TTL |

### Backup Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_backup_vault` | bool | false | Enable AWS Backup |
| `backup_schedule` | string | "cron(0 5 ? * * *)" | Backup schedule in cron format |
| `backup_retention_days` | number | 30 | Backup retention in days |

### Monitoring Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_alarms` | bool | true | Enable CloudWatch alarms |
| `alarm_actions` | list(string) | [] | SNS topic ARNs for alarms |

### Global Table Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_global_table` | bool | false | Enable multi-region replication |
| `replica_regions` | list(string) | [] | List of replica regions |

## Output Values

```hcl
output "table_arn"                        # Table ARN
output "table_name"                       # Table name
output "table_id"                         # Table ID
output "table_stream_arn"                 # Streams ARN (if enabled)
output "billing_mode"                     # Billing mode
output "read_capacity"                    # Read capacity units
output "write_capacity"                   # Write capacity units
output "global_secondary_indexes"         # GSI information
output "item_count"                       # Number of items
output "backup_vault_arn"                 # Backup vault ARN
output "global_table_arn"                 # Global table ARN
output "encryption_enabled"               # Encryption status
output "point_in_time_recovery_enabled"   # PITR status
output "autoscaling_enabled"              # Auto-scaling status
```

## Advanced Usage

### Processing DynamoDB Streams with Lambda

```hcl
# DynamoDB table with streams
module "data_table" {
  source = "./modules/dynamodb"

  table_name   = "data-events"
  hash_key     = "event_id"
  billing_mode = "PAY_PER_REQUEST"
  enable_streams = true
}

# Lambda to process stream records
module "stream_processor" {
  source = "./modules/lambda"

  function_name = "dynamodb-stream-processor"
  handler       = "processor.handler"
  runtime       = "python3.11"
  
  # Grant permission to read streams
  environment_variables = {
    TABLE_NAME = module.data_table.table_name
  }
}

# Connect stream to Lambda
resource "aws_lambda_event_source_mapping" "dynamodb_stream" {
  event_source_arn  = module.data_table.table_stream_arn
  function_name     = module.stream_processor.function_arn
  enabled           = true
  batch_size        = 100
  starting_position = "LATEST"
}
```

### Application Code with DynamoDB

```python
import boto3
from datetime import datetime, timedelta

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('users')

# Put item
table.put_item(Item={
    'user_id': 'user-123',
    'email': 'user@example.com',
    'created_at': datetime.utcnow().isoformat()
})

# Get item
response = table.get_item(Key={'user_id': 'user-123'})
user = response.get('Item')

# Query with GSI
response = table.query(
    IndexName='email-index',
    KeyConditionExpression='email = :email',
    ExpressionAttributeValues={':email': 'user@example.com'}
)

# Update item
table.update_item(
    Key={'user_id': 'user-123'},
    UpdateExpression='SET #status = :status',
    ExpressionAttributeNames={'#status': 'status'},
    ExpressionAttributeValues={':status': 'active'}
)
```

### Cost Estimation

**On-Demand Pricing** (PAY_PER_REQUEST)
- Reads: $1.25 per million read requests
- Writes: $6.25 per million write requests

**Provisioned Pricing** (Example: us-east-1)
- Read: $0.00013 per RCU-hour
- Write: $0.00065 per WCU-hour
- For 100 RCUs: ~$94/month

## Troubleshooting

### Throttling Errors

```bash
# Check current capacity
aws dynamodb describe-table --table-name my-table

# Monitor metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedReadCapacityUnits \
  --dimensions Name=TableName,Value=my-table \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 300 \
  --statistics Sum
```

### Streams Not Working

- Enable streams: `enable_streams = true`
- Verify stream type is set correctly
- Check Lambda event source mapping created
- Verify Lambda has permissions to read streams

### GSI Capacity Issues

- GSI has separate capacity from base table
- Configure auto-scaling separately for GSI
- Monitor GSI throttling with CloudWatch alarms

## Performance Best Practices

1. **Choose Suitable Hash Key** - Distribute evenly across partition keys
2. **Use GSI for Queries** - Don't query on attributes not in key
3. **Enable Auto-Scaling** - Adapt to changing workloads automatically
4. **Monitor Metrics** - Track consumed capacity and throttling
5. **Set TTL for Temporary Data** - Automatically expire old items
6. **Use Batch Operations** - BatchGetItem and BatchWriteItem for efficiency
7. **Enable Point-in-Time Recovery** - Protect against accidental deletion

## Related Modules

- **Lambda Module** - Processes DynamoDB Streams
- **IAM Module** - Controls DynamoDB access
- **S3 Module** - Archives DynamoDB backups

## Additional Resources

- [DynamoDB Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)
- [DynamoDB Performance](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.html)
- [DynamoDB Streams](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Streams.html)
- [Global Tables](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GlobalTables.html)
