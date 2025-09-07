# =============================================================================
# ALB + ASG MODULE VARIABLES
# =============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "customer_name" {
  description = "Name of the customer"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# =============================================================================
# VPC CONFIGURATION
# =============================================================================

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ASG"
  type        = list(string)
}

# =============================================================================
# SSH KEY CONFIGURATION (Simplified like CloudFront keys)
# =============================================================================
# Choose ONE of the following SSH key options:
# 1. "create_new" -> Create a new SSH key pair and save to local files
# 2. "use_existing_aws" -> Use an existing SSH key pair already in AWS
# 3. "use_existing_local" -> Use an existing SSH public key from local file

variable "ssh_key_option" {
  description = "SSH key management option: 'create_new', 'use_existing_aws', or 'use_existing_local'"
  type        = string
  default     = "create_new"
  validation {
    condition     = contains(["create_new", "use_existing_aws", "use_existing_local"], var.ssh_key_option)
    error_message = "ssh_key_option must be one of: 'create_new', 'use_existing_aws', 'use_existing_local'."
  }
}

# New SSH Key Configuration (only used when ssh_key_option = "create_new")
variable "ssh_keys_directory" {
  description = "Directory to save SSH keys (only used when ssh_key_option = 'create_new')"
  type        = string
  default     = "./keys"
}

# Existing AWS SSH Key Configuration (only used when ssh_key_option = "use_existing_aws")
variable "existing_ssh_key_name" {
  description = "Name of existing SSH key pair in AWS (only used when ssh_key_option = 'use_existing_aws')"
  type        = string
  default     = ""
}

# Existing Local SSH Key Configuration (only used when ssh_key_option = "use_existing_local")
variable "existing_ssh_public_key" {
  description = "Existing SSH public key content (only used when ssh_key_option = 'use_existing_local')"
  type        = string
  default     = ""
}

# =============================================================================
# ASG CONFIGURATION
# =============================================================================

variable "instance_type" {
  description = "EC2 instance type for ASG"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 1
}

variable "app_ami_id" {
  description = "AMI ID for EC2 instances (leave empty to use latest Ubuntu 22.04)"
  type        = string
  default     = ""
}

# =============================================================================
# ALB CONFIGURATION
# =============================================================================

variable "domain_name" {
  description = "Domain name for the ALB (optional)"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS (optional)"
  type        = string
  default     = ""
}

# =============================================================================
# APPLICATION CONFIGURATION
# =============================================================================

variable "nodejs_version" {
  description = "Node.js version to install. Use 'lts' for latest LTS (default), or specific version like '18', '20.10.0'. If empty, uses latest LTS"
  type        = string
  default     = "22"
  validation {
    condition     = can(regex("^([0-9]+(\\.[0-9]+)?(\\.[0-9]+)?)$", var.nodejs_version))
    error_message = "nodejs_version must be a valid version number (e.g., '18', '20')."
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

