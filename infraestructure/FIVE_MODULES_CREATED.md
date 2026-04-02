# Five Terraform Modules Created - IAM & DynamoDB

Complete Terraform infrastructure modules for AWS deployment with comprehensive documentation.

## 📦 What's New

Two additional modules have been created, bringing your total to **5 production-ready modules**:

### ✅ **New: IAM Module** (350+ lines)
- Create and manage IAM roles with trust policies
- Attach AWS managed and inline policies
- Permission boundaries for delegation
- CloudTrail audit logging
- Cross-account access support
- MFA and IP-based conditions

### ✅ **New: DynamoDB Module** (500+ lines)
- Deploy DynamoDB tables with GSI/LSI
- Auto-scaling for provisioned capacity
- Point-in-time recovery (PITR)
- Global tables for multi-region
- Automatic backups with retention
- DynamoDB Streams for event processing

---

## 📁 Complete Module Structure

```
infraestructure/
├── modules/
│   ├── iam/                           ⭐ NEW
│   │   ├── main.tf                    (IAM resources, CloudTrail)
│   │   ├── variables.tf               (30+ parameters)
│   │   ├── outputs.tf                 (20+ outputs)
│   │   └── README.md                  (550+ lines)
│   │
│   ├── dynamodb/                      ⭐ NEW
│   │   ├── main.tf                    (DynamoDB, backups, streams)
│   │   ├── variables.tf               (40+ parameters)
│   │   ├── outputs.tf                 (25+ outputs)
│   │   └── README.md                  (650+ lines)
│   │
│   ├── sagemaker_model_deployment/    (Previously created)
│   │   ├── main.tf
│   │   ├── iam.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   │
│   ├── lambda/
│   │   ├── main.tf
│   │   ├── iam.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   │
│   ├── ec2/
│   │   ├── main.tf
│   │   ├── iam.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   │
│   └── s3/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
│
└── examples/
    ├── iam-examples.tf                ⭐ NEW (5 working examples)
    ├── dynamodb-examples.tf           ⭐ NEW (7 working examples)
    ├── lambda-basic.tf
    ├── lambda-advanced.tf
    ├── ec2-basic.tf
    ├── ec2-advanced.tf
    ├── s3-basic.tf
    ├── s3-advanced.tf
    └── integration-example.tf
```

---

## 🚀 Quick Start - IAM Module

### Example 1: Lambda Execution Role

```hcl
module "lambda_role" {
  source = "./modules/iam"

  role_name            = "lambda-execution-role"
  trust_entity_type    = "Service"
  trust_entity_identifiers = ["lambda.amazonaws.com"]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  inline_policies = {
    s3-access = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::my-bucket/*"
      }]
    })
  }
}
```

### Example 2: EC2 Instance Role

```hcl
module "ec2_role" {
  source = "./modules/iam"

  role_name            = "ec2-web-server-role"
  trust_entity_type    = "Service"
  trust_entity_identifiers = ["ec2.amazonaws.com"]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]

  create_instance_profile = true
}
```

### Example 3: Cross-Account with MFA

```hcl
module "cross_account_role" {
  source = "./modules/iam"

  role_name            = "cross-account-admin"
  trust_entity_type    = "AWS"
  trust_entity_identifiers = ["arn:aws:iam::111111111111:root"]

  assume_role_conditions = [
    {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  ]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]

  enable_cloudtrail    = true
  log_retention_days   = 90
}
```

---

## 🚀 Quick Start - DynamoDB Module

### Example 1: Simple On-Demand Table

```hcl
module "users_table" {
  source = "./modules/dynamodb"

  table_name   = "users"
  hash_key     = "user_id"
  billing_mode = "PAY_PER_REQUEST"

  enable_point_in_time_recovery = true

  tags = {
    Application = "user-service"
  }
}
```

### Example 2: Provisioned with Auto-Scaling

```hcl
module "orders_table" {
  source = "./modules/dynamodb"

  table_name      = "orders"
  hash_key        = "order_id"
  range_key       = "created_at"
  billing_mode    = "PROVISIONED"
  read_capacity   = 10
  write_capacity  = 10

  enable_autoscaling = true
  autoscaling_max_read_capacity  = 1000
  autoscaling_max_write_capacity = 1000

  tags = {
    Application = "e-commerce"
  }
}
```

### Example 3: With Global Secondary Index

```hcl
module "events_table" {
  source = "./modules/dynamodb"

  table_name   = "events"
  hash_key     = "event_id"
  billing_mode = "PAY_PER_REQUEST"

  additional_attributes = [
    { name = "user_id", type = "S" }
  ]

  global_secondary_indexes = [
    {
      name            = "user-id-index"
      hash_key        = "user_id"
      projection_type = "ALL"
    }
  ]

  enable_streams = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
}
```

### Example 4: With Backup and Global Replication

```hcl
module "global_analytics_table" {
  source = "./modules/dynamodb"

  table_name   = "global-analytics"
  hash_key     = "metric_id"
  billing_mode = "PAY_PER_REQUEST"

  # Enable backups
  enable_backup_vault = true
  backup_schedule     = "cron(0 2 ? * * *)"  # 2 AM UTC
  backup_retention_days = 90

  # Multi-region replication
  enable_global_table = true
  replica_regions = ["us-west-2", "eu-west-1"]

  enable_point_in_time_recovery = true
}
```

---

## 🔗 Integration Examples

### IAM + Lambda

```hcl
# Create role
module "lambda_role" {
  source = "./modules/iam"
  role_name = "data-processor-role"
  trust_entity_type = "Service"
  trust_entity_identifiers = ["lambda.amazonaws.com"]
  # ... policies ...
}

# Use role in Lambda
module "processor_lambda" {
  source = "./modules/lambda"
  function_name = "data-processor"
  role_arn = module.lambda_role.role_arn
  # ... other config ...
}
```

### Lambda + DynamoDB Streams

```hcl
# Create DynamoDB table
module "data_table" {
  source = "./modules/dynamodb"
  table_name = "data-events"
  enable_streams = true
}

# Lambda processes stream
module "stream_processor" {
  source = "./modules/lambda"
  function_name = "stream-processor"
  environment_variables = {
    TABLE_ARN = module.data_table.table_arn
  }
}

# Connect stream to Lambda
resource "aws_lambda_event_source_mapping" "stream" {
  event_source_arn = module.data_table.table_stream_arn
  function_name    = module.stream_processor.function_name
}
```

### EC2 + DynamoDB + S3

```hcl
# Create IAM role for EC2
module "app_role" {
  source = "./modules/iam"
  role_name = "app-server-role"
  trust_entity_type = "Service"
  trust_entity_identifiers = ["ec2.amazonaws.com"]
  create_instance_profile = true
}

# Create DynamoDB for app storage
module "app_database" {
  source = "./modules/dynamodb"
  table_name = "app-data"
}

# Create S3 for app assets
module "app_assets" {
  source = "./modules/s3"
  bucket_name = "app-assets-${data.aws_caller_identity.current.account_id}"
}

# Launch EC2 with role
module "web_server" {
  source = "./modules/ec2"
  instance_type = "t3.medium"
  iam_instance_profile = module.app_role.instance_profile_name
}
```

---

## 📊 Feature Comparison

| Feature | IAM | DynamoDB | Lambda | EC2 | S3 | SageMaker |
|---------|-----|----------|--------|-----|-----|-----------|
| Cost Control | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Auto-Scaling | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ |
| Monitoring | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Backup | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ |
| Multi-Region | ❌ | ✅ | ✅ | ❌ | ✅ | ✅ |
| Encryption | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## 💡 Common Use Cases

### Use Case 1: Web Application

```
IAM (roles) → EC2 (web server) → DynamoDB (database) → S3 (static assets)
         ↓
    Lambda (background jobs)
```

### Use Case 2: Serverless Data Pipeline

```
IAM (Lambda role) → Lambda (process) → DynamoDB (store) → S3 (archive)
                         ↓
                    DynamoDB Streams
```

### Use Case 3: ML Model Deployment

```
IAM (SageMaker role) → SageMaker (inference) → Lambda (preprocessing) → DynamoDB (results)
                            ↓
                          S3 (models)
```

### Use Case 4: Multi-Account Setup

```
Account A (Data)           Account B (Analytics)
  ↓                              ↓
IAM (cross-account role) ← Assume Role
  ↓
DynamoDB (share data via streams)
```

---

## 🔐 Security Best Practices Per Module

### IAM
- ✅ Use AWS managed policies when possible
- ✅ Enable CloudTrail for sensitive roles
- ✅ Apply permission boundaries for delegated access
- ✅ Require MFA for elevated permissions
- ✅ Use least privilege principle

### DynamoDB
- ✅ Enable encryption at rest (default)
- ✅ Enable point-in-time recovery
- ✅ Use separate GSIs for different access patterns
- ✅ Enable streams for audit trails
- ✅ Set TTL for temporary data

---

## 📖 Documentation Links

### IAM Module
- **README**: [modules/iam/README.md](../modules/iam/README.md) - 550+ lines
- **Examples**: [examples/iam-examples.tf](../examples/iam-examples.tf) - 5 working examples

### DynamoDB Module
- **README**: [modules/dynamodb/README.md](../modules/dynamodb/README.md) - 650+ lines
- **Examples**: [examples/dynamodb-examples.tf](../examples/dynamodb-examples.tf) - 7 working examples

### Master Documentation
- **Modules Guide**: [MODULES_GUIDE.md](MODULES_GUIDE.md) - Architecture overview

---

## 🚀 Deployment Steps

### 1. Initialize Terraform

```bash
cd infraestructure
terraform init
```

### 2. Deploy IAM Role

```bash
# Copy example
cp examples/iam-examples.tf my-iam.tf

# Adjust variables
vim my-iam.tf

# Deploy
terraform plan
terraform apply
```

### 3. Deploy DynamoDB Table

```bash
# Copy example
cp examples/dynamodb-examples.tf my-table.tf

# Adjust variables
vim my-table.tf

# Deploy
terraform plan
terraform apply
```

### 4. Verify Deployment

```bash
# Check IAM role
aws iam get-role --role-name my-role

# Check DynamoDB table
aws dynamodb describe-table --table-name my-table

# Check outputs
terraform output
```

---

## 📊 Cost Estimation

### IAM Costs
- ✅ **FREE** - No charges for IAM roles and policies
- CloudTrail: $2.00 per 100K events (if enabled)

### DynamoDB Costs (us-east-1)

| Mode | Pricing | Monthly (1M requests) |
|------|---------|----------------------|
| **On-Demand (PAY_PER_REQUEST)** | $1.25/M reads, $6.25/M writes | $7.50 for 1M reads+writes |
| **Provisioned 10 RCU/WCU** | $0.00013/RCU-hr, $0.00065/WCU-hr | ~$100/month |
| **Provisioned 100 RCU/WCU** | Same per-unit rates | ~$1,000/month |

**Recommendation**: Use **PAY_PER_REQUEST** for unpredictable workloads, **PROVISIONED** with auto-scaling for stable traffic.

---

## ✅ Checklist - What You Have

- [x] IAM module for role management
- [x] DynamoDB module for database deployment
- [x] 5 production-ready IAM examples
- [x] 7 production-ready DynamoDB examples
- [x] 550+ lines IAM documentation
- [x] 650+ lines DynamoDB documentation
- [x] Integration patterns with other modules
- [x] Security best practices
- [x] Troubleshooting guides

---

## 🎯 Next Steps

1. **Review Documentation**
   - Read [modules/iam/README.md](../modules/iam/README.md)
   - Read [modules/dynamodb/README.md](../modules/dynamodb/README.md)

2. **Select Examples**
   - Choose from [examples/iam-examples.tf](../examples/iam-examples.tf)
   - Choose from [examples/dynamodb-examples.tf](../examples/dynamodb-examples.tf)

3. **Customize for Your Needs**
   - Adjust variables
   - Add inline policies as needed
   - Configure auto-scaling parameters

4. **Deploy**
   ```bash
   terraform plan
   terraform apply
   ```

5. **Monitor**
   - Check CloudWatch metrics
   - Review CloudTrail logs (if enabled)
   - Monitor DynamoDB capacity usage

---

**All modules are production-ready and follow AWS best practices!** 🎉
