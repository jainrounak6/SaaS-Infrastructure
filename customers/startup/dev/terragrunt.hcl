# =============================================================================
# CUSTOMER CONFIGURATION: startup
# =============================================================================

include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../"
}

# Calculate project root and keys base path for portability
locals {
  # Get current terragrunt directory (customers/startup/dev)
  current_dir = get_terragrunt_dir()
  
  # Calculate project root by going up 3 levels: customers/startup/dev -> project root
  project_root = dirname(dirname(dirname(local.current_dir)))
  
  # Define keys base path
  keys_base_path = "${local.project_root}/keys"
}

inputs = {
  # =============================================================================
  # BASIC CONFIGURATION
  # =============================================================================
  customer_name = "startup"
  environment   = "dev"
  project_name  = "customer-one"
  domain_name   = "dev.startup.example.com"

  # AWS Configuration
  aws_region  = "us-east-1"
  aws_profile = "cloudguru"

  # =============================================================================
  # FEATURE FLAGS - Enable/Disable Infrastructure Components
  # =============================================================================
  create_frontend           = true  # S3 + CloudFront for static website
  create_content_storage    = true  # S3 + CloudFront for content storage
  create_vpc                = false  # VPC and networking
  create_alb_asg            = true  # Unified ALB + ASG module
  create_rds                = false # Aurora MySQL Database
  create_bastion            = false # Bastion Host for SSH access
  create_cicd               = false # CI/CD Pipeline
  create_monitoring         = false # CloudWatch monitoring
  create_backup_replication = false # Cross-account S3 replication
  create_secrets            = false # AWS Secrets Manager
  # SSH Key management is now handled by the unified ssh_key_option variables

  # =============================================================================
  # VPC CONFIGURATION - Flexible VPC Management
  # =============================================================================
  # Choose ONE of the following VPC options:
  # 1. "create_new"  -> Create a brand new VPC with custom subnets
  # 2. "use_existing" -> Use a specific existing VPC (provide VPC ID and subnet IDs)
  # 3. "use_default"  -> Use AWS default VPC (auto-detects default VPC and subnets)

  vpc_option = "use_default" # Options: "create_new", "use_existing", "use_default"

  # New VPC Configuration (only used when vpc_option = "create_new")
  # new_vpc_cidr = "10.0.0.0/16"
  # new_vpc_public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
  # new_vpc_private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  # new_vpc_availability_zones = ["us-east-1a", "us-east-1b"]

  # Existing VPC Configuration (only used when vpc_option = "use_existing")
  # existing_vpc_id = "vpc-01ad7bd83ff99c67e"
  # existing_public_subnet_ids = ["subnet-05e26071e27cc8e9a", "subnet-0d3dcfbdeb9baa6c5", "subnet-04613fb140e3bc3aa", "subnet-0e3900664339747d4", "subnet-01fed3167f7121f82", "subnet-06cbab1cc66f3d868"]
  # existing_private_subnet_ids = []

  # Default VPC Configuration (only used when vpc_option = "use_default")
  # No additional configuration needed - AWS default VPC and subnets are auto-detected

  # =============================================================================
  # FRONTEND CONFIGURATION (when create_frontend = true)
  # =============================================================================
  # No additional configuration needed - uses defaults

  # =============================================================================
  # CONTENT STORAGE CONFIGURATION (when create_content_storage = true)
  # =============================================================================

  # CloudFront signed URL configuration
  # cloudfront_public_key = ""  # Leave empty to auto-generate keys, or provide your own PEM format public key
  use_existing_cloudfront_public_key = false        # Set to true to use existing CloudFront public key
  existing_cloudfront_public_key_id  = ""           # ID of existing CloudFront public key (e.g., "K3D5EWEUDCCXON")
  
  # CloudFront Keys Directory Configuration
  # Uses calculated project root path for portability
  cloudfront_keys_directory = "${local.keys_base_path}/CDN-KEYS"

  # =============================================================================
  # ALB CONFIGURATION (when create_alb = true)
  # =============================================================================
  certificate_arn                = ""
  alb_internal                   = false
  alb_idle_timeout               = 60
  alb_enable_deletion_protection = false

  # =============================================================================
  # ASG CONFIGURATION (when create_asg = true)
  # =============================================================================
  instance_type    = "t3.small"
  min_size         = 2
  max_size         = 3
  desired_capacity = 2
  app_ami_id       = "ami-0bbdd8c17ed981ef9"

  # =============================================================================
  # SSH KEY CONFIGURATION (Simplified like CloudFront keys)
  # =============================================================================
  # Choose ONE of the following SSH key options:
  # 1. "create_new" -> Create a new SSH key pair and save to local files
  # 2. "use_existing_aws" -> Use an existing SSH key pair already in AWS
  # 3. "use_existing_local" -> Use an existing SSH public key from local file

  ssh_key_option     = "create_new" # Options: "create_new", "use_existing_aws", "use_existing_local"
  ssh_keys_directory = "${local.keys_base_path}/APP-SSH-KEYS"     # Directory to save SSH keys (only used when ssh_key_option = "create_new")

  # Existing AWS SSH Key Configuration (only used when ssh_key_option = "use_existing_aws")
  existing_ssh_key_name = ""

  # Existing Local SSH Key Configuration (only used when ssh_key_option = "use_existing_local")
  existing_ssh_public_key = ""

  # =============================================================================
  # APPLICATION CONFIGURATION
  # =============================================================================
  
  # Node.js version to install (e.g., '18', '20', '22')
  # If not specified, uses Node.js 22.x (latest)
  nodejs_version = "22"  # Options: "22" (default), or specific version like "18", "20"
  
  # Application port configuration
  app_port = 3000  # Options: 3000 (default), or any valid port number (1-65535)

  # =============================================================================
  # RDS CONFIGURATION (when create_rds = true)
  # =============================================================================
  db_instance_class           = "db.t3.micro"
  db_allocated_storage        = 20
  db_engine_version           = "8.0.mysql_aurora.3.02.0"
  db_name                     = "webapp"
  db_username                 = "admin"
  db_password                 = "changeme123"
  read_replica_count          = 0
  enable_performance_insights = false

  # =============================================================================
  # BASTION CONFIGURATION (when create_bastion = true)
  # =============================================================================
  bastion_instance_type = "t3.micro"
  bastion_ami_id        = ""

  # SSH Key options for Bastion host
  bastion_use_existing_ssh_key  = false # Set to true to use existing key
  bastion_existing_ssh_key_name = ""    # Name of existing key
  bastion_is_shared_ssh_key     = false # Set to true if shared (prevents deletion)
  bastion_save_ssh_private_key  = true  # Save private key to local file
  bastion_save_ssh_public_key   = true  # Save public key to local file

  # =============================================================================
  # CI/CD CONFIGURATION (when create_cicd = true)
  # =============================================================================
  github_repo   = ""
  github_branch = "main"
  github_token  = ""

  # =============================================================================
  # MONITORING CONFIGURATION (when create_monitoring = true)
  # =============================================================================
  # No additional configuration needed - uses defaults

  # =============================================================================
  # BACKUP REPLICATION CONFIGURATION (when create_backup_replication = true)
  # =============================================================================
  backup_account_id = ""
  backup_region     = ""

  # =============================================================================
  # SECRETS CONFIGURATION (when create_secrets = true)
  # =============================================================================
  # No additional configuration needed - uses defaults



  # =============================================================================
  # ADDITIONAL TAGS
  # =============================================================================
  additional_tags = {
    Customer    = "startup"
    Environment = "dev"
    Project     = "customer-one"
  }
}