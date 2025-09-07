# AWS Configuration
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
  validation {
    condition = can(regex("^[a-z0-9-]+$", var.aws_region))
    error_message = "AWS region must be a valid region identifier (e.g., us-east-1, eu-west-1)."
  }
}

variable "aws_profile" {
  description = "AWS profile to use (optional, leave empty for default profile)"
  type        = string
  default     = ""
}

variable "aws_account_id" {
  description = "AWS Account ID (optional, will be auto-detected if not provided)"
  type        = string
  default     = ""
}

# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "web-application"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# =============================================================================
# CUSTOMER CONFIGURATION
# =============================================================================
variable "customer_name" {
  description = "Customer name for tagging and identification"
  type        = string
  default     = "default"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.customer_name))
    error_message = "Customer name must contain only alphanumeric characters, hyphens, and underscores."
  }
}


variable "additional_tags" {
  description = "Additional tags to apply to all resources (optional)"
  type        = map(string)
  default     = {}
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "example.com"
}

variable "skip_acm_setup" {
  description = "Skip ACM certificate setup (useful when domain validation is not available)"
  type        = bool
  default     = false
}

variable "use_existing_acm_certificate" {
  description = "Use existing ACM certificate instead of creating new one"
  type        = bool
  default     = false
}

variable "existing_acm_certificate_arn" {
  description = "ARN of existing ACM certificate to use"
  type        = string
  default     = ""
}

# SSH Key Management (Simplified like CloudFront keys)
variable "ssh_key_option" {
  description = "SSH key management option: 'create_new', 'use_existing_aws', or 'use_existing_local'"
  type        = string
  default     = "create_new"
  validation {
    condition     = contains(["create_new", "use_existing_aws", "use_existing_local"], var.ssh_key_option)
    error_message = "ssh_key_option must be one of: 'create_new', 'use_existing_aws', 'use_existing_local'."
  }
}

variable "ssh_keys_directory" {
  description = "Directory to save SSH keys (only used when ssh_key_option = 'create_new')"
  type        = string
  default     = "./keys"
}

variable "existing_ssh_key_name" {
  description = "Name of existing SSH key pair in AWS (only used when ssh_key_option = 'use_existing_aws')"
  type        = string
  default     = ""
}

variable "existing_ssh_public_key" {
  description = "Existing SSH public key content (only used when ssh_key_option = 'use_existing_local')"
  type        = string
  default     = ""
}


variable "cloudfront_public_key" {
  description = "CloudFront public key for signed URLs (PEM format). Leave empty to auto-generate."
  type        = string
  default     = ""
}

variable "use_existing_cloudfront_public_key" {
  description = "Whether to use an existing CloudFront public key that's already uploaded to AWS"
  type        = bool
  default     = false
}

variable "existing_cloudfront_public_key_id" {
  description = "ID of the existing CloudFront public key (when use_existing_cloudfront_public_key = true)"
  type        = string
  default     = ""
}

variable "cloudfront_keys_directory" {
  description = "Directory to save the CloudFront keys (will be created if doesn't exist)"
  type        = string
  default     = "./keys"
}

# ASG SSH Key management is now handled by the unified ssh_key_option variables above

# Bastion SSH Key Variables (Simplified)
variable "bastion_ssh_key_option" {
  description = "Bastion SSH key management option: 'create_new', 'use_existing_aws', or 'use_existing_local'"
  type        = string
  default     = "create_new"
  
  validation {
    condition     = contains(["create_new", "use_existing_aws", "use_existing_local"], var.bastion_ssh_key_option)
    error_message = "bastion_ssh_key_option must be one of: 'create_new', 'use_existing_aws', 'use_existing_local'."
  }
}

variable "bastion_ssh_keys_directory" {
  description = "Directory to save bastion SSH keys (only used when bastion_ssh_key_option = 'create_new')"
  type        = string
  default     = "keys/BASTIONHOST-SSH-KEYS"
}

variable "bastion_existing_ssh_key_name" {
  description = "Name of existing SSH key for bastion host (only used when bastion_ssh_key_option = 'use_existing_aws')"
  type        = string
  default     = ""
}

variable "bastion_existing_ssh_public_key" {
  description = "Public key content from local file for bastion host (only used when bastion_ssh_key_option = 'use_existing_local')"
  type        = string
  default     = ""
}

# SSH key name is now managed by the unified ssh_key_option variables above

# =============================================================================
# FEATURE FLAGS - Control which resources to create
# =============================================================================
# These flags allow customers to enable/disable specific components
# Example: Customer A (frontend only) vs Customer B (full stack)

variable "create_frontend" {
  description = "Whether to create frontend S3 and CloudFront resources"
  type        = bool
  default     = false
  validation {
    condition     = can(regex("^(true|false)$", tostring(var.create_frontend)))
    error_message = "create_frontend must be true or false."
  }
}

variable "create_content_storage" {
  description = "Whether to create content storage S3 and CloudFront resources"
  type        = bool
  default     = false
  validation {
    condition     = can(regex("^(true|false)$", tostring(var.create_content_storage)))
    error_message = "create_content_storage must be true or false."
  }
}

variable "create_alb_asg" {
  description = "Whether to create Application Load Balancer and Auto Scaling Group (unified module)"
  type        = bool
  default     = false
  validation {
    condition     = can(regex("^(true|false)$", tostring(var.create_alb_asg)))
    error_message = "create_alb_asg must be true or false."
  }
}

variable "create_rds" {
  description = "Whether to create RDS/Aurora database"
  type        = bool
  default     = false
  validation {
    condition     = can(regex("^(true|false)$", tostring(var.create_rds)))
    error_message = "create_rds must be true or false."
  }
}

variable "create_bastion" {
  description = "Whether to create bastion host for SSH access"
  type        = bool
  default     = false
  validation {
    condition     = can(regex("^(true|false)$", tostring(var.create_bastion)))
    error_message = "create_bastion must be true or false."
  }
}

variable "create_cicd" {
  description = "Whether to create CI/CD pipeline"
  type        = bool
  default     = false
  validation {
    condition     = can(regex("^(true|false)$", tostring(var.create_cicd)))
    error_message = "create_cicd must be true or false."
  }
}

variable "create_monitoring" {
  description = "Whether to create comprehensive monitoring"
  type        = bool
  default     = false
  validation {
    condition     = can(regex("^(true|false)$", tostring(var.create_monitoring)))
    error_message = "create_monitoring must be true or false."
  }
}

variable "create_backup_replication" {
  description = "Whether to create S3 cross-account replication"
  type        = bool
  default     = false
  validation {
    condition     = can(regex("^(true|false)$", tostring(var.create_backup_replication)))
    error_message = "create_backup_replication must be true or false."
  }
}

variable "create_secrets" {
  description = "Whether to create AWS Secrets Manager resources"
  type        = bool
  default     = false
  validation {
    condition     = can(regex("^(true|false)$", tostring(var.create_secrets)))
    error_message = "create_secrets must be true or false."
  }
}

# =============================================================================
# VPC CONFIGURATION - Flexible VPC Management
# =============================================================================
# Choose ONE of the following VPC options:
# 1. CREATE_NEW_VPC = true  -> Create a brand new VPC with custom subnets
# 2. USE_EXISTING_VPC = true -> Use a specific existing VPC (provide VPC ID and subnet IDs)
# 3. USE_DEFAULT_VPC = true  -> Use AWS default VPC (auto-detects default VPC and subnets)

variable "vpc_option" {
  description = "VPC deployment option: 'create_new', 'use_existing', or 'use_default'"
  type        = string
  default     = "use_default"
  validation {
    condition     = contains(["create_new", "use_existing", "use_default"], var.vpc_option)
    error_message = "vpc_option must be one of: 'create_new', 'use_existing', 'use_default'."
  }
}

# =============================================================================
# NEW VPC CONFIGURATION (when vpc_option = "create_new")
# =============================================================================
variable "new_vpc_cidr" {
  description = "CIDR block for new VPC (only used when vpc_option = 'create_new')"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.new_vpc_cidr, 0))
    error_message = "new_vpc_cidr must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "new_vpc_public_subnet_cidrs" {
  description = "CIDR blocks for public subnets in new VPC (only used when vpc_option = 'create_new')"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  validation {
    condition     = length(var.new_vpc_public_subnet_cidrs) >= 1 && length(var.new_vpc_public_subnet_cidrs) <= 6
    error_message = "new_vpc_public_subnet_cidrs must contain 1-6 CIDR blocks."
  }
}

variable "new_vpc_private_subnet_cidrs" {
  description = "CIDR blocks for private subnets in new VPC (only used when vpc_option = 'create_new')"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
  validation {
    condition     = length(var.new_vpc_private_subnet_cidrs) >= 1 && length(var.new_vpc_private_subnet_cidrs) <= 6
    error_message = "new_vpc_private_subnet_cidrs must contain 1-6 CIDR blocks."
  }
}

variable "new_vpc_availability_zones" {
  description = "Availability zones for new VPC subnets (only used when vpc_option = 'create_new')"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  validation {
    condition     = length(var.new_vpc_availability_zones) >= 2
    error_message = "new_vpc_availability_zones must contain at least 2 availability zones."
  }
}

# =============================================================================
# EXISTING VPC CONFIGURATION (when vpc_option = "use_existing")
# =============================================================================
variable "existing_vpc_id" {
  description = "ID of existing VPC to use (only used when vpc_option = 'use_existing')"
  type        = string
  default     = ""
  validation {
    condition     = var.existing_vpc_id == "" || can(regex("^vpc-[a-z0-9]+$", var.existing_vpc_id))
    error_message = "existing_vpc_id must be empty or a valid VPC ID (e.g., vpc-12345678)."
  }
}

variable "existing_public_subnet_ids" {
  description = "List of existing public subnet IDs to use (only used when vpc_option = 'use_existing')"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for subnet_id in var.existing_public_subnet_ids : 
      subnet_id == "" || can(regex("^subnet-[a-z0-9]+$", subnet_id))
    ])
    error_message = "All existing_public_subnet_ids must be valid subnet IDs (e.g., subnet-12345678)."
  }
}

variable "existing_private_subnet_ids" {
  description = "List of existing private subnet IDs to use (only used when vpc_option = 'use_existing')"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for subnet_id in var.existing_private_subnet_ids : 
      subnet_id == "" || can(regex("^subnet-[a-z0-9]+$", subnet_id))
    ])
    error_message = "All existing_private_subnet_ids must be valid subnet IDs (e.g., subnet-12345678)."
  }
}

# =============================================================================
# DEFAULT VPC CONFIGURATION (when vpc_option = "use_default")
# =============================================================================
# No additional variables needed - AWS default VPC and subnets are auto-detected

# =============================================================================
# EC2 CONFIGURATION - Customizable per customer tier
# =============================================================================
variable "instance_type" {
  description = "EC2 instance type for application servers"
  type        = string
  default     = "t3.medium"
  validation {
    condition     = can(regex("^[a-z0-9]+\\.[a-z0-9]+$", var.instance_type))
    error_message = "Instance type must be a valid AWS instance type (e.g., t3.medium, m5.large)."
  }
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 2
  validation {
    condition     = var.min_size >= 0 && var.min_size <= 100
    error_message = "min_size must be between 0 and 100."
  }
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 10
  validation {
    condition     = var.max_size >= 1 && var.max_size <= 100
    error_message = "max_size must be between 1 and 100."
  }
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 2
  validation {
    condition     = var.desired_capacity >= 0 && var.desired_capacity <= 100
    error_message = "desired_capacity must be between 0 and 100."
  }
}


# AMI Configuration - Separate for different components
variable "app_ami_id" {
  description = "Custom AMI ID for application servers (optional, will use latest Ubuntu 22.04 if not specified)"
  type        = string
  default     = ""
}

variable "bastion_ami_id" {
  description = "Custom AMI ID for bastion host (optional, will use latest Ubuntu 22.04 if not specified)"
  type        = string
  default     = ""
}

# SSH Access Configuration
variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH to the bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Warning: Restrict this in production
}

# =============================================================================
# DATABASE CONFIGURATION - Customizable per customer tier
# =============================================================================
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
  validation {
    condition     = can(regex("^db\\.[a-z0-9]+\\.[a-z0-9]+$", var.db_instance_class))
    error_message = "Database instance class must be a valid RDS instance type (e.g., db.t3.medium, db.r5.large)."
  }
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 65536
    error_message = "Database allocated storage must be between 20 and 65536 GB."
  }
}

variable "db_engine_version" {
  description = "Aurora MySQL engine version"
  type        = string
  default     = "8.0.mysql_aurora.3.08.0"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[a-z0-9._-]+$", var.db_engine_version))
    error_message = "Database engine version must be a valid version string."
  }
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "myapp"
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_name))
    error_message = "Database name must start with a letter and contain only alphanumeric characters and underscores."
  }
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.db_username))
    error_message = "Database username must start with a letter and contain only alphanumeric characters and underscores."
  }
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
}

# Encryption Configuration
variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption (optional, will create default if not specified)"
  type        = string
  default     = ""
}

# Aurora Read Replica Configuration
variable "read_replica_count" {
  description = "Number of Aurora read replica instances to create"
  type        = number
  default     = 0
}

variable "read_replica_instance_class" {
  description = "Instance class for Aurora read replica instances"
  type        = string
  default     = "db.t3.medium"
}

variable "enable_performance_insights" {
  description = "Whether to enable Performance Insights for RDS (disabled by default for dev environments)"
  type        = bool
  default     = false
}

# SSL Certificate Configuration
variable "certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS"
  type        = string
  default     = null
}

# GitHub Integration Configuration
variable "github_connection_arn" {
  description = "ARN of the GitHub connection for CodePipeline"
  type        = string
  default     = ""
}

variable "frontend_repository" {
  description = "GitHub repository for frontend application"
  type        = string
  default     = ""
}

variable "backend_repository" {
  description = "GitHub repository for backend application"
  type        = string
  default     = ""
}

# Monitoring Configuration
variable "sns_topic_arn" {
  description = "ARN of the SNS topic for notifications"
  type        = string
  default     = ""
}

# S3 Cross-Account Replication Configuration
variable "backup_s3_bucket_arn" {
  description = "ARN of the S3 bucket in the backup AWS account for cross-account replication"
  type        = string
  default     = ""
}

variable "backup_account_id" {
  description = "AWS Account ID of the backup account for S3 replication"
  type        = string
  default     = ""
}

variable "backup_kms_key_arn" {
  description = "ARN of the KMS key in the backup account for encryption (optional)"
  type        = string
  default     = ""
}

# =============================================================================
# APPLICATION CONFIGURATION
# =============================================================================

variable "nodejs_version" {
  description = "Node.js version to install. Use 'lts' for latest LTS (default), or specific version like '18', '20.10.0'. If empty, uses latest LTS"
  type        = string
  default     = "lts"
  validation {
    condition     = can(regex("^(--lts|[0-9]+(\\.[0-9]+)?(\\.[0-9]+)?)$", var.nodejs_version))
    error_message = "nodejs_version must be '--lts', or a valid version number (e.g., '18', '20.10.0')."
  }
}

variable "app_port" {
  description = "Port number for the Node.js application to run on. Default is 3000 (non-privileged port for security)"
  type        = number
  default     = 3000
  validation {
    condition     = var.app_port > 0 && var.app_port <= 65535
    error_message = "app_port must be a valid port number between 1 and 65535."
  }
}


# Common Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
