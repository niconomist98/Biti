################################################################################
# EC2 Module - Advanced Example
# Auto-scaled web application fleet
################################################################################

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Create KMS key for encryption
resource "aws_kms_key" "ebs" {
  description             = "KMS key for EBS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Environment = "production"
  }
}

# Create auto-scaled web server fleet
module "web_fleet" {
  source = "../modules/ec2"

  instance_name = "web-fleet"
  vpc_id        = data.aws_vpc.default.id
  instance_type = "t3.small"

  # Use Ubuntu 22.04 LTS
  ami_owner       = "099720109477"
  ami_filter_name = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]

  # Auto Scaling configuration
  enable_auto_scaling    = true
  asg_subnets            = data.aws_subnets.default.ids
  asg_min_size           = 2
  asg_max_size           = 10
  asg_desired_capacity   = 4
  enable_scaling_policies = true

  # Storage
  root_volume_size    = 50
  root_volume_type    = "gp3"
  encrypt_root_volume = true
  ebs_optimized       = true

  # Additional volumes for application data
  additional_volumes = {
    app_data = {
      size        = 200
      type        = "gp3"
      device_name = "/dev/sdb"
      iops        = 3000
      throughput  = 125
    }
  }

  # Security group rules
  ingress_rules = {
    ssh = {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_ipv4   = "10.0.0.0/8"  # Internal only
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
    app = {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_ipv4   = "10.0.0.0/8"
    }
  }

  # Monitoring
  enable_detailed_monitoring = true
  create_cpu_alarm           = true
  cpu_threshold              = 75
  create_status_alarm        = true
  create_network_alarm       = true
  network_threshold          = 5000000000  # 5 GB

  # CloudWatch alarms
  alarm_actions = [aws_sns_topic.alerts.arn]

  # User data - Install application stack
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    
    echo "Starting instance initialization..."
    
    # Update system
    apt-get update
    apt-get upgrade -y
    
    # Install CloudWatch agent
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
    dpkg -i -E ./amazon-cloudwatch-agent.deb
    
    # Install Docker
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker
    
    # Install application dependencies
    apt-get install -y python3 python3-pip
    
    # Setup logging
    cat > /etc/docker/daemon.json <<'DOCKER'
    {
      "log-driver": "awslogs",
      "log-opts": {
        "awslogs-group": "/ecs/web-fleet",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "docker"
      }
    }
    DOCKER
    
    systemctl restart docker
    
    echo "Instance initialization complete"
  EOF
  )

  # Custom IAM policies for services
  custom_policies = {
    s3_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:GetObject",
            "s3:ListBucket"
          ]
          Effect   = "Allow"
          Resource = [
            "arn:aws:s3:::app-config",
            "arn:aws:s3:::app-config/*"
          ]
        }
      ]
    })

    dynamodb_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "dynamodb:Query",
            "dynamodb:GetItem",
            "dynamodb:PutItem"
          ]
          Effect   = "Allow"
          Resource = "arn:aws:dynamodb:*:*:table/sessions"
        }
      ]
    })

    ecr_access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ecr:GetAuthorizationToken",
            "ecr:BatchGetImage",
            "ecr:GetDownloadUrlForLayer"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })

    cloudwatch_logs = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams"
          ]
          Effect   = "Allow"
          Resource = "arn:aws:logs:*:*:*"
        }
      ]
    })
  }

  tags = {
    Environment = "production"
    Service     = "web-application"
    Team        = "platform"
    AutoScaled  = "true"
  }
}

# SNS topic for alarms
resource "aws_sns_topic" "alerts" {
  name = "ec2-alerts"

  tags = {
    Environment = "production"
  }
}

resource "aws_sns_topic_subscription" "alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "ops-team@example.com"
}

# Outputs
output "asg_name" {
  value = module.web_fleet.asg_name
}

output "asg_min_size" {
  value = module.web_fleet.asg_arn
}

output "security_group_id" {
  value = module.web_fleet.security_group_id
}

output "launch_template_id" {
  value = module.web_fleet.launch_template_id
}
