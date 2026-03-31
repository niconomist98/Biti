# AWS EC2 Module

Comprehensive Terraform module for deploying EC2 instances with complete networking, storage, security, monitoring, and auto-scaling capabilities.

## Features

✅ **Instance Management**
- Support for all instance types and generations
- Latest AMI auto-discovery (Ubuntu, Amazon Linux, Windows)
- Custom AMI support
- Configurable storage with EBS encryption
- Additional EBS volumes support

✅ **Security & Access Control**
- Dedicated IAM execution role
- AWS Systems Manager Session Manager access
- SSH key pair support
- Customizable security groups with ingress/egress rules
- IMDSv2 enforcement option

✅ **High Availability**
- Elastic IP address support
- Auto Scaling Group integration
- Health check configuration
- Rolling instance refresh
- CloudWatch monitoring

✅ **Monitoring & Logging**
- CloudWatch Logs integration
- CPU utilization alarms
- Instance status check alarms
- Network traffic alarms
- Composite health alarms
- CloudWatch agent support

✅ **Networking**
- VPC integration
- Security group management
- Multi-subnet support (ASG)
- Elastic IP assignment

✅ **Performance**
- EBS optimization
- CPU credit options (T-family)
- Hibernation support (if supported)
- IMDSv2 security

## Module Structure

```
ec2/
├── main.tf           # Core EC2 resources and orchestration
├── iam.tf            # IAM roles, policies, and examples
├── variables.tf      # Input parameters with validation
├── outputs.tf        # Output values
└── README.md         # This file
```

## Usage

### Basic Example - Single Instance

```hcl
module "web_server" {
  source = "./modules/ec2"

  instance_name = "web-server-01"
  vpc_id        = aws_vpc.main.id
  subnet_id     = aws_subnet.public.id
  instance_type = "t3.medium"

  tags = {
    Environment = "production"
    Owner       = "platform-team"
  }
}
```

### Web Server with Custom Security Rules

```hcl
module "web_server" {
  source = "./modules/ec2"

  instance_name = "web-server"
  vpc_id        = aws_vpc.main.id
  subnet_id     = aws_subnet.public.id
  instance_type = "t3.large"
  key_name      = aws_key_pair.main.key_name

  ingress_rules = {
    ssh = {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_ipv4   = "10.0.0.0/8"
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

  associate_public_ip = true
  allocate_elastic_ip = true
}
```

### Database Server with Additional Storage

```hcl
module "db_server" {
  source = "./modules/ec2"

  instance_name = "database-server"
  vpc_id        = aws_vpc.main.id
  subnet_id     = aws_subnet.private.id
  instance_type = "m5.2xlarge"

  root_volume_size = 50
  root_volume_type = "gp3"

  additional_volumes = {
    data = {
      size        = 500
      type        = "gp3"
      device_name = "/dev/sdb"
      iops        = 16000
      throughput  = 1000
    }
    logs = {
      size        = 200
      type        = "gp3"
      device_name = "/dev/sdc"
    }
  }

  ingress_rules = {
    postgres = {
      from_port               = 5432
      to_port                 = 5432
      protocol                = "tcp"
      source_security_group_id = aws_security_group.app.id
    }
  }
}
```

### Auto Scaling Group

```hcl
module "web_fleet" {
  source = "./modules/ec2"

  instance_name = "web-fleet"
  vpc_id        = aws_vpc.main.id
  instance_type = "t3.medium"

  enable_auto_scaling    = true
  asg_subnets            = aws_subnet.web[*].id
  asg_min_size           = 2
  asg_max_size           = 10
  asg_desired_capacity   = 4
  enable_scaling_policies = true

  root_volume_size = 30
  root_volume_type = "gp3"

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
  EOF
  )

  tags = {
    Service = "web"
  }
}
```

### Monitor Server with Custom IAM Policy

```hcl
module "monitoring_server" {
  source = "./modules/ec2"

  instance_name = "monitoring"
  vpc_id        = aws_vpc.main.id
  subnet_id     = aws_subnet.private.id
  instance_type = "t3.medium"

  enable_detailed_monitoring = true

  custom_policies = {
    cloudwatch_write = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "cloudwatch:PutMetricData",
            "cloudwatch:PutMetricAlarm",
            "cloudwatch:DescribeAlarms"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
    ec2_describe = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ec2:DescribeInstances",
            "ec2:DescribeTags",
            "ec2:DescribeSecurityGroups"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}
```

### Development Instance with Session Manager

```hcl
module "dev_instance" {
  source = "./modules/ec2"

  instance_name = "dev-workspace"
  vpc_id        = aws_vpc.main.id
  subnet_id     = aws_subnet.private.id
  instance_type = "t3.large"

  # No SSH key - use Session Manager instead
  key_name = null

  ingress_rules = {
    # Allow only from specific security group
    app_access = {
      from_port               = 3000
      to_port                 = 3000
      protocol                = "tcp"
      source_security_group_id = aws_security_group.alb.id
    }
  }

  create_cpu_alarm  = false
  create_status_alarm = false
}
```

### Production Database with Full Monitoring

```hcl
module "prod_db" {
  source = "./modules/ec2"

  instance_name = "production-database"
  vpc_id        = aws_vpc.main.id
  subnet_id     = aws_subnet.db_primary.id
  instance_type = "r6i.4xlarge"
  key_name      = aws_key_pair.prod.key_name

  root_volume_size  = 100
  root_volume_type  = "io2"
  encrypt_root_volume = true
  ebs_optimized     = true

  additional_volumes = {
    data = {
      size   = 1000
      type   = "io2"
      device_name = "/dev/sdb"
      iops   = 64000
    }
    backup = {
      size   = 2000
      type   = "st1"
      device_name = "/dev/sdc"
    }
  }

  enable_detailed_monitoring = true

  create_cpu_alarm      = true
  cpu_threshold         = 85

  create_status_alarm   = true
  create_network_alarm  = true
  network_threshold     = 5000000000

  create_composite_alarm = true
  alarm_actions         = [aws_sns_topic.critical_alerts.arn]

  tags = {
    Environment = "production"
    Service     = "database"
    Criticality = "critical"
  }
}
```

## Input Variables

### Required

| Name | Type | Description |
|------|------|-------------|
| `instance_name` | string | Name for the EC2 instance |
| `vpc_id` | string | VPC ID where instance launches |

### Optional - Instance Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `instance_type` | string | t3.micro | EC2 instance type |
| `ami_id` | string | null | Custom AMI ID (overrides filter) |
| `ami_owner` | string | 099720109477 | AMI owner account ID |
| `ami_filter_name` | list(string) | Ubuntu 22.04 | AMI filter pattern |
| `key_name` | string | null | SSH key pair name |
| `subnet_id` | string | null | Subnet ID (single instance) |

### Optional - Storage Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `root_volume_size` | number | 20 | Root volume size in GB |
| `root_volume_type` | string | gp3 | Volume type (gp3, gp2, io1, io2) |
| `encrypt_root_volume` | bool | true | Encrypt the root volume |
| `ebs_optimized` | bool | true | Enable EBS optimization |
| `additional_volumes` | map(object) | null | Additional EBS volumes |
| `cpu_credits` | string | standard | T-family CPU credits |
| `enable_hibernation` | bool | false | Enable hibernation |

### Optional - Networking & Security

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `ingress_rules` | map(object) | SSH/HTTP/HTTPS | Security group ingress rules |
| `associate_public_ip` | bool | false | Assign public IP address |
| `allocate_elastic_ip` | bool | false | Allocate Elastic IP |
| `require_imds_token` | bool | true | Require IMDSv2 token |

### Optional - Monitoring

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `enable_detailed_monitoring` | bool | false | Enable CloudWatch detail monitoring |
| `create_cpu_alarm` | bool | true | Create CPU alarm |
| `cpu_threshold` | number | 80 | CPU alarm threshold (%) |
| `create_status_alarm` | bool | true | Create instance status alarm |
| `create_network_alarm` | bool | false | Create network traffic alarm |
| `network_threshold` | number | 1000000000 | Network alarm threshold (bytes) |
| `create_composite_alarm` | bool | true | Create composite health alarm |
| `alarm_actions` | list(string) | [] | SNS topic ARNs for alarms |
| `cloudwatch_config` | string | null | CloudWatch agent config (JSON) |

### Optional - Auto Scaling

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `enable_auto_scaling` | bool | false | Enable Auto Scaling Group |
| `asg_subnets` | list(string) | null | ASG subnets |
| `asg_min_size` | number | 1 | Minimum ASG size |
| `asg_max_size` | number | 3 | Maximum ASG size |
| `asg_desired_capacity` | number | 1 | Desired ASG capacity |
| `enable_scaling_policies` | bool | false | Enable CPU-based scaling |

### Optional - Advanced

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `user_data` | string | null | Initialization script |
| `custom_policies` | map(string) | null | Custom IAM policies |
| `tags` | map(string) | {} | Resource tags |

## Outputs

| Name | Description |
|------|-------------|
| `instance_id` | Instance ID |
| `instance_arn` | Instance ARN |
| `instance_private_ip` | Private IP address |
| `instance_public_ip` | Public IP address |
| `instance_public_dns` | Public DNS name |
| `instance_private_dns` | Private DNS name |
| `instance_availability_zone` | Availability zone |
| `instance_primary_network_interface_id` | ENI ID |
| `security_group_id` | Security group ID |
| `security_group_arn` | Security group ARN |
| `elastic_ip` | Elastic IP address |
| `elastic_ip_id` | Elastic IP allocation ID |
| `role_arn` | IAM role ARN |
| `role_name` | IAM role name |
| `instance_profile_arn` | Instance profile ARN |
| `instance_profile_name` | Instance profile name |
| `additional_volume_ids` | Additional EBS volume IDs |
| `asg_name` | Auto Scaling Group name |
| `asg_arn` | Auto Scaling Group ARN |
| `launch_template_id` | Launch template ID |
| `connection_string` | SSH connection string |
| `cpu_alarm_arn` | CPU alarm ARN |
| `status_alarm_arn` | Status alarm ARN |
| `network_alarm_arn` | Network alarm ARN |
| `composite_alarm_arn` | Composite alarm ARN |

## Common Instance Types

### General Purpose (Most Common)
- **t3.micro** - Free tier, burstable (low usage)
- **t3.small / t3.medium** - Development, small apps
- **m5.large / m5.xlarge** - Production web apps
- **m6i.large** - Latest generation, cost optimized

### Compute Optimized (High CPU)
- **c5.large / c5.xlarge** - Web servers, batch processing
- **c6i.2xlarge** - High-performance computing

### Memory Optimized (Database/Cache)
- **r5.large / r5.4xlarge** - Databases, in-memory caches
- **r6i.4xlarge** - High-performance databases

### Storage Optimized (IOPS Heavy)
- **i3.large** - NoSQL databases, data warehousing
- **i4i.2xlarge** - Sequential I/O intensive workloads

### ARM-based (Cost Savings)
- **t4g.medium** - General purpose, 19% cheaper
- **m6g.large** - Latest ARM, same performance

## Cost Estimation

### On-Demand Pricing (US East 1)

| Instance | Hourly | Monthly (730h) |
|----------|--------|----------------|
| t3.micro | $0.0104 | $7.59 |
| t3.medium | $0.0416 | $30.37 |
| m5.large | $0.096 | $70.08 |
| m5.xlarge | $0.192 | $140.16 |
| c5.large | $0.085 | $62.05 |
| r5.large | $0.126 | $91.98 |

**Savings with:**
- Reserved Instances: 30-66% discount
- Spot Instances: 60-90% discount
- ARM-based (t4g): 19% cheaper

## Best Practices

### 1. Security
- Use IMDSv2 (enabled by default)
- Minimize security group rules
- Use Session Manager instead of SSH when possible
- Encrypt EBS volumes
- Use IAM roles for service access

### 2. Performance
- Choose correct instance type before optimizing
- Use EBS-optimized instances for database workloads
- For T-family, use "unlimited" CPU credits for consistent performance
- Use gp3 volumes (better performance/cost than gp2)

### 3. Monitoring & Alerting
- Enable CloudWatch monitoring
- Set up alarms for CPU, network, and status checks
- Monitor disk space with CloudWatch agent
- Track instance costs

### 4. High Availability
- Use Auto Scaling Group for resilience
- Distribute across availability zones
- Use Elastic IPs for static addresses
- Implement health checks

### 5. Scaling
- Start with ASG min=2, max=10
- Scale based on CPU (70% threshold)
- Use spot instances for non-critical workloads
- Monitor and adjust based on usage patterns

## Troubleshooting

### Instance Won't Start
- Check IAM role permissions
- Verify subnet has available IPs
- Check security group allows necessary traffic
- Verify AMI is available in your region

### Can't Connect via SSH
- Verify key pair name is correct
- Check security group allows SSH (port 22)
- Verify public IP is assigned (if needed)
- Check EC2 instance status checks pass

### High CPU Usage
- Review application logs
- Consider larger instance type
- Enable detailed CloudWatch monitoring
- Check for runaway processes

### Network Performance Issues
- Enable EBS optimization
- Use ENI placement groups
- Check security group rules
- Monitor network throughput with CloudWatch

## Security Considerations

✅ **Enabled by Default**
- IMDSv2 enforcement
- CloudWatch monitoring
- IAM instance profile
- EBS encryption

⚠️ **Requires Configuration**
- SSH key pair for remote access
- Security group ingress rules
- Custom IAM policies
- VPC endpoints for private AWS API access

❌ **Not Recommended**
- Public SSH access to all instances
- Storing secrets in user data
- Disabling IMDSv2
- Unencrypted EBS volumes
- Running with overly permissive IAM roles

## Related Modules

- **Lambda Module**: For serverless compute
- **ALB Module**: For load balancing
- **RDS Module**: For managed databases
- **S3 Module**: For object storage
- **VPC Module**: For networking

## References

- [EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [EC2 Best Practices](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-best-practices.html)
- [EC2 Pricing](https://aws.amazon.com/ec2/pricing/)
- [EC2 Instance Types](https://aws.amazon.com/ec2/instance-types/)

---

**Module Version**: 1.0.0  
**Last Updated**: 2026
