# AWS S3 Module

Comprehensive Terraform module for deploying S3 buckets with complete security, configuration, lifecycle management, replication, logging, and monitoring.

## Features

✅ **Bucket Management**
- Custom bucket naming with validation
- Versioning and MFA delete protection
- Server-side encryption (AES256 or KMS)
- Public access blocking
- ACL configuration

✅ **Security**
- Block public access by default
- Encryption at rest (AES256 or KMS)
- Bucket policies and IAM integration
- Access logging to separate bucket
- CloudFront Origin Access Control

✅ **Operational**
- Lifecycle rules (transition to cheaper storage, expiration)
- Cross-region replication
- Website hosting capability
- CORS configuration
- Request metrics

✅ **Monitoring & Compliance**
- CloudWatch alarms for size and object count
- Access logging with separate log bucket
- Versioning for data protection
- Lifecycle management for cost optimization
- Replication for disaster recovery

## Module Structure

```
s3/
├── main.tf           # Core S3 resources and configuration
├── variables.tf      # Input parameters with validation
├── outputs.tf        # Output values
└── README.md         # This file
```

## Usage

### Basic Example - Private Secure Bucket

```hcl
module "data_bucket" {
  source = "./modules/s3"

  bucket_name = "my-app-data-${data.aws_caller_identity.current.account_id}"

  enable_versioning = true
  block_public_access = true

  tags = {
    Environment = "production"
    Owner       = "data-team"
  }
}
```

### Data Lake with Lifecycle Management

```hcl
module "data_lake" {
  source = "./modules/s3"

  bucket_name = "my-data-lake-${data.aws_caller_identity.current.account_id}"

  enable_versioning    = true
  block_public_access  = true
  encryption_algorithm = "AES256"

  lifecycle_rules = [
    {
      id     = "archive_old_data"
      status = "Enabled"
      prefix = "archive/"

      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        },
        {
          days          = 365
          storage_class = "DEEP_ARCHIVE"
        }
      ]

      expiration_days = 2555  # 7 years
    },
    {
      id     = "delete_logs"
      status = "Enabled"
      prefix = "logs/"

      transitions = [
        {
          days          = 7
          storage_class = "GLACIER"
        }
      ]

      expiration_days = 90
    }
  ]

  tags = {
    Environment = "production"
    Purpose     = "data-lake"
  }
}
```

### Static Website Hosting

```hcl
module "website_bucket" {
  source = "./modules/s3"

  bucket_name = "example-com-website"

  enable_website  = true
  index_document  = "index.html"
  error_document  = "404.html"

  cors_rules = [
    {
      allowed_methods = ["GET"]
      allowed_origins = ["https://example.com"]
    }
  ]

  enable_cloudfront_access = true

  tags = {
    Environment = "production"
    Purpose     = "website"
  }
}
```

### With Cross-Region Replication

```hcl
module "main_bucket" {
  source = "./modules/s3"

  bucket_name = "app-data-us-east-1"

  enable_versioning = true
  block_public_access = true

  replication_config = {
    destination_bucket = "app-data-us-west-2"
    rules = [
      {
        id         = "replicate_all"
        status     = "Enabled"
        prefix     = ""
        storage_class = "STANDARD"
        replication_time_minutes = 15
      }
    ]
  }

  tags = {
    Environment = "production"
    Purpose     = "primary-data"
  }
}

module "replica_bucket" {
  source = "./modules/s3"
  providers = {
    aws = aws.us-west-2
  }

  bucket_name = "app-data-us-west-2"

  enable_versioning = true
  block_public_access = true

  tags = {
    Environment = "production"
    Purpose     = "replica-data"
  }
}
```

### KMS Encrypted Bucket with Logging

```hcl
module "secure_bucket" {
  source = "./modules/s3"

  bucket_name = "secure-data-${data.aws_caller_identity.current.account_id}"

  enable_versioning        = true
  block_public_access      = true
  encryption_algorithm     = "aws:kms"
  kms_key_id              = aws_kms_key.s3.id

  enable_logging       = true
  logging_prefix       = "logs/"

  tags = {
    Environment = "production"
    Encryption  = "kms"
  }
}
```

### Model Artifacts Bucket (for SageMaker)

```hcl
module "model_artifacts" {
  source = "./modules/s3"

  bucket_name = "sagemaker-models-${data.aws_caller_identity.current.account_id}"

  enable_versioning = true
  block_public_access = true

  lifecycle_rules = [
    {
      id     = "archive_old_models"
      status = "Enabled"
      prefix = "archive/"

      transitions = [
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]

      expiration_days = 365
    },
    {
      id     = "delete_temp_files"
      status = "Enabled"
      prefix = "temp/"

      expiration_days = 7
    }
  ]

  enable_logging = true

  tags = {
    Environment = "production"
    Service     = "sagemaker"
  }
}
```

### Application Logs Bucket with Monitoring

```hcl
module "logs_bucket" {
  source = "./modules/s3"

  bucket_name = "app-logs-${data.aws_caller_identity.current.account_id}"

  block_public_access = true

  lifecycle_rules = [
    {
      id     = "archive_old_logs"
      status = "Enabled"

      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]

      expiration_days = 365
    }
  ]

  create_size_alarm = true
  size_threshold    = 1099511627776  # 1 TB
  alarm_actions     = [aws_sns_topic.alerts.arn]

  tags = {
    Environment = "production"
    Purpose     = "logs"
  }
}
```

## Input Variables

### Required

| Name | Type | Description |
|------|------|-------------|
| `bucket_name` | string | S3 bucket name (3-63 chars, globally unique) |

### Optional - Basic Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `acl` | string | null | Canned ACL (private, public-read, etc.) |
| `block_public_access` | bool | true | Block all public access |

### Optional - Versioning & Deletion

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `enable_versioning` | bool | true | Enable bucket versioning |
| `enable_mfa_delete` | bool | false | Require MFA for deletion |

### Optional - Encryption

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `encryption_algorithm` | string | AES256 | AES256 or aws:kms |
| `kms_key_id` | string | null | KMS key ID (required if kms) |

### Optional - Logging

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `enable_logging` | bool | true | Enable access logging |
| `logging_bucket` | string | null | Bucket for logs (creates one if null) |
| `logging_prefix` | string | logs/ | Prefix for log files |

### Optional - Website

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `enable_website` | bool | false | Enable website hosting |
| `index_document` | string | index.html | Index file |
| `error_document` | string | null | Error document |
| `routing_rules` | list(object) | null | URL routing rules |

### Optional - CORS

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `cors_rules` | list(object) | null | CORS configuration |

### Optional - Lifecycle & Replication

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `lifecycle_rules` | list(object) | null | Lifecycle management rules |
| `replication_config` | object | null | Cross-region replication |

### Optional - Monitoring & Policy

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `enable_metrics` | bool | false | Enable request metrics |
| `enable_cloudfront_access` | bool | false | Enable CloudFront access |
| `bucket_policy` | string | null | Custom bucket policy |
| `create_size_alarm` | bool | false | Alarm for bucket size |
| `size_threshold` | number | 100GB | Size threshold for alarm |
| `create_count_alarm` | bool | false | Alarm for object count |
| `object_count_threshold` | number | 1000000 | Object count threshold |
| `alarm_actions` | list(string) | [] | SNS topics for alarms |

### Optional - Tags

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `tags` | map(string) | {} | Resource tags |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_id` | S3 bucket ID |
| `bucket_arn` | S3 bucket ARN |
| `bucket_domain_name` | Bucket domain name |
| `bucket_regional_domain_name` | Regional domain name |
| `bucket_region` | AWS region |
| `bucket_versioning_enabled` | Versioning status |
| `bucket_encryption_algorithm` | Encryption algorithm used |
| `bucket_logging_enabled` | Logging status |
| `bucket_website_endpoint` | Website endpoint URL |
| `bucket_website_domain` | Website domain |
| `bucket_policy_applied` | Policy status |
| `access_logs_bucket` | Logs bucket name |
| `cloudfront_oac_id` | CloudFront OAC ID |
| `cloudfront_oac_arn` | CloudFront OAC ARN |
| `replication_enabled` | Replication status |
| `replication_role_arn` | Replication IAM role ARN |
| `metrics_enabled` | Metrics status |
| `size_alarm_arn` | Size alarm ARN |
| `count_alarm_arn` | Count alarm ARN |
| `public_access_blocked` | Public access block status |
| `bucket_cors_configured` | CORS configuration status |
| `lifecycle_rules_count` | Number of lifecycle rules |

## Common Use Cases

### Use Case 1: Application Data Storage

```hcl
module "app_data" {
  source = "./modules/s3"

  bucket_name = "app-data-prod"

  enable_versioning = true
  block_public_access = true

  lifecycle_rules = [
    {
      id = "old_versions"
      noncurrent_expiration_days = 90
    }
  ]

  enable_logging = true

  tags = {
    Environment = "production"
    Type        = "application-data"
  }
}
```

### Use Case 2: Backup Storage

```hcl
module "backup_storage" {
  source = "./modules/s3"

  bucket_name = "backups-prod"

  enable_versioning = true

  lifecycle_rules = [
    {
      id = "backup_retention"
      
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]

      expiration_days = 2555  # 7 years
    }
  ]
}
```

### Use Case 3: CloudFront Content

```hcl
module "cdn_content" {
  source = "./modules/s3"

  bucket_name = "cdn-content"

  block_public_access = true
  enable_cloudfront_access = true

  cors_rules = [
    {
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["*"]
      max_age_seconds = 86400
    }
  ]
}

resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name              = module.cdn_content.bucket_regional_domain_name
    origin_access_control_id = module.cdn_content.cloudfront_oac_id

    origin_id = "myS3Origin"
  }

  enabled = true
  
  # ... additional CloudFront configuration
}
```

## Storage Classes & Costs

| Class | Access Speed | Cost | Use Case |
|-------|-------------|------|----------|
| STANDARD | Immediate | High | Frequently accessed data |
| STANDARD_IA | Immediate | Low | Infrequent access |
| INTELLIGENT_TIERING | Automatic | Variable | Unknown access patterns |
| GLACIER | Hours | Very Low | Archive/long-term retention |
| DEEP_ARCHIVE | 12+ hours | Lowest | Compliance/legal hold |

### Lifecycle Recommendations

- **Hot data**: Keep in STANDARD
- **Warm data** (30+ days old): Move to STANDARD_IA
- **Cold data** (90+ days old): Move to GLACIER
- **Archive** (1+ year old): Move to DEEP_ARCHIVE
- **Expired**: Delete after retention period

## Cost Optimization

### 1. Use Lifecycle Rules
- Automatically transition data to cheaper storage
- Delete old logs and temporary files
- Typical savings: 60-80% on historical data

### 2. Enable S3 Intelligent-Tiering
- Automatic optimization based on access patterns
- Small monthly monitoring fee ($0.0125/1000 objects)

### 3. Use Requester Pays
- Shift storage costs to data consumers
- Use for large public datasets

### 4. Disable Unnecessary Versioning
- Enable only for critical buckets
- Versioning doubles storage costs

### 5. Set Object Expiration
- Delete logs and temp files automatically
- Reduces storage footprint over time

## Best Practices

### 1. Security
✅ Block all public access by default  
✅ Enable versioning for data protection  
✅ Use KMS encryption for sensitive data  
✅ Enable access logging for audit trail  
✅ Use bucket policies for fine-grained access  

### 2. Organization
✅ Use meaningful bucket names  
✅ Enable tagging for cost allocation  
✅ Use prefixes for logical organization  
✅ Document bucket purpose in tags  

### 3. Performance
✅ Use CloudFront CDN for content distribution  
✅ Enable request metrics for monitoring  
✅ Use multi-part uploads for large files  
✅ Consider S3 Transfer Acceleration  

### 4. Compliance
✅ Enable versioning  
✅ Set appropriate retention policies  
✅ Enable logging for audit trail  
✅ Use MFA delete for critical data  

### 5. Cost Management
✅ Use lifecycle rules aggressively  
✅ Monitor bucket size and object count  
✅ Set up CloudWatch alarms  
✅ Review storage class distribution  

## Troubleshooting

### Bucket Creation Fails
- Bucket name already exists globally
- Name violates S3 naming rules
- Account has reached bucket limit (100 default)

### Replication Not Working
- Source bucket versioning not enabled
- IAM role lacks permissions
- Destination bucket not accessible
- Check replication status in management console

### Lifecycle Rules Not Applied
- Rules status must be "Enabled"
- Check prefix filters
- Verify storage class transitions

### Website Not Accessible
- Check bucket policy and block public access
- Verify index document name
- Ensure CORS configured if needed
- Check CloudFront if using CDN

## Security Considerations

✅ **Enabled by Default**
- AES256 encryption at rest
- Block public access
- IMDSv2 for EC2 access
- Bucket versioning (optional)

⚠️ **Requires Configuration**
- KMS encryption
- Cross-region replication
- Bucket policies
- Access logging
- CloudFront access

❌ **Not Recommended**
- Public bucket without clear purpose
- Disabling block public access
- Storing secrets in plain text
- No lifecycle management
- No versioning on critical data

## Estimated Monthly Costs

| Scenario | Storage | Transfer | Cost |
|----------|---------|----------|------|
| Small app (10 GB, STANDARD) | $0.23 | $0 | $0.23 |
| Medium logs (500 GB, IA after 30d) | $7.50 | $0 | $7.50 |
| Large archive (5 TB, Glacier) | $2.56 | $0 | $2.56 |
| CDN distribution (100 GB out) | $2.30 | $8.50 | $10.80 |

## Related Modules

- **Lambda Module**: For processing S3 events
- **EC2 Module**: For compute access to S3
- **CloudFront Module**: For CDN distribution
- **RDS Module**: For database backups to S3
- **DynamoDB Module**: For DynamoDB backups

## References

- [S3 Documentation](https://docs.aws.amazon.com/s3/)
- [S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/BestPractices.html)
- [S3 Pricing](https://aws.amazon.com/s3/pricing/)
- [S3 Storage Classes](https://aws.amazon.com/s3/storage-classes/)

---

**Module Version**: 1.0.0  
**Last Updated**: 2026
