# =============================================================================
# ROOT TERRAGRUNT CONFIGURATION (LOCAL BACKEND)
# =============================================================================
# This version uses local backend for development when AWS credentials aren't available

# =============================================================================
# REMOTE STATE CONFIGURATION (LOCAL)
# =============================================================================
remote_state {
  backend = "local"
  config = {
    path = "${path_relative_to_include()}/terraform.tfstate"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# =============================================================================
# PROVIDER GENERATION
# =============================================================================
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.63.1"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null
  
  default_tags {
    tags = merge(
      {
        Environment = var.environment
        Customer    = var.customer_name
      },
      var.additional_tags
    )
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
EOF
}

# =============================================================================
# DEFAULT INPUTS - Can be overridden in child configurations
# =============================================================================
inputs = {
  # =============================================================================
  # AWS CONFIGURATION
  # =============================================================================
  aws_region  = get_env("AWS_REGION", "us-east-1")
  aws_profile = get_env("AWS_PROFILE", "")
  
  # =============================================================================
  # PROJECT CONFIGURATION
  # =============================================================================
  project_name = "web-application"
  customer_name = "default"
  environment   = "dev"
  domain_name   = "example.com"
  
  # =============================================================================
  # FEATURE FLAGS - Control which resources to create
  # =============================================================================
  # These flags allow customers to enable/disable specific components
  # Example: Customer A (frontend only) vs Customer B (full stack)
  # VPC is now always created (no longer optional) - use vpc_option to control behavior
  create_alb_asg           = false  # Unified ALB + ASG module
  create_bastion          = false
  create_rds              = false
  create_cicd             = false
  create_monitoring       = false
  create_backup_replication = false
  create_secrets          = false
  create_frontend         = false
  create_content_storage  = false
  
  # =============================================================================
  # SSH KEY CONFIGURATION (Simplified like CloudFront keys)
  # =============================================================================
  # Choose ONE of the following SSH key options:
  # 1. "create_new" -> Create a new SSH key pair and save to local files
  # 2. "use_existing_aws" -> Use an existing SSH key pair already in AWS
  # 3. "use_existing_local" -> Use an existing SSH public key from local file
  
  ssh_key_option = "create_new"  # Options: "create_new", "use_existing_aws", "use_existing_local"
  ssh_keys_directory = "keys/APP-SSH-KEYS"  # Directory to save SSH keys in project root (only used when ssh_key_option = "create_new")
  
  # Existing AWS SSH Key Configuration (only used when ssh_key_option = "use_existing_aws")
  existing_ssh_key_name = "customer-one-dev-ssh-key"
  
  # Existing Local SSH Key Configuration (only used when ssh_key_option = "use_existing_local")
  existing_ssh_public_key = ""
  
  # =============================================================================
  # BASTION SSH KEY CONFIGURATION (Simplified)
  # =============================================================================
  # Choose ONE of the following SSH key options for bastion host:
  # 1. "create_new" -> Create a new SSH key pair and save to local files
  # 2. "use_existing_aws" -> Use an existing SSH key pair already in AWS
  # 3. "use_existing_local" -> Use an existing SSH public key from local file
  
  bastion_ssh_key_option = "create_new"  # Options: "create_new", "use_existing_aws", "use_existing_local"
  bastion_ssh_keys_directory = "keys/BASTIONHOST-SSH-KEYS"  # Directory to save bastion SSH keys in project root (only used when bastion_ssh_key_option = "create_new")
  
  # Existing AWS SSH Key Configuration for Bastion (only used when bastion_ssh_key_option = "use_existing_aws")
  bastion_existing_ssh_key_name = ""
  
  # Existing Local SSH Key Configuration for Bastion (only used when bastion_ssh_key_option = "use_existing_local")
  bastion_existing_ssh_public_key = ""  # PEM format public key (leave empty to auto-generate)
  
  # =============================================================================
  # CLOUDFRONT SIGNED URL OPTIONS
  # =============================================================================
  cloudfront_public_key = ""  # PEM format public key for signed URLs (leave empty to auto-generate)
  use_existing_cloudfront_public_key = false  # Set to true to use existing CloudFront public key
  existing_cloudfront_public_key_id = ""  # ID of existing CloudFront public key
  cloudfront_keys_directory = "keys/CDN-KEYS"  # Directory to save keys (will be created if doesn't exist)
  
  # =============================================================================
  # ACM CERTIFICATE CONFIGURATION
  # =============================================================================
  skip_acm_setup = false
  use_existing_acm_certificate = false
  existing_acm_certificate_arn = ""
  
  # =============================================================================
  # VPC CONFIGURATION - Flexible VPC Management
  # =============================================================================
  # Choose ONE of the following VPC options:
  # 1. "create_new"  -> Create a brand new VPC with custom subnets
  # 2. "use_existing" -> Use a specific existing VPC (provide VPC ID and subnet IDs)
  # 3. "use_default"  -> Use AWS default VPC (auto-detects default VPC and subnets)
  
  vpc_option = "use_default"  # Options: "create_new", "use_existing", "use_default"
  
  # New VPC Configuration (only used when vpc_option = "create_new")
  new_vpc_cidr = "10.0.0.0/16"
  new_vpc_public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  new_vpc_private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  new_vpc_availability_zones = ["us-east-1a", "us-east-1b"]
  
  # Existing VPC Configuration (only used when vpc_option = "use_existing")
  existing_vpc_id = ""
  existing_public_subnet_ids = []
  existing_private_subnet_ids = []
  
  # =============================================================================
  # SECURITY CONFIGURATION
  # =============================================================================
  allowed_ssh_cidrs = ["0.0.0.0/0"]  # WARNING: Restrict in production!
  
  # =============================================================================
  # RESOURCE CONFIGURATION
  # =============================================================================
  instance_type      = "t3.micro"
  min_size          = 1
  max_size          = 3
  desired_capacity  = 1
  
  # Database configuration
  db_instance_class = "db.t3.micro"
  read_replica_count = 0
  db_username = "admin"
  db_password = "changeme123"  # WARNING: Use proper secrets management
  db_name = "webapp"
  enable_performance_insights = false  # Disabled by default for dev environments
  
  # AMI configuration
  app_ami_id = ""      # Leave empty to use latest Ubuntu 22.04
  bastion_ami_id = ""  # Leave empty to use latest Ubuntu 22.04
  
  # =============================================================================
  # BACKUP AND REPLICATION CONFIGURATION
  # =============================================================================
  backup_s3_bucket_arn = ""
  backup_account_id = ""
  backup_kms_key_arn = ""
  
  # =============================================================================
  # ADDITIONAL TAGS (Optional)
  # =============================================================================
  additional_tags = {}
}
