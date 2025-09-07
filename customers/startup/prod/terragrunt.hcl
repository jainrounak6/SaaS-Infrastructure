# =============================================================================
# STARTUP CUSTOMER - PRODUCTION ENVIRONMENT
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
  environment   = "prod"
  
  # AWS Configuration
  aws_region    = "us-east-1"
  aws_profile   = "cloudguru"  
  # Project Configuration
  project_name  = "customer-one"
  domain_name   = "startup.example.com"
  
  # VPC Configuration - Use default VPC (example)
  create_vpc                    = false
  existing_vpc_id               = ""
  existing_public_subnet_ids    = []
  existing_private_subnet_ids   = []
  use_default_vpc               = true
  
  # Feature Flags - Production gets all features
  create_bastion       = true
  create_rds           = true
  create_cicd          = true
  create_monitoring    = true
  create_backup_replication = true
  
  # Resource Configuration - Production resources
  instance_type     = "t3.xlarge"
  app_ami_id        = "ami-0bbdd8c17ed981ef9"  # Ubuntu 22.04 LTS in us-east-1
  bastion_ami_id    = "ami-0bbdd8c17ed981ef9"  # Ubuntu 22.04 LTS in us-east-1
  min_size          = 3
  max_size          = 10
  desired_capacity  = 3
  db_instance_class = "db.r5.large"
  read_replica_count = 2
  
  # ACM Configuration - Enable for production
  skip_acm_setup = false
  
  # SSH Configuration
  create_ssh_key = true
  ssh_key_name = ""  # Auto-generates: startup-prod-key
  
  # Additional Tags (optional)
  additional_tags = {
    Purpose = "production"
    Team    = "operations"
    CostCenter = "engineering"
  }
}