# =============================================================================
# VPC MODULE OUTPUTS
# =============================================================================

# VPC Information
output "vpc_id" {
  description = "ID of the VPC (new, existing, or default)"
  value       = local.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = local.vpc_cidr
}

output "vpc_option" {
  description = "VPC deployment option used"
  value       = var.vpc_option
}

# Subnet Information
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = local.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = local.private_subnet_ids
}

# Gateway Information (only available for new VPC)
output "internet_gateway_id" {
  description = "ID of the Internet Gateway (only available for new VPC)"
  value       = local.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs (only available for new VPC)"
  value       = local.nat_gateway_ids
}

# Availability Zones
output "availability_zones" {
  description = "List of availability zones used"
  value       = var.vpc_option == "create_new" ? var.new_vpc_availability_zones : (
    var.vpc_option == "use_existing" ? data.aws_subnet.existing_public[*].availability_zone : 
    data.aws_subnet.default[*].availability_zone
  )
}

# Resource Counts
output "public_subnet_count" {
  description = "Number of public subnets"
  value       = length(local.public_subnet_ids)
}

output "private_subnet_count" {
  description = "Number of private subnets"
  value       = length(local.private_subnet_ids)
}

# VPC Type Information
output "is_new_vpc" {
  description = "Whether this is a newly created VPC"
  value       = var.vpc_option == "create_new"
}

output "is_existing_vpc" {
  description = "Whether this is an existing VPC"
  value       = var.vpc_option == "use_existing"
}

output "is_default_vpc" {
  description = "Whether this is the AWS default VPC"
  value       = var.vpc_option == "use_default"
}