################################################################################
# EC2 Module - Basic Example
# Single web server instance
################################################################################

# Get the default VPC or reference an existing one
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Create a web server instance
module "web_server" {
  source = "../modules/ec2"

  instance_name = "web-server-01"
  vpc_id        = data.aws_vpc.default.id
  subnet_id     = data.aws_subnets.default.ids[0]
  instance_type = "t3.micro"

  # Use default Ubuntu 22.04 AMI
  ami_owner          = "099720109477"
  ami_filter_name    = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]

  # Storage configuration
  root_volume_size = 20
  root_volume_type = "gp3"
  encrypt_root_volume = true

  # Network configuration
  associate_public_ip = true
  allocate_elastic_ip = false

  # Security group ingress rules
  ingress_rules = {
    ssh = {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_ipv4   = "0.0.0.0/0"  # Restrict this in production!
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

  # Monitoring
  enable_detailed_monitoring = false  # Extra cost if enabled
  create_cpu_alarm           = true
  cpu_threshold              = 80
  create_status_alarm        = true

  # User data script
  user_data = file("${path.module}/user_data.sh")

  tags = {
    Environment = "development"
    Service     = "web"
    Owner       = "devops-team"
  }
}

# Outputs
output "instance_id" {
  value = module.web_server.instance_id
}

output "instance_public_ip" {
  value = module.web_server.instance_public_ip
}

output "instance_private_ip" {
  value = module.web_server.instance_private_ip
}

output "security_group_id" {
  value = module.web_server.security_group_id
}

output "connection_string" {
  value = module.web_server.connection_string
}
