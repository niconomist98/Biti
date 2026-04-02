# Biti Crypto Forecasting Model Deployment Guide

This guide explains how to deploy Biti's crypto forecasting models to AWS SageMaker using the provided Terraform infrastructure.

## 🎯 Overview

Biti is deploying AI/ML-powered crypto forecasting models on AWS SageMaker. This infrastructure enables:

- ✅ Deploy any crypto forecasting model (PyTorch, TensorFlow, XGBoost)
- ✅ Automatic scaling for variable prediction loads
- ✅ Real-time model monitoring and alerting
- ✅ High availability with multi-az deployment
- ✅ Cost optimization with instance auto-scaling
- ✅ Production-grade security and isolation

## 📋 Prerequisites

### AWS Setup
1. AWS Account with SageMaker service limits
2. S3 bucket for model artifacts: `s3://biti-ml-models/`
3. S3 bucket for data capture: `s3://biti-ml-models/data-capture/`
4. IAM user/role with SageMaker permissions (provided by module)

### Local Setup
```bash
# Install Terraform
brew install terraform  # macOS
# or
apt-get install terraform  # Linux

# Install AWS CLI
pip install awscli

# Configure AWS credentials
aws configure
# Enter: Access Key, Secret Key, Region (us-east-1), Output (json)

# Verify setup
aws sts get-caller-identity
terraform --version
```

### Model Preparation
Your crypto forecasting model must be:
1. Packaged as `model.tar.gz` with proper structure
2. Uploaded to S3 at `s3://biti-ml-models/models/model-name/v1.0/model.tar.gz`
3. Include an `inference.py` script for predictions
4. Include all dependencies in `requirements.txt`

## 🚀 Step-by-Step Deployment

### Step 1: Prepare Your Model Artifact

**Model Structure Example (PyTorch):**
```
model.tar.gz/
├── code/
│   ├── inference.py          # Prediction entry point
│   ├── requirements.txt       # Python dependencies
│   └── utils/
│       └── preprocessing.py   # Helper functions
└── model.pth                  # Trained PyTorch model
```

**Example inference.py for Crypto Price Prediction:**
```python
import json
import torch
import numpy as np
from datetime import datetime

def model_fn(model_dir):
    """Load model from directory"""
    model = torch.load(f"{model_dir}/model.pth")
    model.eval()
    return model

def input_fn(request_body, request_content_type):
    """Parse incoming request"""
    if request_content_type == "application/json":
        input_data = json.loads(request_body)
        # Convert to tensor for your model
        instances = torch.tensor(input_data["instances"])
        return instances
    raise ValueError(f"Unsupported content type: {request_content_type}")

def predict_fn(input_data, model):
    """Make predictions"""
    with torch.no_grad():
        predictions = model(input_data)
    return predictions

def output_fn(predictions, accept):
    """Format output"""
    if accept == "application/json":
        output = {
            "predictions": predictions.tolist(),
            "timestamp": datetime.utcnow().isoformat()
        }
        return json.dumps(output), accept
    raise ValueError(f"Unsupported accept type: {accept}")
```

**Package and Upload:**
```bash
# Create tar.gz
cd /path/to/model
tar -czf model.tar.gz code/ model.pth

# Upload to S3
# For BTC price predictor v1.0
aws s3 cp model.tar.gz s3://biti-ml-models/models/btc-predictor/v1.0/model.tar.gz

# For ETH classifier v1.0
aws s3 cp model.tar.gz s3://biti-ml-models/models/eth-classifier/v1.0/model.tar.gz

# Verify upload
aws s3 ls s3://biti-ml-models/models/
```

### Step 2: Choose Your Framework & Container

**For Crypto Price Prediction (PyTorch):**
```
Framework: pytorch
Version: 2.1
Python: py310
Image: 382416733822.dkr.ecr.us-east-1.amazonaws.com/sagemaker-pytorch:2.1-cpu-py310
```

**For Time Series Forecasting (TensorFlow):**
```
Framework: tensorflow
Version: 2.13
Python: py311
Image: 382416733822.dkr.ecr.us-east-1.amazonaws.com/sagemaker-tensorflow:2.13-cpu-py311
```

**For Classification (XGBoost):**
```
Framework: xgboost
Version: 1.7
Python: py3
Image: 246618743249.dkr.ecr.us-east-1.amazonaws.com/sagemaker-xgboost:1.7-1-cpu-py3
```

### Step 3: Create Deployment Configuration

Create `infraestructure/environments/btc-predictor-prod.tf`:

```hcl
# BTC Price Predictor - Production Deployment

module "btc_predictor" {
  source = "../modules/sagemaker_model_deployment"

  # Basic Configuration
  project_name               = "biti"
  environment                = "prod"
  model_name                 = "btc-price-predictor-v1"
  endpoint_name             = "btc-predictor-prod"
  model_artifact_s3_uri     = "s3://biti-ml-models/models/btc-predictor/v1.0/model.tar.gz"
  model_container_image_uri = "382416733822.dkr.ecr.us-east-1.amazonaws.com/sagemaker-pytorch:2.1-cpu-py310"

  aws_region = "us-east-1"

  # Instance Configuration
  # ml.g4dn.xlarge = 1x NVIDIA T4 GPU for faster inference
  instance_type          = "ml.g4dn.xlarge"
  initial_instance_count = 1

  # Auto-Scaling Configuration
  # Scale up when demand increases, scale down during low traffic
  autoscaling_config = {
    min_capacity               = 1      # Keep at least 1 instance
    max_capacity               = 5      # Max 5 instances
    target_value               = 70.0   # Target 70% invocations per instance
    scale_in_cooldown_seconds  = 600    # Wait 10 min before scaling down
    scale_out_cooldown_seconds = 60     # Wait 1 min before scaling up
  }

  # Monitoring & Data Capture
  enable_monitoring       = true
  enable_data_capture     = true
  data_capture_s3_prefix  = "s3://biti-ml-models/data-capture/btc-predictor/"
  enable_xray_tracing     = true
  
  # Framework Info
  framework         = "pytorch"
  framework_version = "2.1"
  py_version        = "py310"

  # Environment Variables
  model_environment_variables = {
    MODEL_VERSION      = "1.0.0"
    INFERENCE_TIMEOUT  = "30"
    LOG_LEVEL          = "INFO"
  }

  # Tags for cost allocation
  tags = {
    Project     = "Biti"
    Environment = "Production"
    Team        = "ML-Platform"
    Model       = "BTC-Price-Predictor"
    CostCenter  = "Crypto-Forecasting"
  }
}

# Outputs for integration
output "btc_endpoint_name" {
  value       = module.btc_predictor.endpoint_name
  description = "BTC predictor endpoint name for client applications"
}

output "btc_endpoint_arn" {
  value       = module.btc_predictor.endpoint_arn
  description = "BTC predictor endpoint ARN"
}

output "btc_forecast_command" {
  value       = module.btc_predictor.prediction_command
  description = "AWS CLI command to get BTC price predictions"
}
```

### Step 4: Deploy the Infrastructure

```bash
cd /workspaces/Biti/infraestructure

# Initialize Terraform
terraform init

# Review what will be created
terraform plan -var="environment=prod"

# Deploy
terraform apply -var="environment=prod"

# Note the outputs (endpoint name, etc.)
terraform output
```

### Step 5: Verify Deployment

```bash
# Wait for endpoint to be ready (2-5 minutes)
aws sagemaker describe-endpoint \
  --endpoint-name btc-predictor-prod \
  --query 'EndpointStatus'

# Should output: "InService"

# Check endpoint details
aws sagemaker describe-endpoint \
  --endpoint-name btc-predictor-prod \
  --query 'ProductionVariants[0]'
```

### Step 6: Test Predictions

**Using AWS CLI:**
```bash
# Create test data
cat > test_crypto_data.json << 'EOF'
{
  "instances": [
    [45000.50, 2.3, 1.05, 0.8, -0.2],  # [btc_price, volume_change, sentiment, momentum, rsi]
    [45100.25, 1.9, 0.95, 0.7, -0.1]
  ]
}
EOF

# Send prediction request
aws sagemaker-runtime invoke-endpoint \
  --endpoint-name btc-predictor-prod \
  --content-type application/json \
  --body file://test_crypto_data.json \
  --region us-east-1 \
  response.json

# View predictions
cat response.json | jq .
```

**Using Python (Recommended):**
```python
import boto3
import json

client = boto3.client('sagemaker-runtime', region_name='us-east-1')

# Test data
crypto_data = {
    "instances": [
        [45000.50, 2.3, 1.05, 0.8, -0.2],
        [45100.25, 1.9, 0.95, 0.7, -0.1]
    ]
}

# Get predictions
response = client.invoke_endpoint(
    EndpointName='btc-predictor-prod',
    ContentType='application/json',
    Body=json.dumps(crypto_data)
)

# Parse predictions
predictions = json.loads(response['Body'].read())
print("BTC Price Forecast:")
for idx, pred in enumerate(predictions['predictions']):
    print(f"  Scenario {idx + 1}: ${pred[0]:.2f} (confidence: {pred[1]:.2%})")
```

## 📊 Monitoring Your Model

### Real-time Performance

```bash
# CPU Usage
aws cloudwatch get-metric-statistics \
  --namespace AWS/SageMaker \
  --metric-name CPUUtilization \
  --dimensions Name=EndpointName,Value=btc-predictor-prod \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum

# Invocation Latency (time to get prediction)
aws cloudwatch get-metric-statistics \
  --namespace AWS/SageMaker \
  --metric-name ModelLatency \
  --dimensions Name=EndpointName,Value=btc-predictor-prod \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum
```

### Data Drift Detection

Monitor how input data changes over time:

```bash
# List captured data
aws s3 ls s3://biti-ml-models/data-capture/btc-predictor/ --recursive

# Analyze data drift
aws sagemaker describe-data-quality-job-definition \
  --job-definition-name btc-predictor-data-quality
```

### View Logs

```bash
# Follow logs in real-time
aws logs tail /aws/sagemaker/btc-predictor-prod --follow

# Search for errors
aws logs filter-log-events \
  --log-group-name /aws/sagemaker/btc-predictor-prod \
  --filter-pattern "ERROR"
```

## 🔄 Deployment Scenarios

### Scenario 1: Multiple Models (BTC, ETH, ALT coins)

Deploy separate endpoints for each cryptocurrency:

```hcl
# BTC Endpoint
module "btc_model" {
  source                     = "../modules/sagemaker_model_deployment"
  project_name              = "biti"
  environment               = "prod"
  model_name                = "btc-predictor"
  endpoint_name            = "btc-predictor-prod"
  model_artifact_s3_uri    = "s3://biti-ml-models/models/btc/v1.0/model.tar.gz"
  # ... rest of config
}

# ETH Endpoint
module "eth_model" {
  source                     = "../modules/sagemaker_model_deployment"
  project_name              = "biti"
  environment               = "prod"
  model_name                = "eth-predictor"
  endpoint_name            = "eth-predictor-prod"
  model_artifact_s3_uri    = "s3://biti-ml-models/models/eth/v1.0/model.tar.gz"
  # ... rest of config
}

# ALT Endpoint
module "alt_model" {
  source                     = "../modules/sagemaker_model_deployment"
  project_name              = "biti"
  environment               = "prod"
  model_name                = "alt-predictor"
  endpoint_name            = "alt-predictor-prod"
  model_artifact_s3_uri    = "s3://biti-ml-models/models/alt/v1.0/model.tar.gz"
  # ... rest of config
}

output "crypto_endpoints" {
  value = {
    btc = module.btc_model.endpoint_name
    eth = module.eth_model.endpoint_name
    alt = module.alt_model.endpoint_name
  }
}
```

### Scenario 2: Dev/Staging/Prod Environments

```bash
# Deploy to dev (cheap, single instance)
terraform apply -var="environment=dev"

# Deploy to staging (test before prod)
terraform apply -var="environment=staging"

# Deploy to prod (high availability, auto-scaling)
terraform apply -var="environment=prod"
```

### Scenario 3: Model Updates

```bash
# New version of BTC predictor
aws s3 cp new_model.tar.gz s3://biti-ml-models/models/btc/v1.1/model.tar.gz

# Update Terraform
# In btc-predictor-prod.tf, change:
# model_artifact_s3_uri = "s3://biti-ml-models/models/btc/v1.1/model.tar.gz"

# Re-deploy (no downtime, SageMaker handles the update)
terraform apply
```

## 💡 Production Recommendations

### 1. Use GPU for Real-Time Predictions
```hcl
instance_type = "ml.g4dn.xlarge"  # NVIDIA T4 GPU
```

### 2. Enable Complete Monitoring
```hcl
enable_monitoring       = true
enable_data_capture     = true
enable_xray_tracing     = true
```

### 3. Auto-Scale for Variable Load
```hcl
autoscaling_config = {
  min_capacity  = 2   # Always have 2 instances
  max_capacity  = 10  # Up to 10 during peaks
  target_value  = 70.0
}
```

### 4. Set Up Alerting
```hcl
# Automatically creates CloudWatch alarms for:
# - CPU > 80%
# - GPU Memory > 85%
# - Model Errors > 10/min
```

### 5. Version Control Models
```
s3://biti-ml-models/models/
├── btc-predictor/
│   ├── v1.0/
│   ├── v1.1/
│   └── v1.2/
├── eth-predictor/
│   ├── v1.0/
│   └── v1.1/
```

## 📈 Scaling for High Demand

### Current Capacity
- ml.g4dn.xlarge: ~1,000-2,000 predictions/min
- Single instance sustained

### Scale Up
```hcl
autoscaling_config = {
  min_capacity  = 5   # Start with 5 instances
  max_capacity  = 20  # Up to 20
  target_value  = 70.0
}
# Expected: ~10,000-20,000 predictions/min
```

### Scale Out (Regional)
Deploy separate endpoints in different regions:
```hcl
# us-east-1
module "btc_us_east" {
  aws_region = "us-east-1"
  # ...
}

# eu-west-1
module "btc_eu_west" {
  aws_region = "eu-west-1"
  # ...
}

# ap-southeast-1
module "btc_ap_southeast" {
  aws_region = "ap-southeast-1"
  # ...
}
```

## 🆘 Troubleshooting

### Model Endpoint Won't Start
```bash
# Check IAM role permissions
aws iam get-role --role-name biti-prod-sagemaker-role

# Check S3 access
aws s3 head-object \
  --bucket biti-ml-models \
  --key models/btc-predictor/v1.0/model.tar.gz

# View error logs
aws sagemaker describe-endpoint \
  --endpoint-name btc-predictor-prod \
  --query 'FailureReason'
```

### High Latency Predictions
```bash
# Increase instance type
instance_type = "ml.g4dn.2xlarge"  # Dual GPU

# Enable data caching
model_environment_variables = {
  TF_CPP_MIN_LOG_LEVEL = "3"  # Reduce TensorFlow logging
}

# Check CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/SageMaker \
  --metric-name ModelLatency \
  --dimensions Name=EndpointName,Value=btc-predictor-prod \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average
```

### Repeated Predictions Failing
```bash
# Check endpoint health
aws sagemaker describe-endpoint \
  --endpoint-name btc-predictor-prod

# Check CloudWatch logs
aws logs tail /aws/sagemaker/btc-predictor-prod --follow

# Restart endpoint
aws sagemaker update-endpoint \
  --endpoint-name btc-predictor-prod \
  --endpoint-config-name <config-name>
```

## 📚 Additional Resources

- [Module README](../modules/sagemaker_model_deployment/README.md)
- [Deployment Guide](./DEPLOYMENT_GUIDE.md)
- [SageMaker Documentation](https://docs.aws.amazon.com/sagemaker/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)

---

**Happy Deploying! 🚀**

Last Updated: 2024-03-31
