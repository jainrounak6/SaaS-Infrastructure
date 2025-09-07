# =============================================================================
# ALB + ASG MODULE OUTPUTS
# =============================================================================

# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer"
  value       = aws_lb.main.arn_suffix
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

# Target Group Outputs
output "app_target_group_arn" {
  description = "ARN of the application target group"
  value       = aws_lb_target_group.app.arn
}

# ASG Outputs
output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.arn
}

output "asg_security_group_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.ec2.id
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.main.id
}

output "launch_template_arn" {
  description = "ARN of the launch template"
  value       = aws_launch_template.main.arn
}

# IAM Outputs
output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "ec2_instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

# SSH Key Outputs
output "ssh_key_name" {
  description = "Name of the SSH key pair"
  value       = local.ssh_key_name
}

output "ssh_key_option" {
  description = "SSH key option used"
  value       = var.ssh_key_option
}

# SSH Key Generation Outputs (only when generating new keys)
output "ssh_private_key_pem" {
  description = "The SSH private key in PEM format"
  value       = var.ssh_key_option == "create_new" ? tls_private_key.ssh_key[0].private_key_openssh : null
  sensitive   = true
}

output "ssh_private_key_file_path" {
  description = "Path to the saved SSH private key file"
  value       = var.ssh_key_option == "create_new" ? "${var.ssh_keys_directory}/${var.customer_name}/${var.environment}/${var.project_name}-${var.environment}-ssh-private.pem" : null
}

output "ssh_public_key_file_path" {
  description = "Path to the saved SSH public key file"
  value       = var.ssh_key_option == "create_new" ? "${var.ssh_keys_directory}/${var.customer_name}/${var.environment}/${var.project_name}-${var.environment}-ssh-public.pem" : null
}

output "ssh_keys_directory" {
  description = "Directory where SSH keys are saved"
  value       = var.ssh_key_option == "create_new" ? var.ssh_keys_directory : null
}

# CloudWatch Outputs
output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.alb.dashboard_name}"
}

# S3 Outputs
output "alb_logs_bucket_name" {
  description = "Name of the ALB logs S3 bucket"
  value       = aws_s3_bucket.alb_logs.bucket
}

output "alb_logs_bucket_arn" {
  description = "ARN of the ALB logs S3 bucket"
  value       = aws_s3_bucket.alb_logs.arn
}
