# AWS Glue Job Module

Terraform module for deploying AWS Glue ETL and Python Shell jobs with IAM roles, CloudWatch logging, monitoring alarms, and scheduling.

## Features

✅ **Job Deployment**
- Glue ETL and Python Shell job types
- Configurable worker type and count
- Glue version selection (2.0, 3.0, 4.0)
- Concurrent run limits and retry configuration

✅ **Security & Access Control**
- Dedicated IAM execution role with least-privilege
- Configurable S3 access ARNs
- Custom IAM policies via `custom_policies` parameter
- Glue connection support for VPC/JDBC resources

✅ **Monitoring & Logging**
- CloudWatch Logs with configurable retention
- Continuous CloudWatch logging enabled by default
- CloudWatch metric alarms for failures and duration

✅ **Scheduling**
- Glue Trigger-based scheduling with cron expressions
- Configurable schedule arguments

## Module Structure

```
glue/
├── main.tf           # Core Glue resources, IAM, and monitoring
├── variables.tf      # Input parameters with validation
├── outputs.tf        # Output values
└── README.md         # This file
```

## Usage

### Basic ETL Job

```hcl
module "glue_etl" {
  source = "./modules/glue"

  job_name        = "biti-crypto-etl"
  script_location = "s3://my-scripts-bucket/glue/etl_job.py"
  worker_type     = "G.1X"
  number_of_workers = 2

  s3_access_arns = [
    "arn:aws:s3:::my-data-bucket",
    "arn:aws:s3:::my-data-bucket/*",
    "arn:aws:s3:::my-scripts-bucket",
    "arn:aws:s3:::my-scripts-bucket/*"
  ]

  tags = {
    Environment = "production"
    Project     = "biti"
  }
}
```

### Python Shell Job

```hcl
module "glue_python" {
  source = "./modules/glue"

  job_name        = "biti-data-cleanup"
  script_location = "s3://my-scripts-bucket/glue/cleanup.py"
  job_type        = "pythonshell"
  max_capacity    = 0.0625

  s3_access_arns = [
    "arn:aws:s3:::my-data-bucket",
    "arn:aws:s3:::my-data-bucket/*"
  ]

  tags = { Environment = "production" }
}
```

### Scheduled Job with Monitoring

```hcl
module "glue_scheduled" {
  source = "./modules/glue"

  job_name            = "biti-nightly-forecast"
  script_location     = "s3://my-scripts-bucket/glue/forecast.py"
  worker_type         = "G.2X"
  number_of_workers   = 5
  timeout             = 120
  schedule_expression = "cron(0 2 * * ? *)"

  s3_access_arns = [
    "arn:aws:s3:::my-data-bucket",
    "arn:aws:s3:::my-data-bucket/*"
  ]

  create_failure_alarm  = true
  create_duration_alarm = true
  duration_threshold    = 7200000
  alarm_actions         = [aws_sns_topic.alerts.arn]

  tags = { Environment = "production" }
}
```

### With Custom IAM Policies

```hcl
module "glue_with_policies" {
  source = "./modules/glue"

  job_name        = "biti-data-processor"
  script_location = "s3://my-scripts-bucket/glue/processor.py"

  s3_access_arns = [
    "arn:aws:s3:::my-data-bucket",
    "arn:aws:s3:::my-data-bucket/*"
  ]

  custom_policies = {
    dynamodb_access = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["dynamodb:Query", "dynamodb:PutItem", "dynamodb:BatchWriteItem"]
        Effect   = "Allow"
        Resource = "arn:aws:dynamodb:us-east-1:123456789:table/crypto-prices"
      }]
    })
  }

  tags = { Environment = "production" }
}
```

## Input Variables

### Required

| Name | Type | Description |
|------|------|-------------|
| `job_name` | string | Name of the Glue job (1-255 chars) |
| `script_location` | string | S3 path to the job script |
| `s3_access_arns` | list(string) | S3 ARNs the job needs access to |

### Optional - Job Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `job_type` | string | "glueetl" | glueetl or pythonshell |
| `glue_version` | string | "4.0" | Glue version (2.0, 3.0, 4.0) |
| `python_version` | string | "3" | Python version (3 or 3.9) |
| `worker_type` | string | "G.1X" | Worker type for ETL jobs |
| `number_of_workers` | number | 2 | Number of workers (2-299) |
| `max_capacity` | number | 0.0625 | Max DPU for Python Shell |
| `timeout` | number | 60 | Timeout in minutes (1-2880) |
| `max_retries` | number | 0 | Max retries (0-10) |
| `max_concurrent_runs` | number | null | Max concurrent runs |
| `default_arguments` | map(string) | {} | Additional job arguments |
| `connections` | list(string) | [] | Glue connection names |

### Optional - Scheduling

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `schedule_expression` | string | null | Cron expression for trigger |
| `schedule_enabled` | bool | true | Whether schedule is enabled |
| `schedule_arguments` | map(string) | {} | Arguments for scheduled runs |

### Optional - Monitoring

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `log_retention_days` | number | 14 | CloudWatch log retention |
| `create_failure_alarm` | bool | true | Create failure alarm |
| `failure_threshold` | number | 1 | Failure threshold |
| `create_duration_alarm` | bool | false | Create duration alarm |
| `duration_threshold` | number | 3600000 | Duration threshold (ms) |
| `alarm_actions` | list(string) | [] | SNS topic ARNs for alarms |

### Optional - Security

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `custom_policies` | map(string) | null | Map of custom IAM policies |
| `tags` | map(string) | {} | Resource tags |

## Outputs

| Name | Description |
|------|-------------|
| `job_name` | Name of the Glue job |
| `job_arn` | ARN of the Glue job |
| `role_arn` | ARN of the execution role |
| `role_name` | Name of the execution role |
| `log_group_name` | CloudWatch log group name |
| `log_group_arn` | CloudWatch log group ARN |
| `schedule_trigger_name` | Schedule trigger name (if scheduled) |
| `failure_alarm_arn` | Failure alarm ARN (if enabled) |
| `duration_alarm_arn` | Duration alarm ARN (if enabled) |

## References

- [AWS Glue Documentation](https://docs.aws.amazon.com/glue/)
- [Glue Job Properties](https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-jobs-job.html)
- [Glue Pricing](https://aws.amazon.com/glue/pricing/)

---

**Module Version**: 1.0.0
**Last Updated**: 2025
