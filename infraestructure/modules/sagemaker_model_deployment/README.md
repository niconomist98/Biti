# SageMaker Model Deployment Terraform Module

A comprehensive Terraform module for deploying machine learning models to AWS SageMaker with production-ready features including auto-scaling, monitoring, data capture, and VPC support.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Module Structure](#module-structure)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Configuration Examples](#configuration-examples)
- [Advanced Features](#advanced-features)
- [Monitoring and Logging](#monitoring-and-logging)
- [Troubleshooting](#troubleshooting)
- [Inputs](#inputs)
- [Outputs](#outputs)

## Features

✅ **Complete SageMaker Deployment**
- Automated model and endpoint creation
- Multi-framework support (PyTorch, TensorFlow, XGBoost, scikit-learn, MXNet)
- Custom container image support

✅ **Security & Access Control**
- Fine-grained IAM roles and policies
- S3 model artifact access
- ECR private image registry support
- VPC integration for network isolation

✅ **Auto-Scaling**
- Target tracking scaling policies
- Configurable min/max capacity
- Customizable scale in/out cooldown periods

✅ **Monitoring & Observability**
- CloudWatch metrics and alarms
- Data capture for model monitoring
- X-Ray tracing support
- CloudWatch Logs integration

✅ **Production Ready**
- Resource tagging and naming conventions
- Environment-aware deployments
- State management and versioning

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Terraform Module                      │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────────────────────────────────────────┐  │
│  │           SageMaker Endpoint Variant             │  │
│  │  ┌────────────────────────────────────────────┐  │  │
│  │  │   Container (PyTorch/TF/XGBoost/Sklearn)  │  │  │
│  │  │                                            │  │  │
│  │  │  Model Artifact: s3://bucket/model.tar.gz │  │  │
│  │  └────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────┘  │
│                         ↕                                │
│  ┌────────────────────────────────────────────────┐   │
│  │         IAM Role & Policies                    │   │
│  │  • S3 Read Access (Model Artifacts)            │   │
│  │  • S3 Write Access (Data Capture)              │   │
│  │  • CloudWatch Logs                             │   │
│  │  • CloudWatch Metrics                          │   │
│  │  • X-Ray Tracing (Optional)                    │   │
│  │  • ECR Access (If Custom Image)                │   │
│  └────────────────────────────────────────────────┘   │
│                         ↕                                │
│  ┌────────────────────────────────────────────────┐   │
│  │    Monitoring & Observability                  │   │
│  │  • CloudWatch Alarms (CPU, Memory, Errors)    │   │
│  │  • Auto-Scaling Policy                         │   │
│  │  • Data Capture (Input/Output Logging)         │   │
│  └────────────────────────────────────────────────┘   │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0
3. **AWS CLI** configured with credentials
4. **Model artifact** uploaded to S3 in tar.gz format
5. **Container image** (either AWS SageMaker built-in or custom ECR image)

### Required IAM Permissions

Your AWS credentials must have permissions for:
- SageMaker (CreateModel, CreateEndpoint, CreateEndpointConfig)
- IAM (CreateRole, AttachRolePolicy)
- S3 (GetObject from model bucket)
- CloudWatch (PutMetricAlarm)
- AppAutoScaling (RegisterScalableTarget)
- Logs (CreateLogGroup)

## Module Structure

```
sagemaker_model_deployment/
├── main.tf                 # SageMaker model, endpoint, endpoint config, autoscaling
├── iam.tf                  # IAM roles and policies
├── variables.tf            # Input variables with validation
├── outputs.tf              # Output values
└── README.md              # This file
```

## Getting Started

### 1. Prepare Your Model Artifact

Your model must be packaged as a tar.gz file and uploaded to S3:

```bash
# Example with PyTorch model
tar -czf model.tar.gz code/ model.pth

# Upload to S3
aws s3 cp model.tar.gz s3://my-bucket/models/my-model/model.tar.gz
```

### 2. Determine Your Container Image URI

**AWS SageMaker Built-in Algorithms:**
- PyTorch: `382416733822.dkr.ecr.us-east-1.amazonaws.com/sagemaker-pytorch:2.1-cpu-py310`
- TensorFlow: `382416733822.dkr.ecr.us-east-1.amazonaws.com/sagemaker-tensorflow:2.13-cpu-py311`
- XGBoost: `246618743249.dkr.ecr.us-east-1.amazonaws.com/sagemaker-xgboost:1.7-1-cpu-py3`
- Scikit-Learn: `246618743249.dkr.ecr.us-east-1.amazonaws.com/sagemaker-scikit-learn:1.3-1-cpu-py3`

Find the correct image for your region: [SageMaker Algorithms Registry](https://docs.aws.amazon.com/sagemaker/latest/dg/sagemaker-algo-docker-registry-paths.html)

**Custom ECR Image:**
```
<account-id>.dkr.ecr.<region>.amazonaws.com/<repo-name>:<tag>
```

### 3. Create Module Configuration

Create a Terraform configuration file (e.g., `main.tf`):

```hcl
module "sagemaker_deployment" {
  source = "./modules/sagemaker_model_deployment"

  # Required variables
  project_name                = "my-project"
  environment                 = "prod"
  model_name                  = "my-model"
  endpoint_name              = "my-model-endpoint"
  model_artifact_s3_uri      = "s3://my-bucket/models/my-model/model.tar.gz"
  model_container_image_uri  = "382416733822.dkr.ecr.us-east-1.amazonaws.com/sagemaker-pytorch:2.1-cpu-py310"

  # Optional: Instance configuration
  instance_type          = "ml.t3.medium"
  initial_instance_count = 1

  # Optional: Tags
  tags = {
    Team        = "ml-platform"
    CostCenter  = "engineering"
  }
}
```

### 4. Deploy

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply

# Get outputs
terraform output
```

## Usage

### Basic Deployment

```hcl
module "sagemaker_deployment" {
  source = "./modules/sagemaker_model_deployment"

  project_name               = "cryptocurrency-forecast"
  environment                = "prod"
  model_name                 = "btc-price-predictor"
  endpoint_name             = "btc-predictor-endpoint"
  model_artifact_s3_uri     = "s3://ml-models-bucket/btc-predictor/model.tar.gz"
  model_container_image_uri = "382416733822.dkr.ecr.us-east-1.amazonaws.com/sagemaker-pytorch:2.1-cpu-py310"
  aws_region                = "us-east-1"
}
```

### Advanced Deployment with Auto-Scaling

```hcl
module "sagemaker_deployment" {
  source = "./modules/sagemaker_model_deployment"

  project_name               = "cryptocurrency-forecast"
  environment                = "prod"
  model_name                 = "btc-price-predictor"
  endpoint_name             = "btc-predictor-endpoint"
  model_artifact_s3_uri     = "s3://ml-models-bucket/btc-predictor/model.tar.gz"
  model_container_image_uri = "382416733822.dkr.ecr.us-east-1.amazonaws.com/sagemaker-pytorch:2.1-cpu-py310"

  # Instance configuration
  instance_type          = "ml.g4dn.xlarge"  # GPU instance
  initial_instance_count = 2

  # Auto-scaling configuration
  autoscaling_config = {
    min_capacity               = 1
    max_capacity               = 10
    target_value               = 70.0  # Target 70% invocation per instance
    scale_in_cooldown_seconds  = 300
    scale_out_cooldown_seconds = 60
  }

  # Monitoring
  enable_monitoring = true
  enable_data_capture = true
  data_capture_s3_prefix = "s3://ml-models-bucket/data-capture/"

  # Environment variables
  model_environment_variables = {
    TS_INFERENCE_DEFAULT_VERSION = "1.0"
    PYTORCH_ENV                  = "production"
  }

  tags = {
    Team       = "ml-platform"
    CostCenter = "engineering"
    Owner      = "ai-team"
  }
}
```

### Deployment with VPC Isolation

```hcl
module "sagemaker_deployment" {
  source = "./modules/sagemaker_model_deployment"

  project_name               = "cryptocurrency-forecast"
  environment                = "prod"
  model_name                 = "btc-price-predictor"
  endpoint_name             = "btc-predictor-endpoint"
  model_artifact_s3_uri     = "s3://ml-models-bucket/btc-predictor/model.tar.gz"
  model_container_image_uri = "382416733822.dkr.ecr.us-east-1.amazonaws.com/sagemaker-pytorch:2.1-cpu-py310"

  # VPC configuration for network isolation
  vpc_config = {
    subnet_ids         = ["subnet-12345", "subnet-67890"]
    security_group_ids = ["sg-12345"]
  }

  # X-Ray tracing
  enable_xray_tracing = true

  tags = {
    SecurityLevel = "high"
  }
}
```

## Configuration Examples

### Example 1: PyTorch Model Inference

**Model Artifact Structure:**
```
model.tar.gz
├── code/
│   ├── inference.py
│   ├── requirements.txt
│   └── utils/
└── model.pth
```

**Terraform Configuration:**
```hcl
module "pytorch_model" {
  source = "./modules/sagemaker_model_deployment"

  project_name               = "test"
  environment                = "dev"
  model_name                 = "pytorch-model"
  endpoint_name             = "pytorch-endpoint"
  model_artifact_s3_uri     = "s3://my-bucket/models/pytorch-model/model.tar.gz"
  model_container_image_uri = "382416733822.dkr.ecr.us-east-1.amazonaws.com/sagemaker-pytorch:2.1-cpu-py310"
  instance_type             = "ml.t3.medium"

  framework         = "pytorch"
  framework_version = "2.1"
  py_version        = "py310"
}
```

### Example 2: TensorFlow Model Inference

```hcl
module "tensorflow_model" {
  source = "./modules/sagemaker_model_deployment"

  project_name               = "test"
  environment                = "dev"
  model_name                 = "tensorflow-model"
  endpoint_name             = "tensorflow-endpoint"
  model_artifact_s3_uri     = "s3://my-bucket/models/tf-model/model.tar.gz"
  model_container_image_uri = "382416733822.dkr.ecr.us-east-1.amazonaws.com/sagemaker-tensorflow:2.13-cpu-py311"
  instance_type             = "ml.t3.large"

  framework         = "tensorflow"
  framework_version = "2.13"
  py_version        = "py311"
}
```

### Example 3: XGBoost Model with GPU

```hcl
module "xgboost_gpu_model" {
  source = "./modules/sagemaker_model_deployment"

  project_name               = "test"
  environment                = "prod"
  model_name                 = "xgboost-gpu-model"
  endpoint_name             = "xgboost-gpu-endpoint"
  model_artifact_s3_uri     = "s3://my-bucket/models/xgboost-model/model.tar.gz"
  model_container_image_uri = "246618743249.dkr.ecr.us-west-2.amazonaws.com/sagemaker-xgboost:1.7-1-gpu-py3"
  instance_type             = "ml.p3.2xlarge"  # GPU instance
  initial_instance_count    = 2

  framework         = "xgboost"
  framework_version = "1.7"
  py_version        = "py3"

  autoscaling_config = {
    min_capacity               = 1
    max_capacity               = 5
    target_value               = 75.0
    scale_in_cooldown_seconds  = 300
    scale_out_cooldown_seconds = 60
  }

  enable_monitoring = true
}
```

## Advanced Features

### 1. Auto-Scaling Configuration

Automatically scale your endpoint based on invocation load:

```hcl
autoscaling_config = {
  min_capacity               = 1    # Minimum instances
  max_capacity               = 10   # Maximum instances
  target_value               = 70.0 # Target 70% CPU or invocations per instance
  scale_in_cooldown_seconds  = 300  # Wait 5 min before scaling in
  scale_out_cooldown_seconds = 60   # Wait 1 min before scaling out
}
```

**Target Metrics:**
- `SageMakerVariantInvocationsPerInstance`: Scale based on prediction requests
- `CPUUtilization`: Scale based on CPU usage

### 2. Data Capture for Model Monitoring

Enable automatic capture of model inputs and outputs for drift detection:

```hcl
enable_data_capture     = true
data_capture_s3_prefix = "s3://my-bucket/data-capture/"
```

This captures:
- Input: Raw feature vectors
- Output: Model predictions
- Timestamp: When prediction was made

### 3. VPC Integration

Deploy your endpoint in a VPC for network isolation:

```hcl
vpc_config = {
  subnet_ids         = ["subnet-12345", "subnet-67890"]  # Private subnets
  security_group_ids = ["sg-12345"]                      # Security group
}
```

**Requirements:**
- Subnets must have outbound internet access (NAT Gateway)
- Security group must allow outbound HTTPS (443) to S3

### 4. X-Ray Tracing

Enable distributed tracing for debugging and performance analysis:

```hcl
enable_xray_tracing = true
```

View traces in AWS X-Ray console for:
- Request latency
- Dependency analysis
- Error tracking

### 5. Environment Variables

Pass configuration to your model container:

```hcl
model_environment_variables = {
  MODEL_VERSION           = "1.0"
  INFERENCE_MODE          = "batch"
  LOG_LEVEL              = "INFO"
  CUSTOM_PARAM           = "value"
}
```

### 6. Custom Model Data URL

Use different model data location than artifact:

```hcl
custom_model_data_url = "s3://different-bucket/models/model.tar.gz"
```

## Monitoring and Logging

### CloudWatch Metrics

The module automatically creates CloudWatch alarms for:

1. **CPU Utilization** - Alerts when > 80%
2. **GPU Memory Utilization** - Alerts when > 85%
3. **Model Invocation Errors** - Alerts on 4XX errors

Access metrics in CloudWatch:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/SageMaker \
  --metric-name CPUUtilization \
  --dimensions Name=EndpointName,Value=your-endpoint-name \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 300 \
  --statistics Average
```

### CloudWatch Logs

Model logs are automatically streamed to:
```
/aws/sagemaker/<endpoint-name>
```

View logs:
```bash
aws logs tail /aws/sagemaker/my-endpoint --follow
```

### Data Capture Inspection

Examine captured data:
```bash
# List captured files
aws s3 ls s3://my-bucket/data-capture/

# Download and inspect
aws s3 cp s3://my-bucket/data-capture/something.jsonl .
cat something.jsonl | jq .
```

## Making Predictions

### Using AWS CLI

```bash
# Invoke endpoint with JSON input
aws sagemaker-runtime invoke-endpoint \
  --endpoint-name my-model-endpoint \
  --content-type application/json \
  --body '{"instances": [[1.0, 2.0, 3.0]]}' \
  response.json

cat response.json
```

### Using Python (Boto3)

```python
import json
import boto3

client = boto3.client('sagemaker-runtime', region_name='us-east-1')

response = client.invoke_endpoint(
    EndpointName='my-model-endpoint',
    ContentType='application/json',
    Body=json.dumps({
        'instances': [[1.0, 2.0, 3.0]]
    })
)

predictions = json.loads(response['Body'].read())
print(predictions)
```

### Using JavaScript/Node.js

```javascript
const AWS = require('aws-sdk');
const sagemaker = new AWS.SageMakerRuntime();

const params = {
  EndpointName: 'my-model-endpoint',
  ContentType: 'application/json',
  Body: JSON.stringify({
    instances: [[1.0, 2.0, 3.0]]
  })
};

sagemaker.invokeEndpoint(params, (err, data) => {
  if (err) console.log(err);
  else console.log(JSON.parse(data.Body));
});
```

## Troubleshooting

### Issue: Model Artifact Not Found

**Error:** `ValidationException: Could not find model artifact at location`

**Solution:**
1. Verify S3 URI is correct: `s3://bucket-name/path/to/model.tar.gz`
2. Check IAM role has S3 read permissions
3. Verify bucket exists and file is accessible
4. Check bucket is in the same region or s3_regional_uri is used

```bash
# Test S3 access
aws s3 ls s3://my-bucket/models/my-model/model.tar.gz
```

### Issue: Endpoint Fails to Create

**Error:** `AccessDenied` or `UnauthorizedOperation`

**Solution:**
1. Verify IAM role has correct permissions
2. Check security group allows outbound traffic
3. Ensure subnets have route to S3 (NAT Gateway for private subnets)

```bash
# Check IAM role policies
aws iam list-role-policies --role-name my-role
```

### Issue: High Latency or Timeout

**Error:** `ModelInvocation5XX: Request timed out`

**Solution:**
1. Increase instance type: `ml.t3.large` → `ml.t3.xlarge`
2. Check CloudWatch Logs for model errors
3. Verify data capture isn't overwhelming the endpoint
4. Consider enabling auto-scaling

### Issue: Data Capture Not Working

**Error:** Files not appearing in S3

**Solution:**
1. Verify `data_capture_s3_prefix` is writable
2. Check IAM role has S3:PutObject permission
3. Wait 1+ hour for first data to appear (batched writes)
4. Verify endpoint is receiving traffic

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `project_name` | Project name for resource naming | `string` | N/A |
| `environment` | Environment (dev/staging/prod) | `string` | N/A |
| `model_name` | SageMaker model name | `string` | N/A |
| `endpoint_name` | SageMaker endpoint name | `string` | N/A |
| `model_artifact_s3_uri` | S3 URI of model artifact | `string` | N/A |
| `model_container_image_uri` | Container image URI | `string` | N/A |
| `aws_region` | AWS region | `string` | `us-east-1` |
| `instance_type` | SageMaker instance type | `string` | `ml.t3.medium` |
| `initial_instance_count` | Initial instance count | `number` | 1 |
| `autoscaling_config` | Auto-scaling configuration | `object` | `null` |
| `vpc_config` | VPC configuration | `object` | `null` |
| `enable_data_capture` | Enable data capture | `bool` | `false` |
| `enable_monitoring` | Enable CloudWatch monitoring | `bool` | `true` |
| `enable_xray_tracing` | Enable X-Ray tracing | `bool` | `false` |
| `tags` | Resource tags | `map(string)` | `{}` |

## Outputs

| Name | Description |
|------|-------------|
| `model_name` | Name of the created SageMaker model |
| `model_arn` | ARN of the created SageMaker model |
| `endpoint_name` | Name of the created SageMaker endpoint |
| `endpoint_arn` | ARN of the created SageMaker endpoint |
| `endpoint_url` | URL for making predictions |
| `deployment_info` | Complete deployment information |
| `cloudwatch_alarms` | CloudWatch alarm names |
| `prediction_command` | Example AWS CLI prediction command |

## Best Practices

1. **Use environment-specific configurations** - Create separate tfvars files for dev/staging/prod
2. **Enable monitoring** - Always enable monitoring and set up CloudWatch alarms
3. **Use auto-scaling** - Implement auto-scaling for production workloads
4. **Implement data capture** - Capture data for ongoing model monitoring and drift detection
5. **Use VPC** - Deploy endpoints in VPCs for network security
6. **Tag resources** - Use consistent tagging for cost allocation and resource management
7. **Backup and version models** - Keep model artifacts versioned in S3
8. **Test before production** - Always test in dev/staging environment first
9. **Monitor costs** - Set up AWS Cost Explorer alerts for SageMaker spending
10. **Use environment variables** - Pass configuration via environment variables, not code

## Additional Resources

- [AWS SageMaker Documentation](https://docs.aws.amazon.com/sagemaker/)
- [SageMaker Algorithm Registry](https://docs.aws.amazon.com/sagemaker/latest/dg/sagemaker-algo-docker-registry-paths.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [SageMaker Best Practices](https://docs.aws.amazon.com/sagemaker/latest/dg/best-practices.html)
