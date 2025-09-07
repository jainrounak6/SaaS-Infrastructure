# =============================================================================
# ROOT OUTPUTS
# =============================================================================

# ALB DNS Name
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = var.create_alb_asg ? module.alb_asg[0].alb_dns_name : null
}

# ALB Zone ID
output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = var.create_alb_asg ? module.alb_asg[0].alb_zone_id : null
}

# VPC ID
output "vpc_id" {
  description = "ID of the VPC"
  value       = var.vpc_option != "do_not_create" ? module.vpc[0].vpc_id : null
}

# Public Subnet IDs
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = var.vpc_option != "do_not_create" ? module.vpc[0].public_subnet_ids : null
}

# Private Subnet IDs
output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = var.vpc_option != "do_not_create" ? module.vpc[0].private_subnet_ids : null
}

# Content Storage Buckets
output "public_content_bucket_name" {
  description = "Name of the public content S3 bucket"
  value       = length(module.content_storage) > 0 ? module.content_storage[0].public_content_bucket_name : null
}

output "private_content_bucket_name" {
  description = "Name of the private content S3 bucket"
  value       = length(module.content_storage) > 0 ? module.content_storage[0].private_content_bucket_name : null
}

# CloudFront Distributions
output "public_content_cloudfront_domain_name" {
  description = "CloudFront domain for public content"
  value       = length(module.content_storage) > 0 ? module.content_storage[0].public_content_cloudfront_domain_name : null
}

output "private_content_cloudfront_domain_name" {
  description = "CloudFront domain for private content"
  value       = length(module.content_storage) > 0 ? module.content_storage[0].private_content_cloudfront_domain_name : null
}

# Frontend
output "frontend_bucket_name" {
  description = "Name of the frontend S3 bucket"
  value       = length(module.frontend) > 0 ? module.frontend[0].frontend_bucket_name : null
}

output "frontend_cloudfront_domain_name" {
  description = "CloudFront domain for frontend"
  value       = length(module.frontend) > 0 ? module.frontend[0].frontend_cloudfront_domain_name : null
}

# Note: Bastion module is not currently enabled in main.tf
# Uncomment the following outputs when bastion module is added:
#
# output "bastion_public_ip" {
#   description = "Public IP address of the bastion host"
#   value       = var.create_bastion ? module.bastion[0].bastion_public_ip : null
# }
#
# output "bastion_ssh_command" {
#   description = "SSH command to connect to the bastion host"
#   value       = var.create_bastion ? module.bastion[0].bastion_ssh_command : null
# }
