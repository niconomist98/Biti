################################################################################
# EC2 Module - Input Variables
################################################################################

variable "instance_name" {
  description = "Name for the EC2 instance"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,255}$", var.instance_name))
    error_message = "Instance name must be 1-255 alphanumeric characters, hyphens, and underscores."
  }
}

variable "vpc_id" {
  description = "VPC ID where the instance will be launched"
  type        = string

  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "VPC ID must start with 'vpc-'."
  }
}

variable "subnet_id" {
  description = "Subnet ID for the instance (single instance only)"
  type        = string
  default     = null

  validation {
    condition     = var.subnet_id == null || can(regex("^subnet-", var.subnet_id))
    error_message = "Subnet ID must start with 'subnet-'."
  }
}

variable "instance_type" {
  description = "EC2 instance type (e.g., t3.medium, t4g.large, m5.xlarge)"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*\\.[a-z0-9]+$", var.instance_type))
    error_message = "Instance type format must be valid (e.g., t3.micro)."
  }
}

variable "ami_id" {
  description = "AMI ID to use (overrides ami_filter_name)"
  type        = string
  default     = null

  validation {
    condition     = var.ami_id == null || can(regex("^ami-", var.ami_id))
    error_message = "AMI ID must start with 'ami-'."
  }
}

variable "ami_owner" {
  description = "AMI owner account ID"
  type        = string
  default     = "099720109477"  # Canonical (Ubuntu)
}

variable "ami_filter_name" {
  description = "AMI filter name pattern"
  type        = list(string)
  default     = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = null
}

variable "associate_public_ip" {
  description = "Associate a public IP address"
  type        = bool
  default     = false
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8
    error_message = "Root volume size must be at least 8 GB."
  }
}

variable "root_volume_type" {
  description = "Root volume type (gp3, gp2, io1, io2)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2", "st1", "sc1"], var.root_volume_type)
    error_message = "Volume type must be gp3, gp2, io1, io2, st1, or sc1."
  }
}

variable "encrypt_root_volume" {
  description = "Encrypt the root volume"
  type        = bool
  default     = true
}

variable "ebs_optimized" {
  description = "Enable EBS optimization"
  type        = bool
  default     = true
}

variable "additional_volumes" {
  description = "Additional EBS volumes to attach"
  type = map(object({
    size        = number
    type        = string
    device_name = string
    iops        = optional(number)
    throughput  = optional(number)
  }))
  default = null
}

variable "cpu_credits" {
  description = "CPU credits for T-family instances (standard or unlimited)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "unlimited"], var.cpu_credits)
    error_message = "CPU credits must be standard or unlimited."
  }
}

variable "enable_hibernation" {
  description = "Enable hibernation"
  type        = bool
  default     = false
}

variable "require_imds_token" {
  description = "Require IMDSv2 token (recommended for security)"
  type        = bool
  default     = true
}

variable "user_data" {
  description = "User data script to run on launch"
  type        = string
  default     = null
}

variable "ingress_rules" {
  description = "Ingress rules for security group"
  type = map(object({
    from_port              = number
    to_port                = number
    protocol               = string
    cidr_ipv4              = optional(string)
    source_security_group_id = optional(string)
  }))
  default = {
    ssh = {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    http = {
      from_port = 80
      to_port   = 80
      protocol  = "tcp"
      cidr_ipv4 = "0.0.0.0/0"
    }
    https = {
      from_port = 443
      to_port   = 443
      protocol  = "tcp"
      cidr_ipv4 = "0.0.0.0/0"
    }
  }
}

variable "allocate_elastic_ip" {
  description = "Allocate an Elastic IP address"
  type        = bool
  default     = false
}

variable "create_cpu_alarm" {
  description = "Create CloudWatch alarm for CPU utilization"
  type        = bool
  default     = true
}

variable "cpu_threshold" {
  description = "CPU utilization threshold for alarm (%)"
  type        = number
  default     = 80

  validation {
    condition     = var.cpu_threshold > 0 && var.cpu_threshold <= 100
    error_message = "CPU threshold must be between 0 and 100."
  }
}

variable "create_status_alarm" {
  description = "Create CloudWatch alarm for instance status checks"
  type        = bool
  default     = true
}

variable "create_network_alarm" {
  description = "Create CloudWatch alarm for network traffic"
  type        = bool
  default     = false
}

variable "network_threshold" {
  description = "Network threshold in bytes for alarm"
  type        = number
  default     = 1000000000  # 1 GB
}

variable "create_composite_alarm" {
  description = "Create composite alarm for overall instance health"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "SNS topic ARNs for alarm actions"
  type        = list(string)
  default     = []
}

variable "enable_auto_scaling" {
  description = "Enable Auto Scaling Group instead of single instance"
  type        = bool
  default     = false
}

variable "asg_subnets" {
  description = "Subnets for Auto Scaling Group"
  type        = list(string)
  default     = null
}

variable "asg_min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1

  validation {
    condition     = var.asg_min_size >= 1
    error_message = "Minimum size must be at least 1."
  }
}

variable "asg_max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 3

  validation {
    condition     = var.asg_max_size >= 1
    error_message = "Maximum size must be at least 1."
  }
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 1

  validation {
    condition     = var.asg_desired_capacity >= 1
    error_message = "Desired capacity must be at least 1."
  }
}

variable "enable_scaling_policies" {
  description = "Enable CPU-based scaling policies"
  type        = bool
  default     = false
}

variable "cloudwatch_config" {
  description = "CloudWatch agent configuration (JSON)"
  type        = string
  default     = null
}

variable "custom_policies" {
  description = "Map of custom IAM policies to attach"
  type        = map(string)
  default     = null
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
