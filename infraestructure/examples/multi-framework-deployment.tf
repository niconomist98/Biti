# Example 4: XGBoost and TensorFlow Model Deployments

# ============================================================
# XGBoost Model - Crypto Price Regression
# ============================================================

module "xgboost_crypto_model" {
  source = "../modules/sagemaker_model_deployment"

  project_name               = "biti"
  environment                = "prod"
  model_name                 = "xgboost-crypto-price"
  endpoint_name             = "xgboost-crypto-price-prod"
  model_artifact_s3_uri     = "s3://biti-ml-models/models/xgboost-crypto/v1.0/model.tar.gz"
  model_container_image_uri = "246618743249.dkr.ecr.us-east-1.amazonaws.com/sagemaker-xgboost:1.7-1-cpu-py3"

  aws_region             = "us-east-1"
  instance_type         = "ml.c5.2xlarge"
  initial_instance_count = 2

  framework         = "xgboost"
  framework_version = "1.7"
  py_version        = "py3"

  autoscaling_config = {
    min_capacity               = 1
    max_capacity               = 8
    target_value               = 70.0
    scale_in_cooldown_seconds  = 300
    scale_out_cooldown_seconds = 60
  }

  enable_monitoring       = true
  enable_data_capture     = true
  data_capture_s3_prefix = "s3://biti-ml-models/data-capture/xgboost/"

  tags = {
    Project     = "Biti"
    Environment = "Production"
    ModelType   = "Regression"
    Framework   = "XGBoost"
  }
}

# ============================================================
# TensorFlow Model - Time Series Forecasting
# ============================================================

module "tensorflow_timeseries_model" {
  source = "../modules/sagemaker_model_deployment"

  project_name               = "biti"
  environment                = "prod"
  model_name                 = "tensorflow-timeseries"
  endpoint_name             = "tensorflow-timeseries-prod"
  model_artifact_s3_uri     = "s3://biti-ml-models/models/tensorflow-timeseries/v1.0/model.tar.gz"
  model_container_image_uri = "382416733822.dkr.ecr.us-east-1.amazonaws.com/sagemaker-tensorflow:2.13-cpu-py311"

  aws_region             = "us-east-1"
  instance_type         = "ml.g4dn.xlarge"  # GPU for TensorFlow inference
  initial_instance_count = 1

  framework         = "tensorflow"
  framework_version = "2.13"
  py_version        = "py311"

  autoscaling_config = {
    min_capacity               = 1
    max_capacity               = 10
    target_value               = 75.0
    scale_in_cooldown_seconds  = 300
    scale_out_cooldown_seconds = 60
  }

  enable_monitoring       = true
  enable_data_capture     = true
  data_capture_s3_prefix = "s3://biti-ml-models/data-capture/tensorflow/"
  enable_xray_tracing     = true

  model_environment_variables = {
    TF_CPP_MIN_LOG_LEVEL = "2"
    CUDA_VISIBLE_DEVICES = "0"
  }

  tags = {
    Project     = "Biti"
    Environment = "Production"
    ModelType   = "TimeSeries"
    Framework   = "TensorFlow"
    Accelerator = "GPU"
  }
}

# ============================================================
# Scikit-Learn Model - Classification
# ============================================================

module "sklearn_classification_model" {
  source = "../modules/sagemaker_model_deployment"

  project_name               = "biti"
  environment                = "dev"
  model_name                 = "sklearn-classifier"
  endpoint_name             = "sklearn-classifier-dev"
  model_artifact_s3_uri     = "s3://biti-ml-models/models/sklearn-classifier/v1.0/model.tar.gz"
  model_container_image_uri = "246618743249.dkr.ecr.us-east-1.amazonaws.com/sagemaker-scikit-learn:1.3-1-cpu-py3"

  aws_region             = "us-east-1"
  instance_type         = "ml.t3.medium"
  initial_instance_count = 1

  framework         = "sklearn"
  framework_version = "1.3"
  py_version        = "py3"

  enable_monitoring = true

  tags = {
    Project     = "Biti"
    Environment = "Development"
    Framework   = "Scikit-Learn"
  }
}

# ============================================================
# Outputs for all models
# ============================================================

output "xgboost_endpoint" {
  value = module.xgboost_crypto_model.endpoint_name
}

output "tensorflow_endpoint" {
  value = module.tensorflow_timeseries_model.endpoint_name
}

output "sklearn_endpoint" {
  value = module.sklearn_classification_model.endpoint_name
}

output "all_endpoints" {
  value = {
    xgboost    = module.xgboost_crypto_model.endpoint_name
    tensorflow = module.tensorflow_timeseries_model.endpoint_name
    sklearn    = module.sklearn_classification_model.endpoint_name
  }
}
