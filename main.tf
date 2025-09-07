# =============================================================================
# ROOT TERRAFORM CONFIGURATION
# =============================================================================
# This is the main Terraform configuration that orchestrates all modules
# based on feature flags and customer requirements

# =============================================================================
# LOCAL VALUES
# =============================================================================

locals {
  common_tags = merge(var.additional_tags, {
    Project     = var.project_name
    Customer    = var.customer_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

# =============================================================================
# VPC MODULE
# =============================================================================

module "vpc" {
  count  = var.vpc_option != "do_not_create" ? 1 : 0
  source = "./modules/vpc"

  project_name = var.project_name
  environment  = var.environment
  common_tags  = local.common_tags

  # VPC Configuration
  vpc_option = var.vpc_option

  # New VPC Configuration (only used when vpc_option = "create_new")
  new_vpc_cidr                    = var.new_vpc_cidr
  new_vpc_public_subnet_cidrs     = var.new_vpc_public_subnet_cidrs
  new_vpc_private_subnet_cidrs    = var.new_vpc_private_subnet_cidrs
  new_vpc_availability_zones      = var.new_vpc_availability_zones

  # Existing VPC Configuration (only used when vpc_option = "use_existing")
  existing_vpc_id              = var.existing_vpc_id
  existing_public_subnet_ids   = var.existing_public_subnet_ids
  existing_private_subnet_ids  = var.existing_private_subnet_ids
}

# =============================================================================
# FRONTEND MODULE
# =============================================================================

module "frontend" {
  count  = var.create_frontend ? 1 : 0
  source = "./modules/frontend"

  project_name = var.project_name
  environment  = var.environment
  common_tags  = local.common_tags
}

# =============================================================================
# CONTENT STORAGE MODULE
# =============================================================================

module "content_storage" {
  count  = var.create_content_storage ? 1 : 0
  source = "./modules/content_storage"

  project_name = var.project_name
  customer_name = var.customer_name
  environment  = var.environment
  common_tags  = local.common_tags

  # CloudFront signed URL configuration
  use_existing_cloudfront_public_key = var.use_existing_cloudfront_public_key
  existing_cloudfront_public_key_id  = var.existing_cloudfront_public_key_id
  cloudfront_public_key              = var.cloudfront_public_key
  cloudfront_keys_directory          = var.cloudfront_keys_directory
}

# =============================================================================
# ALB + ASG MODULE (Unified)
# =============================================================================

module "alb_asg" {
  count  = var.create_alb_asg ? 1 : 0
  source = "./modules/alb_asg"

  project_name = var.project_name
  customer_name = var.customer_name
  environment  = var.environment
  common_tags  = local.common_tags

  # VPC Configuration
  vpc_id              = module.vpc[0].vpc_id
  public_subnet_ids   = module.vpc[0].public_subnet_ids
  private_subnet_ids  = module.vpc[0].private_subnet_ids

  # ALB Configuration
  domain_name = var.domain_name
  acm_certificate_arn = var.certificate_arn

  # ASG Configuration
  instance_type    = var.instance_type
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity
  app_ami_id       = var.app_ami_id

  # SSH Key Configuration (Simplified)
  ssh_key_option     = var.ssh_key_option
  ssh_keys_directory = var.ssh_keys_directory
  existing_ssh_key_name = var.existing_ssh_key_name
  existing_ssh_public_key = var.existing_ssh_public_key
}
