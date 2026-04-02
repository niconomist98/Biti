variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

# Upload Glue script to S3
resource "aws_s3_object" "glue_script" {
  bucket = "biti-data-${var.environment}"
  key    = "scripts/etl_job.py"
  source = "${path.module}/../../../src/glue/etl_job.py"
  etag   = filemd5("${path.module}/../../../src/glue/etl_job.py")
}

# Glue Job Deployment
module "biti_glue" {
  source = "../../modules/glue"

  job_name        = "biti-crypto-etl-${var.environment}"
  script_location = "s3://${aws_s3_object.glue_script.bucket}/${aws_s3_object.glue_script.key}"

  s3_access_arns = [
    "arn:aws:s3:::biti-data-${var.environment}",
    "arn:aws:s3:::biti-data-${var.environment}/*"
  ]

  default_arguments = {
    "--INPUT_PATH"        = "s3://biti-data-${var.environment}/raw/"
    "--OUTPUT_PATH"       = "s3://biti-data-${var.environment}/hudi/crypto_klines/"
    "--datalake-formats"  = "hudi"
  }

  create_failure_alarm  = false
  create_duration_alarm = false

  tags = {
    Project     = "Biti"
    Environment = var.environment
  }
}

output "glue_job_name" {
  value = module.biti_glue.job_name
}

output "glue_job_arn" {
  value = module.biti_glue.job_arn
}