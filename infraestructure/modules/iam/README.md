# AWS IAM Module

Comprehensive Terraform module for managing AWS IAM roles, policies, and access control with support for AssumeRole policies, inline and managed policies, permission boundaries, and CloudTrail auditing.

## Features

✅ **Role Management**
- Create IAM roles with custom or service principal trust policies
- Support for Assume Role conditions (MFA, IP restrictions, etc.)
- Configurable max session duration

✅ **Policy Management**
- Attach AWS managed policies
- Define inline policies directly
- Create custom managed policies
- Permission boundary support (policy delegation guardrails)

✅ **Instance Profiles**
- Create EC2 instance profiles linked to roles
- Direct IAM role assumption from EC2 instances

✅ **Attribute-Based Access Control (ABAC)**
- Session tags for ABAC implementations
- Cost allocation and resource management

✅ **Auditing & Logging**
- CloudWatch logging for IAM access
- CloudTrail integration for detailed audit trails
- S3 storage for long-term audit logs

✅ **Security Best Practices**
- Least privilege principle built-in
- Permission boundaries for delegation
- MFA and IP-based conditions supported
- Session duration validation

## Module Structure

```
modules/iam/
├── main.tf          # IAM role, policies, and CloudTrail resources
├── variables.tf     # Input parameters with validation
├── outputs.tf       # Output values for integration
└── README.md        # This file
```

## Basic Usage

### Simple Role for EC2

```hcl
module "ec2_role" {
  source = "./modules/iam"

  role_name       = "ec2-application-role"
  trust_entity_type = "Service"
  trust_entity_identifiers = ["ec2.amazonaws.com"]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  create_instance_profile = true

  tags = {
    Environment = "production"
    Application = "web-server"
  }
}
```

### Role with S3 Permissions

```hcl
module "s3_access_role" {
  source = "./modules/iam"

  role_name           = "s3-data-processing-role"
  role_description    = "Role for Lambda to process S3 data"
  trust_entity_type   = "Service"
  trust_entity_identifiers = ["lambda.amazonaws.com"]

  inline_policies = {
    s3-read = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:ListBucket"
          ]
          Resource = [
            "arn:aws:s3:::my-bucket",
            "arn:aws:s3:::my-bucket/*"
          ]
        }
      ]
    })

    dynamodb-write = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:PutItem",
            "dynamodb:UpdateItem"
          ]
          Resource = "arn:aws:dynamodb:*:123456789012:table/ProcessedData"
        }
      ]
    })
  }

  tags = {
    Environment = "production"
  }
}
```

### Role with MFA Requirement

```hcl
module "mfa_required_role" {
  source = "./modules/iam"

  role_name                    = "admin-access-role"
  role_description             = "Role requiring MFA for access"
  trust_entity_type            = "AWS"
  trust_entity_identifiers     = ["arn:aws:iam::123456789012:root"]

  assume_role_conditions = [
    {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    },
    {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = ["203.0.113.0/24"]
    }
  ]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]

  tags = {
    Security = "high"
  }
}
```

### Role with Permission Boundary

```hcl
module "delegated_role" {
  source = "./modules/iam"

  role_name                = "developer-deployment-role"
  trust_entity_type        = "AWS"
  trust_entity_identifiers = ["arn:aws:iam::123456789012:role/CI-CD-Pipeline"]

  # Limit permissions to EC2 and RDS only
  permission_boundary_arn = "arn:aws:iam::aws:policy/PowerUserAccess"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
  ]

  tags = {
    Team = "platform"
  }
}
```

### Role for Cross-Account Access

```hcl
module "cross_account_role" {
  source = "./modules/iam"

  role_name            = "cross-account-read-role"
  role_description     = "Allow read-only access from partner AWS account"
  trust_entity_type    = "AWS"
  trust_entity_identifiers = [
    "arn:aws:iam::999888777666:root",
    "arn:aws:iam::999888777666:role/DataAnalyst"
  ]

  inline_policies = {
    read-only = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:ListBucket",
            "dynamodb:GetItem",
            "dynamodb:Query"
          ]
          Resource = "*"
        }
      ]
    })
  }

  tags = {
    Partnership = "acme-corp"
  }
}
```

### Role with ABAC Tags

```hcl
module "abac_role" {
  source = "./modules/iam"

  role_name            = "project-team-role"
  trust_entity_type    = "Service"
  trust_entity_identifiers = ["lambda.amazonaws.com"]

  session_tags = {
    Department    = "finance"
    Project       = "billing-system"
    CostCenter    = "1234"
    Environment   = "production"
  }

  manage_policy_arns = [
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]

  tags = {
    Tagging = "enabled"
  }
}
```

### Role with Audit Logging

```hcl
module "audited_role" {
  source = "./modules/iam"

  role_name                       = "sensitive-data-processor"
  trust_entity_type               = "Service"
  trust_entity_identifiers        = ["lambda.amazonaws.com"]
  enable_iam_access_logging       = true
  enable_cloudtrail               = true
  log_retention_days              = 90

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  tags = {
    Compliance = "hipaa"
  }
}
```

## Input Variables

### Core Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `role_name` | string | - | Name of the IAM role (required) |
| `role_description` | string | "" | Description of the role |
| `trust_entity_type` | string | - | Type of entity (Service, AWS, Federated, CanonicalUser) |
| `trust_entity_identifiers` | list(string) | - | Service principals or ARNs for assume role |

### Policy Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `inline_policies` | map(string) | {} | Map of inline policies to attach |
| `managed_policy_arns` | list(string) | [] | AWS managed policy ARNs to attach |
| `create_custom_policy` | bool | false | Create a custom managed policy |
| `custom_policy_document` | string | "" | JSON policy document for custom policy |
| `permission_boundary_arn` | string | "" | ARN of permission boundary policy |

### Security Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `assume_role_conditions` | list(object) | [] | Conditions for assuming the role |
| `max_session_duration` | number | 3600 | Max session duration in seconds |
| `session_tags` | map(string) | {} | Session tags for ABAC |

### Instance Profile Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `create_instance_profile` | bool | false | Create an EC2 instance profile |

### Auditing Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_iam_access_logging` | bool | false | Enable CloudWatch logging |
| `enable_cloudtrail` | bool | false | Enable CloudTrail auditing |
| `log_retention_days` | number | 30 | Log retention in days |

## Output Values

```hcl
output "role_arn"                    # Full ARN of the role
output "role_name"                   # Name of the role
output "role_id"                     # Role ID
output "instance_profile_arn"        # Instance profile ARN (if created)
output "instance_profile_name"       # Instance profile name (if created)
output "custom_policy_arn"           # Custom managed policy ARN
output "custom_policy_name"          # Custom managed policy name
output "cloudwatch_log_group_name"   # CloudWatch log group name
output "cloudtrail_name"             # CloudTrail trail name
output "cloudtrail_s3_bucket"        # S3 bucket for CloudTrail logs
```

## Advanced Usage

### Assume Role from Application Code

```hcl
# Deploy role
module "app_role" {
  source = "./modules/iam"

  role_name                    = "my-app-role"
  trust_entity_type            = "Service"
  trust_entity_identifiers     = ["lambda.amazonaws.com"]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  ]

  tags = {
    Application = "data-processing"
  }
}

# In Python Lambda code
import boto3

sts = boto3.client('sts')
credentials = sts.assume_role(
    RoleArn="arn:aws:iam::ACCOUNT_ID:role/my-app-role",
    RoleSessionName="app-session"
)
```

### Cross-Account Access Setup

**Account A (Data Owner)**
```hcl
module "data_provider_role" {
  source = "./modules/iam"

  role_name                = "account-a-data-read-role"
  trust_entity_type        = "AWS"
  trust_entity_identifiers = ["arn:aws:iam::ACCOUNT_B:root"]

  inline_policies = {
    s3-read = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = "arn:aws:s3:::data-bucket/*"
      }]
    })
  }
}
```

**Account B (Data Consumer)**
```python
import boto3

sts = boto3.client('sts')
response = sts.assume_role(
    RoleArn="arn:aws:iam::ACCOUNT_A:role/account-a-data-read-role",
    RoleSessionName="cross-account-session",
    ExternalId="unique-external-id"
)

s3 = boto3.client('s3', **response['Credentials'])
```

## Security Best Practices

1. **Use AWS Managed Policies When Possible** - Easier to maintain and update
2. **Implement Permission Boundaries** - Prevents privilege escalation in delegated environments
3. **Enable MFA for Sensitive Roles** - Use `assume_role_conditions` with MFA checks
4. **Audit with CloudTrail** - Use `enable_cloudtrail = true` for sensitive operations
5. **Apply Least Privilege** - Create specific inline policies rather than using broad AWS policies
6. **Use Session Duration Limits** - Set `max_session_duration` appropriately per role
7. **Enable ABAC** - Use `session_tags` for scalable, tag-based access control

## Troubleshooting

### AssumeRole Fails

```bash
# Check role trust policy
aws iam get-role --role-name my-role

# Check conditions
aws iam get-role-policy --role-name my-role --policy-name policy-name

# Verify permissions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT:role/my-role \
  --action-names s3:GetObject
```

### Permission Denied on AssumeRole

- Verify trust policy: role trust policy must allow the principal
- Check session duration: may have expired
- Verify MFA condition if required
- Check IP restrictions in conditions

### CloudTrail Not Writing Logs

- Verify S3 bucket policy is correct
- Check CloudTrail is enabled: `aws cloudtrail describe-trails`
- Verify IAM permissions for CloudTrail service role

## Cost Optimization

- IAM roles and policies are **free**
- CloudTrail: $2.00 per 100,000 events
- CloudWatch Logs: $0.50 per GB ingested
- Consider disabling `enable_cloudtrail` for dev/test roles

## Related Modules

- **Lambda Module** - Uses IAM roles for function execution
- **EC2 Module** - Uses IAM roles via instance profiles
- **SageMaker Module** - Uses IAM roles for model execution
- **S3 Module** - Can be accessed using IAM roles

## Additional Resources

- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AssumeRole Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html)
- [ABAC with AWS](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction_attribute-based-access-control.html)
- [Cross-Account Access](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_common-scenarios_aws-accounts.html)
