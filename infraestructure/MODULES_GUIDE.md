# Biti Infrastructure Module Suite

Complete Terraform module library for deploying AWS infrastructure with Lambda, EC2, S3, DynamoDB, and IAM. Part of the Biti cryptographic forecasting platform.

## 📦 Available Modules

### 1. **IAM Module** - Identity & Access Management
Manage AWS IAM roles, policies, and access control with trust relationships, permission boundaries, and audit logging.

- ✅ Create and manage IAM roles
- ✅ Attach AWS managed and inline policies
- ✅ Permission boundaries for delegation
- ✅ AssumeRole conditions (MFA, IP restrictions)
- ✅ CloudTrail audit logging
- ✅ Cross-account access support
- ✅ Instance profiles for EC2

**Location**: `modules/iam/`  
**Documentation**: [IAM Module README](modules/iam/README.md)  
**Examples**: [iam-examples.tf](examples/iam-examples.tf)

### 2. **DynamoDB Module** - NoSQL Database
Deploy DynamoDB tables with auto-scaling, global secondary indexes, backup, point-in-time recovery, and global tables.

- ✅ On-demand or provisioned billing
- ✅ Global and Local Secondary Indexes (GSI/LSI)
- ✅ Auto-scaling with target utilization
- ✅ DynamoDB Streams for event processing
- ✅ Point-in-time recovery (PITR)
- ✅ Global tables for multi-region
- ✅ Automatic backups with retention
- ✅ TTL for automatic item expiration

**Location**: `modules/dynamodb/`  
**Documentation**: [DynamoDB Module README](modules/dynamodb/README.md)  
**Examples**: [dynamodb-examples.tf](examples/dynamodb-examples.tf)

### 3. **Lambda Module** - Serverless Functions
Deploy serverless Lambda functions with monitoring, logging, scheduling, and custom IAM policies.

- ✅ Multi-runtime support (Python, Node.js, Go, Java, Ruby, .NET)
- ✅ EventBridge scheduling for background jobs
- ✅ CloudWatch monitoring and alarms
- ✅ VPC integration for database access
- ✅ Lambda function URLs for HTTP endpoints

**Location**: `modules/lambda/`  
**Documentation**: [Lambda Module README](modules/lambda/README.md)

### 2. **EC2 Module** - Virtual Machines
Deploy EC2 instances with auto-scaling, monitoring, storage, and security controls.

- ✅ Single instances or Auto Scaling Groups
- ✅ EBS volume configuration and optimization
- ✅ CloudWatch monitoring and alarms
- ✅ Security group management
- ✅ IAM role and SSM access

**Location**: `modules/ec2/`  
**Documentation**: [EC2 Module README](modules/ec2/README.md)

### 3. **S3 Module** - Object Storage
Deploy S3 buckets with lifecycle management, replication, encryption, and monitoring.

- ✅ Versioning and MFA delete protection
- ✅ Server-side encryption (AES256 or KMS)
- ✅ Lifecycle rules for cost optimization
- ✅ Cross-region replication
- ✅ Website hosting and CloudFront integration
- ✅ Logging and access metrics

**Location**: `modules/s3/`  
**Documentation**: [S3 Module README](modules/s3/README.md)

## 🚀 Quick Start

### Minimum Requirements

- Terraform >= 1.0
- AWS CLI configured with credentials
- AWS account (free tier eligible)

### 1. Create an IAM Role

```hcl
module "lambda_role" {
  source = "./modules/iam"

  role_name            = "lambda-data-processor"
  trust_entity_type    = "Service"
  trust_entity_identifiers = ["lambda.amazonaws.com"]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  tags = {
    Application = "data-processer"
  }
}
```

### 2. Deploy a DynamoDB Table

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

output "table_name" {
  value = module.users_table.table_name
}
```

### 3. Deploy a Basic S3 Bucket

```hcl
module "my_bucket" {
  source = "./modules/s3"

  bucket_name = "my-app-${data.aws_caller_identity.current.account_id}"
  
  enable_versioning = true
  block_public_access = true

  tags = {
    Environment = "production"
  }
}

output "bucket_name" {
  value = module.my_bucket.bucket_id
}
```

### 2. Deploy a Lambda Function

```hcl
module "my_function" {
  source = "./modules/lambda"

  function_name = "my-processor"
  source_dir    = "./src/lambda"
  runtime       = "python3.11"
  handler       = "index.handler"
  
  tags = {
    Environment = "production"
  }
}

output "function_arn" {
  value = module.my_function.function_arn
}
```

### 3. Deploy an EC2 Instance

```hcl
module "my_server" {
  source = "./modules/ec2"

  instance_name = "web-server"
  vpc_id        = aws_vpc.main.id
  subnet_id     = aws_subnet.public.id
  instance_type = "t3.micro"
  
  tags = {
    Environment = "production"
  }
}

output "instance_ip" {
  value = module.my_server.instance_public_ip
}
```

### 4. Run Terraform

```bash
cd infrastructure
terraform init
terraform plan
terraform apply
```

## 📚 Examples

The `examples/` directory contains production-ready configurations:

### IAM Examples
- **iam-examples.tf** - 5 working examples:
  - Lambda execution role with S3 access
  - EC2 instance role with Systems Manager
  - Cross-account admin with MFA
  - CI/CD deployment with permission boundary
  - SageMaker execution role

### DynamoDB Examples
- **dynamodb-examples.tf** - 7 working examples:
  - Simple on-demand user table
  - Provisioned orders table with auto-scaling
  - Session table with TTL
  - Real-time events table with Streams
  - Global analytics table with replication
  - Encrypted audit table with backup
  - Development test table

### Lambda Examples
- **lambda-basic.tf** - Simple Python function
- **lambda-advanced.tf** - VPC + Database + Custom policies

### EC2 Examples
- **ec2-basic.tf** - Single web server
- **ec2-advanced.tf** - Auto-scaled application fleet

### S3 Examples
- **s3-basic.tf** - Private data bucket
- **s3-advanced.tf** - Data lake with lifecycle + replication

### Integration Examples
- **integration-example.tf** - Lambda + EC2 + S3 together

## 📋 Module Comparison

| Feature | IAM | DynamoDB | Lambda | EC2 | S3 |
|---------|-----|----------|--------|-----|-----|
| Primary Use | Access control | NoSQL DB | Serverless | Virtual machines | Object storage |
| Pricing | FREE | Pay-per-request or provisioned | Pay-per-invocation | Always-on | Storage-based |
| Auto-scaling | N/A | ✅ | ✅ | ✅ ASG | Manual/Lifecycle |
| Backup | N/A | ✅ PITR/AWS Backup | ❌ | ✅ | ✅ Versioning |
| Multi-region | N/A | ✅ Global Tables | ✅ | ❌ | ✅ Replication |
| Monitoring | ✅ CloudTrail | ✅ CloudWatch | ✅ CloudWatch | ✅ CloudWatch | ✅ CloudWatch |
| Entry Cost/Month | $0 | $0-50 | $0-20 | $7-30 | $0-5 |

## 🏗️ Architecture Patterns

### Pattern 1: Serverless API with Database
```
IAM (Lambda role) → Lambda Function URL → DynamoDB → CloudWatch
```
**Use when**: Low traffic APIs, variable load, cost optimization  
**Modules**: IAM + Lambda + DynamoDB  
**Example**: `examples/lambda-basic.tf` + `dynamodb-examples.tf`

### Pattern 2: Web Application Server
```
IAM (EC2 role) → Load Balancer → EC2 Auto Scaling → DynamoDB
```
**Use when**: Long-running apps, consistent load, full control  
**Modules**: IAM + EC2 + DynamoDB  
**Example**: `examples/ec2-advanced.tf`

### Pattern 3: Data Lake Pipeline
```
IAM (Lambda role) → Lambda ETL → S3 (processed) → Analytics
                      ↓
                   DynamoDB (index)
```
**Use when**: Large data volumes, cost optimization needed  
**Modules**: IAM + Lambda + S3 + DynamoDB  
**Example**: `examples/s3-advanced.tf`

### Pattern 4: Event Processing with Streams
```
DynamoDB (Streams) → IAM (Lambda role) → Lambda → S3/SNS
```
**Use when**: Real-time data processing, event-driven architecture  
**Modules**: DynamoDB + IAM + Lambda  
**Example**: `dynamodb-examples.tf` (events table)

### Pattern 5: Multi-Server Application
```
ALB → IAM (EC2 role) → EC2 ASG → DynamoDB (table) → S3 (backup)
         ↓                                ↓
   CloudWatch monitoring          Point-in-time recovery
```
**Use when**: Complex multi-tier application  
**Modules**: IAM + EC2 + DynamoDB + S3  
**Example**: `examples/integration-example.tf`

## 💰 Cost Estimation

### Scenario 1: Development Environment (Monthly)
- 1x t3.micro EC2: $7.50
- 1x Lambda (10k invocations): $0.20
- 1x S3 (10GB): $0.23
- **Total: ~$8/month**

### Scenario 2: Production Environment (Monthly)
- 2x t3.small EC2 (ASG): $60
- Lambda (1M invocations): $20
- S3 (1TB): $23
- Monitoring & Data transfer: $50
- **Total: ~$150/month**

### Scenario 3: Data Lake (Monthly)
- EC2 for processing: $30
- S3 (10TB total, archive): $150
- Lambda for ETL: $50
- **Total: ~$230/month**

**Cost Optimization Tips**:
1. Use Lambda for intermittent workloads
2. Use Spot instances for EC2 (70% savings)
3. Archive S3 data older than 90 days (60% savings)
4. Reserved instances for predictable load (30-40% savings)

## 🔒 Security Best Practices

### IAM Security
✅ Use AWS managed policies when possible  
✅ Enable CloudTrail for sensitive roles  
✅ Apply permission boundaries for delegated access  
✅ Require MFA for elevated permissions  
✅ Use least privilege principle  
✅ Enable audit logging for compliance  

### DynamoDB Security
✅ Enable encryption at rest (default)  
✅ Enable point-in-time recovery (PITR)  
✅ Use separate GSIs for different access patterns  
✅ Enable streams for audit trails  
✅ Set TTL for temporary data  
✅ Use IAM roles for access control  

### Lambda Security
✅ Always use VPC for database access  
✅ Store secrets in Secrets Manager, not env vars  
✅ Enable X-Ray tracing for debugging  
✅ Use dedicated IAM roles with least privilege  

### EC2 Security
✅ Use Systems Manager Session Manager instead of SSH  
✅ Encrypt EBS volumes  
✅ Restrict security group rules  
✅ Use IMDSv2 (enforced by default)  

### S3 Security
✅ Block all public access by default  
✅ Enable versioning  
✅ Use KMS encryption for sensitive data  
✅ Enable logging for audit trail  

## 📖 Documentation

### Module Documentation
- [IAM Module README](modules/iam/README.md) - 550+ lines with 5 examples
- [DynamoDB Module README](modules/dynamodb/README.md) - 650+ lines with 7 examples
- [Lambda Module README](modules/lambda/README.md) - 100+ KB
- [EC2 Module README](modules/ec2/README.md) - 100+ KB  
- [S3 Module README](modules/s3/README.md) - 100+ KB

### Examples & Guides
- [Five Modules Created](FIVE_MODULES_CREATED.md) - Overview of all modules
- [Basic Deployment Guide](examples/DEPLOYMENT_GUIDE.md)
- [Biti Deployment Guide](BITI_DEPLOYMENT_GUIDE.md) - Crypto-specific
- [Deliverables Summary](DELIVERABLES.md)

### File Manifest
See [FILE_MANIFEST.txt](FILE_MANIFEST.txt) for complete directory listing

## 🛠️ Common Tasks

### Create an IAM Role
1. Copy `examples/iam-examples.tf`
2. Select the example that matches your use case
3. Update role name and trust entities
4. Run `terraform apply`

### Deploy a DynamoDB Table
1. Copy `examples/dynamodb-examples.tf`
2. Select the example that matches your use case (on-demand, provisioned, global, etc.)
3. Update table name and keys
4. Run `terraform apply`

### Deploy a Lambda Function
1. Create your code in `src/lambda/`
2. Copy `examples/lambda-basic.tf` to your directory
3. Update function name and settings
4. Run `terraform apply`

### Deploy a Web Server
1. Create VPC and security groups
2. Copy `examples/ec2-basic.tf`
3. Update instance type and SSH key
4. Run `terraform apply`

### Create Data Storage
1. Copy `examples/s3-basic.tf`
2. Update bucket name
3. Add lifecycle rules if needed
4. Run `terraform apply`

### Integrate Lambda with DynamoDB
1. Create DynamoDB table: `examples/dynamodb-examples.tf` (events table)
2. Create IAM role with DynamoDB permissions: `examples/iam-examples.tf`
3. Create Lambda with role: `examples/lambda-basic.tf`
4. Connect using `aws_lambda_event_source_mapping`

### Scale Application
1. Set `enable_auto_scaling = true` for DynamoDB or EC2
2. Configure `autoscaling_max_*` parameters
3. Enable scaling policies
4. Monitor via CloudWatch metrics

## 🐛 Troubleshooting

### Common Issues

**Lambda: "Function not found"**
- Check source_dir path is correct
- Verify handler matches code structure
- Check file permissions

**EC2: "Instance launch failed"**
- Verify subnet is in correct VPC
- Check AMI is available in region
- Verify key pair exists

**S3: "Bucket name already exists"**
- S3 bucket names are globally unique
- Add account ID to name: `my-bucket-${account_id}`
- Check bucket in different region

**Terraform: "State lock timeout"**
- Previous run may not have completed
- Delete `.terraform.lock.hcl` and try again
- Check no other instances running

## 🤝 Contributing

To add new features or fix bugs:

1. Create a branch from your module
2. Make changes following existing patterns
3. Test with `terraform plan` and `terraform apply`
4. Update corresponding README
5. Create pull request with description

## 📞 Support

For issues or questions:
- Check module README documentation
- Review example configurations
- Check AWS documentation links
- Open GitHub issue with details

## 📜 License

This infrastructure code is provided as-is for the Biti project.

## 🗂️ Directory Structure

```
infrastructure/
├── provider.tf                    # AWS provider configuration
├── variables.tf                   # Root variables
├── .gitignore                     # Git ignore rules
├── README.md                      # This file
├── SETUP_COMPLETE.md             # Setup guide
├── BITI_DEPLOYMENT_GUIDE.md      # Biti-specific guide
├── DELIVERABLES.md               # Deliverables summary
├── FILE_MANIFEST.txt             # File listing
│
├── modules/
│   ├── lambda/
│   │   ├── main.tf               # Lambda resources
│   │   ├── iam.tf                # IAM roles/policies
│   │   ├── variables.tf          # Input variables
│   │   ├── outputs.tf            # Output values
│   │   └── README.md             # Lambda documentation
│   │
│   ├── ec2/
│   │   ├── main.tf               # EC2 resources
│   │   ├── iam.tf                # IAM roles/policies
│   │   ├── variables.tf          # Input variables
│   │   ├── outputs.tf            # Output values
│   │   └── README.md             # EC2 documentation
│   │
│   └── s3/
│       ├── main.tf               # S3 resources
│       ├── variables.tf          # Input variables
│       ├── outputs.tf            # Output values
│       └── README.md             # S3 documentation
│
├── examples/
│   ├── DEPLOYMENT_GUIDE.md       # Step-by-step guide
│   ├── lambda-basic.tf           # Basic Lambda
│   ├── lambda-advanced.tf        # Advanced Lambda
│   ├── ec2-basic.tf              # Basic EC2
│   ├── ec2-advanced.tf           # Advanced EC2
│   ├── s3-basic.tf               # Basic S3
│   ├── s3-advanced.tf            # Advanced S3
│   ├── integration-example.tf    # Full integration
│   ├── terraform.tfvars.example  # Configuration template
│   └── test_endpoint.py          # Testing utility
│
└── environments/
    └── (Your environment configs)
```

## 🎯 Next Steps

1. **Read**: Start with [SETUP_COMPLETE.md](SETUP_COMPLETE.md)
2. **Choose**: Pick a use case (Lambda, EC2, or S3)
3. **Copy**: Use the appropriate example from `examples/`
4. **Configure**: Update variables for your needs
5. **Deploy**: Run `terraform apply`
6. **Monitor**: Check CloudWatch for metrics and alarms

---

**Version**: 1.0.0  
**Last Updated**: 2026  
**Maintained By**: Biti Platform Team

For detailed information on each module, see the individual README files in each `modules/*/` directory.
