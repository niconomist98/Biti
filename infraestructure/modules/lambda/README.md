# AWS Lambda Module

Comprehensive Terraform module for deploying serverless Lambda functions with complete monitoring, logging, security, and orchestration.

## Features

✅ **Function Deployment**
- Support for multiple runtimes (Python, Node.js, Java, Go, Ruby, .NET)
- ARM64 (AWS Graviton) and x86_64 architectures
- Zip file packaging and versioning
- Reserved concurrent executions
- Ephemeral storage configuration

✅ **Security & Access Control**
- Dedicated IAM execution role with least-privilege
- VPC integration for private network access
- Custom IAM policies via `custom_policies` parameter
- X-Ray tracing support
- Secrets Manager integration examples

✅ **Monitoring & Logging**
- CloudWatch Logs with configurable retention
- JSON or Text log format
- Lambda Insights integration
- CloudWatch metric alarms for:
  - Errors
  - Throttles
  - High duration
  - Composite health check

✅ **Deployment Patterns**
- Lambda aliases for blue-green deployments
- Function URLs for public HTTP endpoints
- CORS configuration support
- Automatic ZIP packaging

✅ **Orchestration**
- EventBridge scheduled invocations
- Support for external triggers via custom policies
- Lambda layers for shared dependencies

✅ **Extensibility**
- Lambda layers for code reuse
- Custom environment variables
- S3, DynamoDB, SNS, SQS, Secrets Manager examples

## Module Structure

```
lambda/
├── main.tf           # Core Lambda resources and orchestration
├── iam.tf            # IAM roles, policies, and examples
├── variables.tf      # Input parameters with validation
├── outputs.tf        # Output values
└── README.md         # This file
```

## Usage

### Basic Example

```hcl
module "lambda_function" {
  source = "./modules/lambda"

  function_name = "my-function"
  source_dir    = "${path.module}/src/lambda"
  runtime       = "python3.11"
  handler       = "index.handler"

  environment_variables = {
    TABLE_NAME = "my-table"
    LOG_LEVEL  = "INFO"
  }

  tags = {
    Environment = "production"
    Owner       = "platform-team"
  }
}
```

### With VPC Access

```hcl
module "lambda_vpc" {
  source = "./modules/lambda"

  function_name = "vpc-lambda"
  source_dir    = "${path.module}/src/lambda"
  runtime       = "python3.11"

  vpc_config = {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.lambda.id]
  }

  timeout      = 120
  memory_size  = 512
}
```

### With Scheduled Invocation

```hcl
module "scheduled_lambda" {
  source = "./modules/lambda"

  function_name = "scheduled-job"
  source_dir    = "${path.module}/src/lambda"
  runtime       = "python3.11"

  schedule_expression = "cron(0 2 * * ? *)"  # 2 AM UTC daily
  schedule_input      = jsonencode({
    task = "data_import"
    env  = "production"
  })

  create_error_alarm = true
  error_threshold    = 3
}
```

### With Public HTTP Endpoint

```hcl
module "api_lambda" {
  source = "./modules/lambda"

  function_name = "public-api"
  source_dir    = "${path.module}/src/lambda"
  runtime       = "nodejs20.x"

  enable_function_url    = true
  function_url_auth_type = "NONE"  # Public

  cors_allow_origins = ["https://example.com"]
  cors_allow_methods = ["GET", "POST", "OPTIONS"]
}
```

### With Custom Policies

```hcl
module "lambda_with_policies" {
  source = "./modules/lambda"

  function_name = "data-processor"
  source_dir    = "${path.module}/src/lambda"
  runtime       = "python3.11"

  custom_policies = {
    s3_access = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["s3:GetObject", "s3:PutObject"]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::data-bucket/*"
      }]
    })
    dynamodb_access = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["dynamodb:Query", "dynamodb:PutItem"]
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:us-east-1:123456789:table/events"
      }]
    })
  }
}
```

### With Lambda Alias (Blue-Green Deployment)

```hcl
module "lambda_with_alias" {
  source = "./modules/lambda"

  function_name  = "versioned-function"
  source_dir     = "${path.module}/src/lambda"
  runtime        = "python3.11"

  enable_alias = true
  alias_name   = "live"
}

# Point API Gateway to the alias
resource "aws_api_gateway_integration" "lambda" {
  uri = module.lambda_with_alias.alias_arn
}
```

### With GPU/ARM64 Support

```hcl
module "arm_lambda" {
  source = "./modules/lambda"

  function_name = "arm-optimized"
  source_dir    = "${path.module}/src/lambda"
  runtime       = "python3.11"

  architectures = ["arm64"]  # AWS Graviton processors
  memory_size   = 1024
}
```

### With Monitoring Alerts

```hcl
module "monitored_lambda" {
  source = "./modules/lambda"

  function_name = "critical-function"
  source_dir    = "${path.module}/src/lambda"
  runtime       = "python3.11"

  create_error_alarm    = true
  error_threshold       = 5
  create_throttle_alarm = true
  throttle_threshold    = 1
  create_duration_alarm = true
  duration_threshold    = 60000  # 60 seconds

  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

## Input Variables

### Required

| Name | Type | Description |
|------|------|-------------|
| `function_name` | string | Name of the Lambda function (1-64 chars) |
| `source_dir` | string | Path to source code directory to zip |
| `handler` | string | Handler in format: filename.function |
| `runtime` | string | Lambda runtime (e.g., python3.11) |

### Optional - Function Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `timeout` | number | 60 | Function timeout in seconds (1-900) |
| `memory_size` | number | 256 | Memory in MB (128-10240) |
| `publish` | bool | true | Publish version after update |
| `architectures` | list(string) | ["x86_64"] | x86_64 or arm64 |
| `environment_variables` | map(string) | {} | Environment variables |
| `reserved_concurrent_executions` | number | -1 | Reserved concurrency (-1 = unlimited) |
| `ephemeral_storage_size` | number | null | Ephemeral storage in MB (512-10240) |

### Optional - Networking

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `vpc_config` | object | null | VPC configuration (subnet/SG IDs) |

### Optional - Logging

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `log_retention_days` | number | 14 | CloudWatch log retention |
| `log_format` | string | "Text" | Log format (Text or JSON) |

### Optional - Orchestration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `schedule_expression` | string | null | EventBridge cron expression |
| `schedule_input` | string | null | JSON input for scheduled runs |
| `layers` | list(string) | null | Lambda layer ARNs |

### Optional - Deployment

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `enable_alias` | bool | false | Enable Lambda alias |
| `alias_name` | string | "live" | Alias name |
| `enable_function_url` | bool | false | Enable public HTTP endpoint |
| `function_url_auth_type` | string | "AWS_IAM" | AWS_IAM or NONE |

### Optional - CORS (when using Function URL)

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `cors_allow_origins` | list(string) | ["*"] | CORS allowed origins |
| `cors_allow_methods` | list(string) | ["GET", "POST"] | CORS allowed methods |
| `cors_allow_headers` | list(string) | ["x-custom-header"] | CORS allowed headers |
| `cors_expose_headers` | list(string) | ["x-custom-header"] | CORS expose headers |
| `cors_allow_credentials` | bool | false | Allow credentials in CORS |
| `cors_max_age` | number | 86400 | CORS preflight cache in seconds |

### Optional - Monitoring & Alarms

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `create_error_alarm` | bool | true | Create error CloudWatch alarm |
| `error_threshold` | number | 5 | Error threshold for alarm |
| `create_throttle_alarm` | bool | true | Create throttle alarm |
| `throttle_threshold` | number | 1 | Throttle threshold |
| `create_duration_alarm` | bool | true | Create duration alarm |
| `duration_threshold` | number | 30000 | Duration threshold (ms) |
| `create_composite_alarm` | bool | true | Create composite health alarm |
| `alarm_actions` | list(string) | [] | SNS topic ARNs for alarms |

### Optional - Advanced

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `enable_xray_tracing` | bool | false | Enable X-Ray tracing |
| `enable_insights` | bool | false | Enable Lambda Insights |
| `custom_policies` | map(string) | null | Map of custom IAM policies |
| `tags` | map(string) | {} | Resource tags |

## Outputs

| Name | Description |
|------|-------------|
| `function_arn` | ARN of the Lambda function |
| `function_name` | Name of the Lambda function |
| `function_invoke_arn` | Invoke ARN for use in triggers |
| `function_version` | Latest version of the function |
| `function_last_modified` | Last modified timestamp |
| `function_code_size` | Size of the function code in bytes |
| `role_arn` | ARN of the execution role |
| `role_name` | Name of the execution role |
| `log_group_name` | CloudWatch log group name |
| `log_group_arn` | CloudWatch log group ARN |
| `alias_name` | Lambda alias name (if enabled) |
| `alias_arn` | Lambda alias ARN (if enabled) |
| `function_url` | Public function URL (if enabled) |
| `error_alarm_arn` | Error alarm ARN (if enabled) |
| `throttle_alarm_arn` | Throttle alarm ARN (if enabled) |
| `duration_alarm_arn` | Duration alarm ARN (if enabled) |
| `composite_alarm_arn` | Composite health alarm ARN |
| `schedule_rule_arn` | EventBridge schedule rule ARN (if scheduled) |

## Common Patterns

### Pattern 1: Data Processing Pipeline

```hcl
# Lambda triggered by S3 events
module "s3_processor" {
  source = "./modules/lambda"

  function_name = "s3-event-processor"
  source_dir    = "${path.module}/src/processors"
  runtime       = "python3.11"
  timeout       = 300  # Long-running
  memory_size   = 2048

  custom_policies = {
    s3_read = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::input-bucket/*"
      }]
    })
  }
}

resource "aws_s3_bucket_notification" "events" {
  bucket = aws_s3_bucket.input.id

  lambda_function {
    lambda_function_arn = module.s3_processor.function_arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_lambda_permission" "s3_invoke" {
  function_name = module.s3_processor.function_name
  action        = "lambda:InvokeFunction"
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.input.arn
}
```

### Pattern 2: API Backend

```hcl
module "api_lambda" {
  source = "./modules/lambda"

  function_name         = "api-handler"
  source_dir            = "${path.module}/src/api"
  runtime               = "nodejs20.x"
  enable_function_url   = true
  function_url_auth_type = "NONE"

  cors_allow_origins = ["https://*.example.com"]
  cors_allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]

  alarm_actions = [aws_sns_topic.api_alerts.arn]
}

resource "aws_cloudwatch_log_group" "api_access" {
  name              = "/api/${module.api_lambda.function_name}"
  retention_in_days = 30
}
```

### Pattern 3: Batch Job with Monitoring

```hcl
module "batch_job" {
  source = "./modules/lambda"

  function_name       = "nightly-batch"
  source_dir          = "${path.module}/src/batch"
  runtime             = "python3.11"
  schedule_expression = "cron(0 3 * * ? *)"  # 3 AM UTC daily

  timeout     = 900  # 15 minutes
  memory_size = 3008  # Maximum for Python

  create_error_alarm    = true
  error_threshold       = 1
  create_duration_alarm = true
  duration_threshold    = 800000  # 800 seconds

  alarm_actions = [aws_sns_topic.ops_team.arn]
}
```

### Pattern 4: Microservice with VPC Access

```hcl
module "microservice" {
  source = "./modules/lambda"

  function_name = "order-service"
  source_dir    = "${path.module}/src/services/order"
  runtime       = "python3.11"

  vpc_config = {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.lambda_rds.id]
  }

  environment_variables = {
    DATABASE_HOST = aws_db_instance.main.endpoint
    API_KEY_SECRET = aws_secretsmanager_secret.api_key.arn
  }

  custom_policies = {
    secrets_access = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["secretsmanager:GetSecretValue"]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.api_key.arn
      }]
    })
  }
}
```

## Cost Estimation

### Pricing Components

1. **Compute**: $0.0000002 per GB-second
   - 128 MB for 1 second = $0.0000000128
   - 3008 MB for 60 seconds = $0.00000003

2. **Requests**: $0.20 per million requests

3. **Storage**: 
   - Function storage: Free for first 512 MB
   - CloudWatch Logs: $0.50 per GB ingested

### Example Monthly Costs

| Scenario | Invocations | Compute GB-s | Monthly |
|----------|-------------|--------------|---------|
| Light API (web hook) | 100K | 50 | $12 |
| Medium batch job | 750K | 3,600 | $160 |
| Heavy processing | 2M | 14,400 | $600+ |

**Note**: First 1M requests per month are free. First 400K GB-seconds are free.

## Best Practices

### 1. Memory & Performance
- Monitor Duration metric to find optimal memory
- Higher memory = faster CPU = lower duration = potential cost savings
- ARM64 can be 19% cheaper than x86_64

### 2. Security
- Always use VPC for database access
- Store secrets in Secrets Manager, not environment variables
- Use least-privilege IAM policies
- Enable X-Ray tracing for debugging

### 3. Monitoring
- Enable error alarms immediately
- Set throttle alarms for capacity planning
- Capture logs for at least 7 days
- Use composite alarms for critical functions

### 4. Deployment
- Use aliases for safe deployments
- Test with lower reserved concurrency first
- Implement gradual rollouts
- Monitor cold start times with ARM64

### 5. Scaling
- Set reserved concurrency for predictable load
- Enable auto-scaling for batch jobs
- Use SQS for distributed load balancing
- Monitor concurrent execution limits

## Troubleshooting

### High Duration
- Check memory allocation (CPU scales with memory)
- Monitor VPC cold starts (ENI attachment)
- Profile function code for bottlenecks

### Throttling
- Increase reserved concurrency
- Implement exponential backoff in clients
- Use SQS to buffer requests

### Cold Starts
- Use provisioned concurrency
- Optimize function size (remove unused dependencies)
- Consider ARM64 architecture
- Use Lambda@Edge for APIs

### VPC Performance Issues
- Increase ENI count in configuration
- Use fewer subnets
- Consider NAT gateway placement

## Security Considerations

✅ **Enabled by Default**
- CloudWatch Logs encryption at rest
- IAM role with least-privilege access
- VPC security groups (when configured)

⚠️ **Requires Configuration**
- Secrets Manager for sensitive data
- VPC for database access
- X-Ray for request tracing
- Custom policies for AWS service access

❌ **Not Recommended**
- Storing secrets in environment variables
- Public functions without authorization
- Wide-open IAM permissions
- Disabling CloudWatch Logs

## Related Modules

- **S3 Module**: For input/output bucket storage
- **DynamoDB Module**: For state management
- **API Gateway Module**: For REST API frontend
- **EventBridge Module**: For advanced orchestration
- **SQS/SNS Module**: For async messaging

## References

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [Lambda Pricing](https://aws.amazon.com/lambda/pricing/)
- [Lambda Limits](https://docs.aws.amazon.com/lambda/latest/dg/limits.html)

---

**Module Version**: 1.0.0  
**Last Updated**: 2026
