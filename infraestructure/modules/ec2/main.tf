################################################################################
# AWS EC2 Module
# Deploys EC2 instances with comprehensive configuration, monitoring,
# security, and auto-scaling capabilities.
################################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Create security group for EC2
resource "aws_security_group" "ec2" {
  name_prefix = "${var.instance_name}-sg-"
  description = "Security group for ${var.instance_name}"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    { Name = "${var.instance_name}-sg" }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Ingress rules
resource "aws_vpc_security_group_ingress_rule" "ec2" {
  for_each = var.ingress_rules != null ? var.ingress_rules : {}

  security_group_id = aws_security_group.ec2.id

  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  ip_protocol                  = each.value.protocol
  cidr_ipv4                    = each.value.cidr_ipv4
  referenced_security_group_id = each.value.source_security_group_id

  tags = {
    Name = "${var.instance_name}-${each.key}"
  }
}

# Egress rule (allow all outbound)
resource "aws_vpc_security_group_egress_rule" "ec2" {
  security_group_id = aws_security_group.ec2.id

  cidr_ipv4    = "0.0.0.0/0"
  from_port    = 0
  to_port      = 65535
  ip_protocol  = "tcp"

  tags = {
    Name = "${var.instance_name}-egress"
  }
}

# Create IAM role for EC2 instance profile
resource "aws_iam_role" "ec2_role" {
  name_prefix = "${var.instance_name}-ec2-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach SSM Session Manager policy for systems access
resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch agent policy
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach EC2 instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name_prefix = "${var.instance_name}-profile-"
  role        = aws_iam_role.ec2_role.name
}

# Get latest AMI
data "aws_ami" "ec2" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = var.ami_filter_name
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create EC2 instance
resource "aws_instance" "ec2" {
  ami                         = var.ami_id != null ? var.ami_id : data.aws_ami.ec2.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.associate_public_ip
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  key_name                    = var.key_name

  # Security
  vpc_security_group_ids = [aws_security_group.ec2.id]
  monitoring             = var.enable_detailed_monitoring

  # Storage configuration
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = true
    encrypted             = var.encrypt_root_volume

    tags = merge(
      var.tags,
      { Name = "${var.instance_name}-root" }
    )
  }

  # EBS-optimized for better performance
  ebs_optimized = var.ebs_optimized

  # Advanced options
  user_data = var.user_data

  dynamic "credit_specification" {
    for_each = can(regex("^t", var.instance_type)) ? [1] : []
    content {
      cpu_credits = var.cpu_credits
    }
  }

  hibernation = var.enable_hibernation

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.require_imds_token ? "required" : "optional"
    http_put_response_hop_limit = 1
  }

  tags = merge(
    var.tags,
    { Name = var.instance_name }
  )

  depends_on = [aws_iam_instance_profile.ec2_profile]

  lifecycle {
    ignore_changes = [ami]
  }
}

# Create additional EBS volumes
resource "aws_ebs_volume" "additional" {
  for_each = var.additional_volumes != null ? var.additional_volumes : {}

  availability_zone = aws_instance.ec2.availability_zone
  size              = each.value.size
  type              = each.value.type
  iops              = each.value.iops
  throughput        = each.value.throughput
  encrypted         = var.encrypt_root_volume

  tags = merge(
    var.tags,
    { Name = "${var.instance_name}-${each.key}" }
  )
}

# Attach additional volumes
resource "aws_volume_attachment" "additional" {
  for_each = var.additional_volumes != null ? var.additional_volumes : {}

  device_name = each.value.device_name
  volume_id   = aws_ebs_volume.additional[each.key].id
  instance_id = aws_instance.ec2.id
}

# Elastic IP (optional)
resource "aws_eip" "ec2" {
  count  = var.allocate_elastic_ip ? 1 : 0
  domain = "vpc"

  tags = merge(
    var.tags,
    { Name = "${var.instance_name}-eip" }
  )
}

resource "aws_eip_association" "ec2" {
  count         = var.allocate_elastic_ip ? 1 : 0
  instance_id   = aws_instance.ec2.id
  allocation_id = aws_eip.ec2[0].id
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  count               = var.create_cpu_alarm ? 1 : 0
  alarm_name          = "${var.instance_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.ec2.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "status_check" {
  count               = var.create_status_alarm ? 1 : 0
  alarm_name          = "${var.instance_name}-status-check"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.ec2.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "network_in" {
  count               = var.create_network_alarm ? 1 : 0
  alarm_name          = "${var.instance_name}-high-network-in"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.network_threshold
  alarm_actions       = var.alarm_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.ec2.id
  }

  tags = var.tags
}

# CloudWatch composite alarm
resource "aws_cloudwatch_composite_alarm" "ec2_health" {
  count           = var.create_composite_alarm ? 1 : 0
  alarm_name      = "${var.instance_name}-health"
  alarm_description = "Composite health check for ${var.instance_name}"
  actions_enabled = true
  alarm_actions   = var.alarm_actions

  alarm_rule = join(" OR ", concat(
    var.create_cpu_alarm ? [aws_cloudwatch_metric_alarm.cpu_utilization[0].arn] : [],
    var.create_status_alarm ? [aws_cloudwatch_metric_alarm.status_check[0].arn] : [],
    var.create_network_alarm ? [aws_cloudwatch_metric_alarm.network_in[0].arn] : []
  ))

  tags = var.tags
}

# Auto-Scaling Group (optional - for multiple instances)
resource "aws_launch_template" "ec2" {
  count           = var.enable_auto_scaling ? 1 : 0
  name_prefix     = "${var.instance_name}-lt-"
  image_id        = var.ami_id != null ? var.ami_id : data.aws_ami.ec2.id
  instance_type   = var.instance_type
  key_name        = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  vpc_security_group_ids = [aws_security_group.ec2.id]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      delete_on_termination = true
      encrypted             = var.encrypt_root_volume
    }
  }

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.require_imds_token ? "required" : "optional"
    http_put_response_hop_limit = 1
  }

  user_data = base64encode(var.user_data != null ? var.user_data : "")

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.tags,
      { Name = var.instance_name }
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ec2" {
  count            = var.enable_auto_scaling ? 1 : 0
  name_prefix      = "${var.instance_name}-asg-"
  vpc_zone_identifier = var.asg_subnets
  launch_template {
    id      = aws_launch_template.ec2[0].id
    version = "$Latest"
  }

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  health_check_type         = "ELB"
  health_check_grace_period = 300
  termination_policies      = ["OldestInstance"]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
    }
  }

  dynamic "tag" {
    for_each = merge(var.tags, { Name = var.instance_name })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto-scaling policies
resource "aws_autoscaling_policy" "scale_up" {
  count                  = var.enable_auto_scaling && var.enable_scaling_policies ? 1 : 0
  name                   = "${var.instance_name}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.ec2[0].name
  cooldown               = 300
}

resource "aws_autoscaling_policy" "scale_down" {
  count                  = var.enable_auto_scaling && var.enable_scaling_policies ? 1 : 0
  name                   = "${var.instance_name}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.ec2[0].name
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count               = var.enable_auto_scaling && var.enable_scaling_policies ? 1 : 0
  alarm_name          = "${var.instance_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_actions       = [aws_autoscaling_policy.scale_up[0].arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ec2[0].name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  count               = var.enable_auto_scaling && var.enable_scaling_policies ? 1 : 0
  alarm_name          = "${var.instance_name}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 30
  alarm_actions       = [aws_autoscaling_policy.scale_down[0].arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ec2[0].name
  }
}

# AWS CloudWatch agent config (optional)
resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  count           = var.cloudwatch_config != null ? 1 : 0
  name            = "/cloudwatch-config/${var.instance_name}"
  type            = "String"
  value           = var.cloudwatch_config
  description     = "CloudWatch agent configuration for ${var.instance_name}"

  tags = var.tags
}

# Custom inline IAM policies
resource "aws_iam_role_policy" "custom_policies" {
  for_each = var.custom_policies != null ? var.custom_policies : {}

  name   = "${var.instance_name}-${each.key}"
  role   = aws_iam_role.ec2_role.id
  policy = each.value
}
