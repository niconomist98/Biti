# Quick Start: How to Deploy Your Model

This guide explains step-by-step how to deploy your existing ML model artifact from S3 to AWS SageMaker using this Terraform module.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Verify Your Model Artifact](#step-1-verify-your-model-artifact)
3. [Step 2: Determine Your Container Image](#step-2-determine-your-container-image)
4. [Step 3: Create Your Terraform Configuration](#step-3-create-your-terraform-configuration)
5. [Step 4: Deploy the Endpoint](#step-4-deploy-the-endpoint)
6. [Step 5: Test Your Endpoint](#step-5-test-your-endpoint)
7. [Step 6: Monitor Your Endpoint](#step-6-monitor-your-endpoint)
8. [Cleanup](#cleanup)

## Prerequisites

- [x] AWS Account with SageMaker permissions
- [x] Model artifact packaged as `model.tar.gz` and uploaded to S3
- [x] Terraform >= 1.0 installed
- [x] AWS CLI configured with credentials
- [x] Basic knowledge of your model framework (PyTorch, TensorFlow, XGBoost, etc.)

Verify your setup:

```bash
# Check Terraform
terraform --version

# Check AWS CLI
aws --version

# Test AWS credentials
aws sts get-caller-identity
```

## Step 1: Verify Your Model Artifact

Your model must be packaged and available in S3. 

### Verify S3 Location

```bash
# List and verify your model artifact
aws s3 ls s3://your-bucket/path/to/model.tar.gz

# Expected output:
# 2024-03-31 10:30:45  123456789   model.tar.gz
```

### Understand Your Model Package Structure

Your `model.tar.gz` should contain:

```
model.tar.gz
├── code/
│   ├── inference.py      # (or entry_point script)
│   ├── requirements.txt
│   └── utils/
└── model.pth             # (or model.pb, model.joblib, etc.)
```

**For Different Frameworks:**

**PyTorch:**
```
model.tar.gz
├── code/
│   ├── inference.py
│   └── requirements.txt
└── model.pth
```

**TensorFlow:**
```
model.tar.gz
├── code/
│   ├── inference.py
│   └── requirements.txt
└── model/
    ├── saved_model.pb
    └── variables/
```

**XGBoost/Scikit-Learn:**
```
model.tar.gz
└── model.joblib  # or model.pkl
```

## Step 2: Determine Your Container Image

Identify which container image is appropriate for your model framework and region.

### AWS SageMaker Built-in Images

SageMaker provides free container images for common frameworks. Find the correct Regional Repository ID:

#### PyTorch Images (CPU and GPU)

**us-east-1:**
```
382416733822.dkr.ecr.us-east-1.amazonaws.com/sagemaker-pytorch:2.1-cpu-py310
382416733822.dkr.ecr.us-east-1.amazonaws.com/sagemaker-pytorch:2.1-gpu-py310
```

**us-west-2:**
```
246618743249.dkr.ecr.us-west-2.amazonaws.com/sagemaker-pytorch:2.1-cpu-py310
246618743249.dkr.ecr.us-west-2.amazonaws.com/sagemaker-pytorch:2.1-gpu-py310
```

#### TensorFlow Images (CPU and GPU)

**us-east-1:**
```
382416733822.dkr.ecr.us-east-1.amazonaws.com/sagemaker-tensorflow:2.13-cpu-py311
382416733822.dkr.ecr.us-east-1.amazonaws.com/sagemaker-tensorflow:2.13-gpu-py311
```

**us-west-2:**
```
246618743249.dkr.ecr.us-west-2.amazonaws.com/sagemaker-tensorflow:2.13-cpu-py311
246618743249.dkr.ecr.us-west-2.amazonaws.com/sagemaker-tensorflow:2.13-gpu-py311
```

#### XGBoost Images

**us-east-1:**
```
246618743249.dkr.ecr.us-east-1.amazonaws.com/sagemaker-xgboost:1.7-1-cpu-py3
```

**us-west-2:**
```
246618743249.dkr.ecr.us-west-2.amazonaws.com/sagemaker-xgboost:1.7-1-cpu-py3
```

#### Scikit-Learn Images

**us-east-1:**
```
246618743249.dkr.ecr.us-east-1.amazonaws.com/sagemaker-scikit-learn:1.3-1-cpu-py3
```

**us-west-2:**
```
246618743249.dkr.ecr.us-west-2.amazonaws.com/sagemaker-scikit-learn:1.3-1-cpu-py3
```

**Find your region's repository:**

```bash
# For PyTorch
aws ecr describe-repositories \
  --region us-east-1 \
  --registry-id 382416733822 \
  --query 'repositories[*].repositoryName' \
  --output table | grep pytorch
```

## Step 3: Create Your Terraform Configuration

Create a new file in the `environments/` directory for your specific model.

### Example: Deploy a PyTorch Model

Create `environments/pytorch-model.tf`:

```hcl
# ============================================================
# SageMaker Endpoint for Your PyTorch Model
# ============================================================

module "my_pytorch_model" {
  source = "../modules/sagemaker_model_deployment"

  # ============================================================
  # REQUIRED: Modify these values for your model
  # ============================================================

  # Project identifier
  project_name   = "biti"
  environment    = "prod"                    # dev, staging, or prod

  # Model information
  model_name     = "my-crypto-predictor"     # Descriptive name
  endpoint_name = "my-crypto-predictor-endpoint"

  # ⭐ YOUR MODEL ARTIFACT S3 URI - CHANGE THIS!
  model_artifact_s3_uri = "s3://your-bucket/path/to/model.tar.gz"

  # ⭐ YOUR CONTAINER IMAGE - CHANGE THIS!
  # Use PyTorch image from Step 2
  model_container_image_uri = "382416733822.dkr.ecr.us-east-1.amazonaws.com/sagemaker-pytorch:2.1-cpu-py310"

  # AWS region
  aws_region = "us-east-1"

  # ============================================================
  # OPTIONAL: Fine-tune these settings
  # ============================================================

  # Instance type (CPU vs GPU)
  # CPU: ml.t3.medium, ml.t3.large, ml.t3.xlarge, ml.c5.large, ml.c5.xlarge
  # GPU: ml.g4dn.xlarge, ml.g4dn.2xlarge, ml.p3.2xlarge, ml.p3.8xlarge
  instance_type          = "ml.t3.medium"   # For low-traffic models
  # instance_type         = "ml.g4dn.xlarge"  # For GPU inference

  # Number of initial instances
  initial_instance_count = 1

  # Framework information
  framework         = "pytorch"
  framework_version = "2.1"
  py_version        = "py310"

  # ============================================================
  # ADVANCED OPTIONS (optional)
  # ============================================================

  # Enable auto-scaling for high-traffic models
  # autoscaling_config = {
  #   min_capacity               = 1
  #   max_capacity               = 5
  #   target_value               = 70.0
  #   scale_in_cooldown_seconds  = 300
  #   scale_out_cooldown_seconds = 60
  # }

  # Enable data capture for model monitoring
  # enable_data_capture     = true
  # data_capture_s3_prefix  = "s3://your-bucket/data-capture/"

  # Enable CloudWatch monitoring
  enable_monitoring = true

  # VPC Configuration (optional - for network isolation)
  # vpc_config = {
  #   subnet_ids         = ["subnet-12345", "subnet-67890"]
  #   security_group_ids = ["sg-12345"]
  # }

  # X-Ray tracing (optional - for debugging)
  # enable_xray_tracing = true

  # Environment variables for your model
  # model_environment_variables = {
  #   MODEL_VERSION = "1.0"
  #   LOG_LEVEL     = "INFO"
  # }

  # Tags for cost allocation and organization
  tags = {
    Project     = "Biti"
    Environment = "Production"
    Team        = "ML-Platform"
    CreatedBy   = "Terraform"
  }
}

# ============================================================
# OUTPUTS - These will display after deployment
# ============================================================

output "my_model_endpoint_name" {
  value       = module.my_pytorch_model.endpoint_name
  description = "Your SageMaker endpoint name"
}

output "my_model_prediction_command" {
  value       = module.my_pytorch_model.prediction_command
  description = "AWS CLI command to test your endpoint"
}

output "my_model_deployment_info" {
  value       = module.my_pytorch_model.deployment_info
  description = "Complete deployment information"
}
```

## Step 4: Deploy the Endpoint

### Initialize Terraform

```bash
cd /workspaces/Biti/infraestructure
terraform init
```

### Plan the Deployment

```bash
# Preview what will be created
terraform plan -out=tfplan
```

This will show you:
- IAM role creation
- SageMaker model creation
- SageMaker endpoint configuration
- CloudWatch alarms

### Review and Approve

```bash
# Read the plan carefully
terraform show tfplan

# Apply the configuration
terraform apply tfplan
```

The deployment will take **2-5 minutes**. You'll see output like:

```
Apply complete! Resources added: 7 deleted: 0, changed: 0.

Outputs:

my_model_endpoint_name = "biti-prod-my-crypto-predictor-endpoint"
my_model_prediction_command = "aws sagemaker-runtime invoke-endpoint --endpoint-name biti-prod-my-crypto-predictor-endpoint ..."
```

### Wait for Endpoint to be "InService"

```bash
# Check endpoint status
aws sagemaker describe-endpoint \
  --endpoint-name biti-prod-my-crypto-predictor-endpoint \
  --query 'EndpointStatus'

# Expected output: "InService" (may take 2-5 minutes)

# Keep checking until status is InService
aws sagemaker describe-endpoint \
  --endpoint-name biti-prod-my-crypto-predictor-endpoint \
  --query 'EndpointStatus' \
  --output text | watch -n 5 'echo "Status: $(cat /dev/stdin)"'
```

## Step 5: Test Your Endpoint

### Prepare Test Data

The format of your test data depends on your model. Common formats:

**JSON (Recommended):**
```json
{
  "instances": [[1.0, 2.0, 3.0, 4.0]],
  "configuration": {"max_length": 100}
}
```

**CSV:**
```csv
feature1,feature2,feature3,feature4
1.0,2.0,3.0,4.0
```

### Method 1: Using AWS CLI

```bash
# Create a test file
cat > test_data.json << 'EOF'
{
  "instances": [[1.0, 2.0, 3.0, 4.0]]
}
EOF

# Invoke the endpoint
aws sagemaker-runtime invoke-endpoint \
  --endpoint-name biti-prod-my-crypto-predictor-endpoint \
  --content-type application/json \
  --body file://test_data.json \
  --region us-east-1 \
  response.json

# View the response
cat response.json
jq . response.json  # Pretty print if response is JSON
```

### Method 2: Using Python (Boto3)

```python
import json
import boto3

# Create client
sagemaker_client = boto3.client('sagemaker-runtime', region_name='us-east-1')

# Prepare input
test_data = {
    "instances": [[1.0, 2.0, 3.0, 4.0]]
}

# Invoke endpoint
response = sagemaker_client.invoke_endpoint(
    EndpointName='biti-prod-my-crypto-predictor-endpoint',
    ContentType='application/json',
    Body=json.dumps(test_data)
)

# Parse response
predictions = json.loads(response['Body'].read())
print("Predictions:", predictions)
```

### Method 3: Using Node.js/JavaScript

```javascript
const AWS = require('aws-sdk');
const sagemaker = new AWS.SageMakerRuntime({region: 'us-east-1'});

const params = {
  EndpointName: 'biti-prod-my-crypto-predictor-endpoint',
  ContentType: 'application/json',
  Body: JSON.stringify({
    instances: [[1.0, 2.0, 3.0, 4.0]]
  })
};

sagemaker.invokeEndpoint(params, (err, data) => {
  if (err) console.error('Error:', err);
  else console.log('Prediction:', JSON.parse(data.Body));
});
```

## Step 6: Monitor Your Endpoint

### View Endpoint Details

```bash
# Get complete endpoint information
aws sagemaker describe-endpoint \
  --endpoint-name biti-prod-my-crypto-predictor-endpoint \
  --query '{
    EndpointName: EndpointName,
    Status: EndpointStatus,
    CreationTime: CreationTime,
    LastModifiedTime: LastModifiedTime,
    InstanceType: ProductionVariants[0].InstanceType,
    CurrentInstanceCount: ProductionVariants[0].CurrentInstanceCount,
    VariantWeights: ProductionVariants[0].VariantWeight
  }' \
  --output table
```

### CloudWatch Metrics

```bash
# View CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/SageMaker \
  --metric-name CPUUtilization \
  --dimensions Name=EndpointName,Value=biti-prod-my-crypto-predictor-endpoint \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum \
  --output table
```

### CloudWatch Logs

```bash
# View latest logs
aws logs tail /aws/sagemaker/biti-prod-my-crypto-predictor-endpoint --follow
```

### CloudWatch Dashboard

Create a dashboard in the AWS Console to visualize:
1. Endpoint Status
2. Invocation Latency
3. Invocation Errors
4. Instance Count (if auto-scaling enabled)
5. Model Latency

### Set Up Alarms

The Terraform module automatically creates alarms for:
- CPU > 80%
- GPU Memory > 85%
- 4XX Errors > 10/min

View alarms:

```bash
# List alarms for your endpoint
aws cloudwatch describe-alarms \
  --query "Alarms[?contains(AlarmName, 'my-crypto-predictor')]" \
  --output table
```

## Cleanup

When you no longer need the endpoint, delete it to avoid costs:

```bash
# Delete all resources
terraform destroy

# Confirm deletion
terraform show  # Should show no resources
```

**⚠️ Important:** Deleting the endpoint will:
- Stop the inference service
- Delete the CloudWatch alarms
- Free up AWS resources
- Stop incurring API costs

Before destroying, consider:
- Exporting important logs
- Saving model performance metrics
- Updating documentation
- Notifying dependent services

```bash
# Export metrics before deletion
aws logs create-export-task \
  --log-group-name /aws/sagemaker/biti-prod-my-crypto-predictor-endpoint \
  --destination s3://your-bucket/logs/
```

## Troubleshooting

### Endpoint stuck in "Creating" status

**Problem:** Endpoint remains in "Creating" for > 10 minutes

**Solutions:**
```bash
# Check for errors
aws sagemaker describe-endpoint --endpoint-name <name> --query 'FailureReason'

# Check IAM role
aws iam get-role --role-name <role-name>

# Verify S3 access
aws s3 ls s3://your-bucket/path/to/model.tar.gz
```

### Model artifact not found

**Problem:** `ValidationException: Could not find model artifact`

**Solution:**
```bash
# Verify S3 URI format
aws s3 ls s3://your-bucket/path/to/model.tar.gz

# Grant read permissions
aws s3api head-object \
  --bucket your-bucket \
  --key path/to/model.tar.gz
```

### Invocation errors

**Problem:** Getting 4XX or 5XX errors when calling endpoint

**Check:**
```bash
# View model logs
aws logs tail /aws/sagemaker/endpoint-name --follow

# Check endpoint health
aws sagemaker describe-endpoint \
  --endpoint-name <name> \
  --query 'ProductionVariants[0].{InstanceType: InstanceType, CurrentInstanceCount: CurrentInstanceCount, Status: CurrentInstanceCount}'
```

## Next Steps

1. **Set up monitoring dashboard** in CloudWatch
2. **Configure auto-scaling** for production workloads
3. **Enable data capture** for model monitoring and drift detection
4. **Create alarm notifications** via SNS
5. **Document your model** and deployment in your project README
6. **Version your Terraform configurations** in git
7. **Test disaster recovery** - practice re-deployment from scratch
8. **Monitor costs** in AWS Cost Explorer

## Additional Resources

- [SageMaker Documentation](https://docs.aws.amazon.com/sagemaker/)
- [Model Architecture & Inference](https://docs.aws.amazon.com/sagemaker/latest/dg/how-it-works-model-architecture.html)
- [Instance Types & Sizing](https://docs.aws.amazon.com/sagemaker/latest/dg/instance-types-general.html)
- [Module README](../modules/sagemaker_model_deployment/README.md)
