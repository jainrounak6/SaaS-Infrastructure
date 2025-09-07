# =============================================================================
# VPC MODULE VARIABLES
# =============================================================================

variable "vpc_option" {
  description = "VPC deployment option: 'create_new', 'use_existing', or 'use_default'"
  type        = string
  validation {
    condition     = contains(["create_new", "use_existing", "use_default"], var.vpc_option)
    error_message = "vpc_option must be one of: 'create_new', 'use_existing', 'use_default'."
  }
}

variable "project_name" {
  description = "Name of the project"
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
# NEW VPC CONFIGURATION (when vpc_option = "create_new")
# =============================================================================

variable "new_vpc_cidr" {
  description = "CIDR block for new VPC (only used when vpc_option = 'create_new')"
  type        = string
  default     = "10.0.0.0/16"
}

variable "new_vpc_public_subnet_cidrs" {
  description = "CIDR blocks for public subnets in new VPC (only used when vpc_option = 'create_new')"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "new_vpc_private_subnet_cidrs" {
  description = "CIDR blocks for private subnets in new VPC (only used when vpc_option = 'create_new')"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "new_vpc_availability_zones" {
  description = "Availability zones for new VPC subnets (only used when vpc_option = 'create_new')"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# =============================================================================
# EXISTING VPC CONFIGURATION (when vpc_option = "use_existing")
# =============================================================================

variable "existing_vpc_id" {
  description = "ID of existing VPC to use (only used when vpc_option = 'use_existing')"
  type        = string
  default     = ""
}

variable "existing_public_subnet_ids" {
  description = "List of existing public subnet IDs to use (only used when vpc_option = 'use_existing')"
  type        = list(string)
  default     = []
}

variable "existing_private_subnet_ids" {
  description = "List of existing private subnet IDs to use (only used when vpc_option = 'use_existing')"
  type        = list(string)
  default     = []
}