# Biti Infrastructure - SageMaker Model Deployment

Complete Terraform infrastructure for deploying machine learning models to AWS SageMaker on Biti's crypto forecasting network.

## 📋 Overview

This infrastructure package provides production-ready Terraform code to deploy ML models to AWS SageMaker with:

- ✅ **Automated model deployment** with minimal configuration
- ✅ **Production-grade security** with fine-grained IAM policies
- ✅ **Auto-scaling** for variable workloads
- ✅ **Comprehensive monitoring** with CloudWatch alarms
- ✅ **Data capture** for model monitoring and drift detection
- ✅ **VPC integration** for network isolation
- ✅ **Multi-framework support** (PyTorch, TensorFlow, XGBoost, etc.)

## 🗂️ Directory Structure

```
infraestructure/
├── modules/
│   └── sagemaker_model_deployment/     # Main SageMaker Terraform module
│       ├── main.tf                     # SageMaker resources (model, endpoint, config, alarms)
│       ├── iam.tf                      # IAM roles and policies
│       ├── variables.tf                # Input variables with validation
│       ├── outputs.tf                  # Output values
│       └── README.md                   # Detailed module documentation
│
├── examples/
│   ├── DEPLOYMENT_GUIDE.md             # Step-by-step deployment guide
│   ├── basic-deployment.tf             # Basic PyTorch model deployment
│   ├── production-deployment.tf        # Production setup with auto-scaling
│   ├── vpc-isolated-deployment.tf      # VPC-isolated deployment
│   ├── multi-framework-deployment.tf   # PyTorch, TensorFlow, XGBoost examples
│   ├── test_endpoint.py               # Python script to test endpoints
│   └── terraform.tfvars.example       # Example configuration file
│
├── environments/
│   └── (Your deployment configs go here)
│
└── README.md                           # This file
```

## 🚀 Quick Start

### 1. Prerequisites

```bash
# Install required tools
terraform --version  # >= 1.0
aws --version        # AWS CLI v2
python3 --version    # >= 3.8 (for testing script)

# Configure AWS credentials
aws configure

# Verify access
aws sts get-caller-identity
```

### 2. Prepare Your Model

Your model must be packaged as `model.tar.gz` on S3:

```bash
# Example with PyTorch
tar -czf model.tar.gz code/ model.pth
aws s3 cp model.tar.gz s3://my-bucket/models/model.tar.gz
```

### 3. Create Deployment Configuration

```bash
# Copy the example configuration
cp examples/basic-deployment.tf environments/my-model.tf

# Edit with your model details
# - Update model_name, endpoint_name
# - Set model_artifact_s3_uri to your S3 location
# - Set model_container_image_uri (see examples/)
```

### 4. Deploy

```bash
# Initialize Terraform
cd /workspaces/Biti/infraestructure
terraform init

# Review deployment plan
terraform plan

# Deploy
terraform apply

# Get outputs
terraform output
```

### 5. Test Your Endpoint

```bash
# Using AWS CLI
aws sagemaker-runtime invoke-endpoint \
  --endpoint-name <endpoint-name> \
  --content-type application/json \
  --body '{"instances": [[1.0, 2.0, 3.0]]}' \
  response.json

# Using Python script
python examples/test_endpoint.py --endpoint-name <endpoint-name> --info
python examples/test_endpoint.py --endpoint-name <endpoint-name> --payload data.json
```

## 📖 Documentation

### For First-Time Users
- Start with [DEPLOYMENT_GUIDE.md](examples/DEPLOYMENT_GUIDE.md)
- Contains step-by-step instructions and troubleshooting

### For Module Details
- Read [modules/sagemaker_model_deployment/README.md](modules/sagemaker_model_deployment/README.md)
- Comprehensive reference for all features and configuration options

### Example Configurations
- **Basic**: [basic-deployment.tf](examples/basic-deployment.tf) - Simple production deployment
- **Production**: [production-deployment.tf](examples/production-deployment.tf) - Auto-scaling and monitoring
- **VPC**: [vpc-isolated-deployment.tf](examples/vpc-isolated-deployment.tf) - Network isolation
- **Multi-Framework**: [multi-framework-deployment.tf](examples/multi-framework-deployment.tf) - PyTorch, TensorFlow, XGBoost

## 🔧 Common Tasks

### Deploy a PyTorch Model

```hcl
module "my_model" {
  source = "./modules/sagemaker_model_deployment"

  project_name               = "biti"
  environment                = "prod"
  model_name                 = "my-predictor"
  endpoint_name             = "my-predictor-endpoint"
  model_artifact_s3_uri     = "s3://my-bucket/model.tar.gz"
  model_container_image_uri = "382416733822.dkr.ecr.us-east-1.amazonaws.com/sagemaker-pytorch:2.1-cpu-py310"
}
```

### Enable Auto-Scaling

```hcl
autoscaling_config = {
  min_capacity               = 1
  max_capacity               = 10
  target_value               = 70.0
  scale_in_cooldown_seconds  = 300
  scale_out_cooldown_seconds = 60
}
```

### Deploy in VPC

```hcl
vpc_config = {
  subnet_ids         = ["subnet-12345", "subnet-67890"]
  security_group_ids = ["sg-12345"]
}
```

### Enable Data Capture for Monitoring

```hcl
enable_data_capture        = true
data_capture_s3_prefix    = "s3://my-bucket/data-capture/"
```

## 📊 Supported Frameworks

All major ML frameworks are supported:

| Framework | Image URL | CPU | GPU |
|-----------|-----------|-----|-----|
| PyTorch | `sagemaker-pytorch:2.1-cpu-py310` | ✅ | ✅ |
| TensorFlow | `sagemaker-tensorflow:2.13-cpu-py311` | ✅ | ✅ |
| XGBoost | `sagemaker-xgboost:1.7-1-cpu-py3` | ✅ | - |
| Scikit-Learn | `sagemaker-scikit-learn:1.3-1-cpu-py3` | ✅ | - |
| MXNet | `sagemaker-mxnet:1.8-cpu-py37` | ✅ | ✅ |

See [SageMaker Algorithm Registry](https://docs.aws.amazon.com/sagemaker/latest/dg/sagemaker-algo-docker-registry-paths.html) for complete list and regional URIs.

## 🔐 Security Features

The module includes comprehensive security:

- ✅ **Fine-grained IAM policies** - S3, CloudWatch, VPC, ECR access
- ✅ **VPC support** - Deploy in isolated networks
- ✅ **Encryption** - KMS keys for data at rest
- ✅ **Audit logging** - CloudWatch Logs and X-Ray tracing
- ✅ **Resource tags** - Full cost allocation and governance

## 💡 Best Practices

1. **Use environment-specific configurations**
   ```bash
   environments/model-dev.tf
   environments/model-staging.tf
   environments/model-prod.tf
   ```

2. **Version your models in S3**
   ```
   s3://bucket/models/model-name/v1.0/model.tar.gz
   s3://bucket/models/model-name/v1.1/model.tar.gz
   ```

3. **Enable monitoring for production**
   ```hcl
   enable_monitoring = true
   enable_data_capture = true
   enable_xray_tracing = true
   ```

4. **Use auto-scaling for variable workloads**
   ```hcl
   autoscaling_config = {
     min_capacity = 1
     max_capacity = 10
   }
   ```

5. **Tag resources consistently**
   ```hcl
   tags = {
     Project     = "Biti"
     Environment = "Production"
     Team        = "ML-Platform"
   }
   ```

## 📈 Monitoring

The module automatically creates CloudWatch alarms for:

- **CPU Utilization** > 80%
- **GPU Memory** > 85%
- **Model Invocation Errors** > 10/min

View metrics in AWS CloudWatch or via CLI:

```bash
# View CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/SageMaker \
  --metric-name CPUUtilization \
  --dimensions Name=EndpointName,Value=<endpoint-name> \
  --start-time 2024-03-31T00:00:00Z \
  --end-time 2024-04-01T00:00:00Z \
  --period 300 \
  --statistics Average,Maximum
```

## 💰 Cost Estimation

Example monthly costs (us-east-1, 730 hours/month):

| Instance Type | Hourly | Monthly |
|---------------|--------|---------|
| ml.t3.medium (CPU) | $0.042 | $30 |
| ml.t3.xlarge (CPU) | $0.166 | $121 |
| ml.g4dn.xlarge (GPU) | $0.526 | $384 |
| ml.p3.2xlarge (GPU) | $3.06 | $2,234 |

Plus data transfer and CloudWatch monitoring (~$10-50/month).

## 🆘 Troubleshooting

### Endpoint stuck in "Creating"
```bash
# Check for error reasons
aws sagemaker describe-endpoint \
  --endpoint-name <name> \
  --query 'FailureReason'
```

### Model artifact not found
```bash
# Verify S3 URI
aws s3 ls s3://your-bucket/path/to/model.tar.gz

# Test IAM permissions
aws s3 head-object \
  --bucket your-bucket \
  --key path/to/model.tar.gz
```

### Invocation errors
```bash
# View model logs
aws logs tail /aws/sagemaker/<endpoint-name> --follow

# Check endpoint health
aws sagemaker describe-endpoint \
  --endpoint-name <name> \
  --query 'ProductionVariants[0]'
```

See [DEPLOYMENT_GUIDE.md](examples/DEPLOYMENT_GUIDE.md) for more troubleshooting.

## 🔄 Updating Your Model

To update an existing deployment:

1. **New model version**: Version your artifact in S3
   ```bash
   aws s3 cp model.tar.gz s3://bucket/models/model-name/v1.1/model.tar.gz
   ```

2. **Update Terraform**
   ```hcl
   model_artifact_s3_uri = "s3://bucket/models/model-name/v1.1/model.tar.gz"
   ```

3. **Re-deploy**
   ```bash
   terraform apply
   ```

The old endpoint will be updated with new model in ~5 minutes with zero downtime (SageMaker handles this).

## 🗑️ Cleanup

Remove all resources:

```bash
# Check what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Confirm removal
terraform show
```

## 📚 Additional Resources

- [AWS SageMaker Documentation](https://docs.aws.amazon.com/sagemaker/)
- [SageMaker Best Practices](https://docs.aws.amazon.com/sagemaker/latest/dg/best-practices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Model Package Groups](https://docs.aws.amazon.com/sagemaker/latest/dg/model-registry.html)
- [SageMaker Pipelines](https://docs.aws.amazon.com/sagemaker/latest/dg/pipelines.html)

## 💬 Getting Help

1. **Review the documentation**
   - [DEPLOYMENT_GUIDE.md](examples/DEPLOYMENT_GUIDE.md) - Step-by-step guide
   - [Module README](modules/sagemaker_model_deployment/README.md) - Complete reference

2. **Check examples**
   - [basic-deployment.tf](examples/basic-deployment.tf)
   - [production-deployment.tf](examples/production-deployment.tf)
   - [multi-framework-deployment.tf](examples/multi-framework-deployment.tf)

3. **Test your endpoint**
   ```bash
   python examples/test_endpoint.py --endpoint-name <name> --info
   ```

4. **Check logs**
   ```bash
   aws logs tail /aws/sagemaker/<endpoint-name> --follow
   ```

## 📝 License

This infrastructure code is part of the Biti project. See LICENSE for details.

## 🤝 Contributing

To contribute improvements:

1. Test changes in dev environment
2. Update documentation
3. Follow Terraform best practices
4. Add examples for new features
5. Submit pull request with clear description

---

**Last Updated:** 2024-03-31
**Terraform Version:** >= 1.0
**AWS Provider Version:** >= 5.0
