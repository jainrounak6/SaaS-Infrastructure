# =============================================================================
# STARTUP CUSTOMER - STAGING ENVIRONMENT
# =============================================================================

include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Point to the main Terraform configuration
terraform {
  source = "../../../"
}

# Override only what's different from defaults
inputs = {
  # Customer and Environment
  customer_name = "startup"
  environment   = "staging"
  
  # AWS Configuration
  aws_region    = "us-east-1"
  aws_profile   = "cloudguru"  
  # Project Configuration
  project_name  = "customer-one"
  domain_name   = "staging.startup.example.com"
  
  # VPC Configuration - Use existing VPC (example)
  create_vpc                    = false
  existing_vpc_id               = "vpc-12345678"  # Replace with your existing VPC ID
  existing_public_subnet_ids    = ["subnet-12345678", "subnet-87654321"]  # Replace with your subnet IDs
  existing_private_subnet_ids   = ["subnet-11111111", "subnet-22222222"]  # Replace with your subnet IDs
  use_default_vpc               = false
  
  # Feature Flags - Staging gets more features
  create_bastion       = true
  create_rds           = true
  create_cicd          = true
  create_monitoring    = true
  create_backup_replication = false
  
  # Resource Configuration - Medium resources
  instance_type     = "t3.large"
  app_ami_id        = "ami-0bbdd8c17ed981ef9"  # Ubuntu 22.04 LTS in us-east-1
  bastion_ami_id    = "ami-0bbdd8c17ed981ef9"  # Ubuntu 22.04 LTS in us-east-1
  min_size          = 2
  max_size          = 5
  desired_capacity  = 2
  db_instance_class = "db.t3.large"
  read_replica_count = 1
  
  # ACM Configuration - Skip for staging
  skip_acm_setup = true
  
  # SSH Configuration
  create_ssh_key = true
  ssh_key_name = ""  # Auto-generates: startup-staging-key
  
  # Additional Tags (optional)
  additional_tags = {
    Purpose = "staging"
    Team    = "development"
  }
}