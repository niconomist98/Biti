################################################################################
# Integration Example - Lambda, EC2, and S3 Working Together
# Full-stack application: EC2 web + Lambda worker + S3 storage
################################################################################

data "aws_caller_identity" "current" {}
data "aws_vpc" "default" {
  default = true
}
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 1. Create S3 bucket for application data
module "app_storage" {
  source = "../modules/s3"

  bucket_name = "app-storage-${data.aws_caller_identity.current.account_id}"

  # Security
  block_public_access = true
  enable_versioning   = true
  encryption_algorithm = "AES256"
  enable_logging      = true

  # Cost optimization
  lifecycle_rules = [
    {
      id     = "archive_processed"
      status = "Enabled"
      prefix = "processed/"

      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        }
      ]

      expiration_days = 365
    }
  ]

  tags = {
    Application = "integrated-demo"
  }
}

# 2. Create Lambda function for async processing
module "worker_lambda" {
  source = "../modules/lambda"

  function_name = "file-processor"
  source_dir    = "${path.module}/lambda_code/worker"
  runtime       = "python3.11"
  handler       = "processor.handler"
  timeout       = 300  # Long-running
  memory_size   = 1024

  environment_variables = {
    BUCKET_NAME = module.app_storage.bucket_id
    LOG_LEVEL   = "INFO"
  }

  # Allow S3 access
  custom_policies = {
    s3_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:GetObject",
            "s3:PutObject"
          ]
          Effect   = "Allow"
          Resource = "${module.app_storage.bucket_arn}/*"
        }
      ]
    })
  }

  # Scheduled execution
  schedule_expression = "cron(0 */6 * * ? *)"  # Every 6 hours

  # Monitoring
  create_error_alarm   = true
  error_threshold      = 2
  alarm_actions        = [aws_sns_topic.alerts.arn]

  tags = {
    Application = "integrated-demo"
    Role        = "worker"
  }
}

# 3. Create EC2 web server
module "web_app" {
  source = "../modules/ec2"

  instance_name = "web-server"
  vpc_id        = data.aws_vpc.default.id
  subnet_id     = data.aws_subnets.default.ids[0]
  instance_type = "t3.small"

  # Storage
  root_volume_size    = 30
  root_volume_type    = "gp3"
  encrypt_root_volume = true

  # Network
  associate_public_ip = true

  ingress_rules = {
    ssh = {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    http = {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    https = {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  # Allow EC2 to access S3 and invoke Lambda
  custom_policies = {
    s3_read = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:ListBucket"
          ]
          Effect   = "Allow"
          Resource = [
            module.app_storage.bucket_arn,
            "${module.app_storage.bucket_arn}/*"
          ]
        }
      ]
    })

    lambda_invoke = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "lambda:InvokeFunction"
          ]
          Effect   = "Allow"
          Resource = module.worker_lambda.function_arn
        }
      ]
    })

    logs = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Effect   = "Allow"
          Resource = "arn:aws:logs:*:*:*"
        }
      ]
    })
  }

  # Application startup script
  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y python3 python3-pip nodejs
    
    # Install application requirements
    pip3 install boto3 flask
    npm install
    
    # Download and start application
    aws s3 cp s3://${module.app_storage.bucket_id}/app.tar.gz /opt/
    cd /opt
    tar -xzf app.tar.gz
    
    # Start application
    python3 app.py &
  EOF
  )

  # Monitoring
  create_cpu_alarm  = true
  cpu_threshold     = 80
  create_status_alarm = true
  alarm_actions     = [aws_sns_topic.alerts.arn]

  tags = {
    Application = "integrated-demo"
    Role        = "web-server"
  }
}

# SNS topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "integrated-app-alerts"
}

# Outputs - How to use
output "s3_bucket_name" {
  value       = module.app_storage.bucket_id
  description = "S3 bucket for application data"
}

output "lambda_function_name" {
  value       = module.worker_lambda.function_name
  description = "Lambda function for async processing"
}

output "ec2_instance_id" {
  value       = module.web_app.instance_id
  description = "EC2 web server instance"
}

output "ec2_public_ip" {
  value       = module.web_app.instance_public_ip
  description = "EC2 public IP address"
}

output "next_steps" {
  value = <<-EOF
Web Server (EC2):
  1. SSH into the instance:
     ssh -i /path/to/key.pem ec2-user@${module.web_app.instance_public_ip}
  
  2. Application will be running at:
     http://${module.web_app.instance_public_ip}

S3 Bucket:
  Upload files for processing:
    aws s3 cp myfile.txt s3://${module.app_storage.bucket_id}/input/

Lambda Worker:
  Processes files from S3 every 6 hours
  Results written to: s3://${module.app_storage.bucket_id}/processed/

Monitoring:
  Check CloudWatch for Lambda errors, EC2 CPU usage, and S3 metrics
EOF
}
