# =============================================================================
# CONTENT STORAGE MODULE VARIABLES
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
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
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

