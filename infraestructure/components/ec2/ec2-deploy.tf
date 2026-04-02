variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}
# EC2 Instance Deployment - Test

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "biti_ec2" {
  source = "../../modules/ec2"

  instance_name = "biti-test"
  vpc_id        = data.aws_vpc.default.id
  subnet_id     = data.aws_subnets.default.ids[0]
  instance_type = "t3.micro"

  root_volume_size    = 8
  associate_public_ip = true

  create_cpu_alarm       = false
  create_status_alarm    = false
  create_composite_alarm = false

  tags = {
    Project     = "Biti"
    Environment = var.environment
  }
}

output "ec2_instance_id" {
  value = module.biti_ec2.instance_id
}

output "ec2_public_ip" {
  value = module.biti_ec2.instance_public_ip
}

output "ec2_connection" {
  value = module.biti_ec2.connection_string
}
