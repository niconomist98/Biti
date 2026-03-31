################################################################################
# EC2 Module - Outputs
################################################################################

output "instance_id" {
  description = "Instance ID"
  value       = aws_instance.ec2.id
}

output "instance_arn" {
  description = "Instance ARN"
  value       = aws_instance.ec2.arn
}

output "instance_private_ip" {
  description = "Private IP address"
  value       = aws_instance.ec2.private_ip
}

output "instance_public_ip" {
  description = "Public IP address"
  value       = aws_instance.ec2.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name"
  value       = aws_instance.ec2.public_dns
}

output "instance_private_dns" {
  description = "Private DNS name"
  value       = aws_instance.ec2.private_dns
}

output "instance_availability_zone" {
  description = "Availability zone of the instance"
  value       = aws_instance.ec2.availability_zone
}

output "instance_primary_network_interface_id" {
  description = "Network interface ID"
  value       = aws_instance.ec2.primary_network_interface_id
}

output "instance_root_block_device" {
  description = "Root block device information"
  value       = aws_instance.ec2.root_block_device
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.ec2.id
}

output "security_group_arn" {
  description = "Security group ARN"
  value       = aws_security_group.ec2.arn
}

output "elastic_ip" {
  description = "Elastic IP address"
  value       = var.allocate_elastic_ip ? aws_eip.ec2[0].public_ip : null
}

output "elastic_ip_id" {
  description = "Elastic IP allocation ID"
  value       = var.allocate_elastic_ip ? aws_eip.ec2[0].id : null
}

output "role_arn" {
  description = "IAM role ARN"
  value       = aws_iam_role.ec2_role.arn
}

output "role_name" {
  description = "IAM role name"
  value       = aws_iam_role.ec2_role.name
}

output "instance_profile_arn" {
  description = "Instance profile ARN"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

output "instance_profile_name" {
  description = "Instance profile name"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "additional_volume_ids" {
  description = "IDs of additional EBS volumes"
  value       = { for key, vol in aws_ebs_volume.additional : key => vol.id }
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = var.enable_auto_scaling ? aws_autoscaling_group.ec2[0].name : null
}

output "asg_arn" {
  description = "Auto Scaling Group ARN"
  value       = var.enable_auto_scaling ? aws_autoscaling_group.ec2[0].arn : null
}

output "launch_template_id" {
  description = "Launch template ID"
  value       = var.enable_auto_scaling ? aws_launch_template.ec2[0].id : null
}

output "launch_template_latest_version" {
  description = "Launch template latest version"
  value       = var.enable_auto_scaling ? aws_launch_template.ec2[0].latest_version_number : null
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = aws_instance.ec2.ami
}

output "connection_string" {
  description = "SSH connection string"
  value       = var.key_name != null ? "ssh -i /path/to/${var.key_name}.pem ec2-user@${aws_instance.ec2.public_ip}" : "Use AWS Systems Manager Session Manager"
}

output "cpu_alarm_arn" {
  description = "CPU utilization alarm ARN"
  value       = var.create_cpu_alarm ? aws_cloudwatch_metric_alarm.cpu_utilization[0].arn : null
}

output "status_alarm_arn" {
  description = "Status check alarm ARN"
  value       = var.create_status_alarm ? aws_cloudwatch_metric_alarm.status_check[0].arn : null
}

output "network_alarm_arn" {
  description = "Network traffic alarm ARN"
  value       = var.create_network_alarm ? aws_cloudwatch_metric_alarm.network_in[0].arn : null
}

output "composite_alarm_arn" {
  description = "Composite health alarm ARN"
  value       = var.create_composite_alarm ? aws_cloudwatch_composite_alarm.ec2_health[0].arn : null
}
