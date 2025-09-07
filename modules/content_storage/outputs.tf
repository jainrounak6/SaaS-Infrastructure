# =============================================================================
# CONTENT STORAGE MODULE OUTPUTS
# =============================================================================

# Public Content Bucket Outputs
output "public_content_bucket_id" {
  description = "ID of the public content S3 bucket"
  value       = aws_s3_bucket.public_content.id
}

output "public_content_bucket_name" {
  description = "Name of the public content S3 bucket"
  value       = aws_s3_bucket.public_content.bucket
}

output "public_content_bucket_arn" {
  description = "ARN of the public content S3 bucket"
  value       = aws_s3_bucket.public_content.arn
}

output "public_content_cloudfront_distribution_id" {
  description = "ID of the public content CloudFront distribution"
  value       = aws_cloudfront_distribution.public_content.id
}

output "public_content_cloudfront_domain_name" {
  description = "Domain name of the public content CloudFront distribution"
  value       = aws_cloudfront_distribution.public_content.domain_name
}

# Private Content Bucket Outputs
output "private_content_bucket_id" {
  description = "ID of the private content S3 bucket"
  value       = aws_s3_bucket.private_content.id
}

output "private_content_bucket_name" {
  description = "Name of the private content S3 bucket"
  value       = aws_s3_bucket.private_content.bucket
}

output "private_content_bucket_arn" {
  description = "ARN of the private content S3 bucket"
  value       = aws_s3_bucket.private_content.arn
}

output "private_content_cloudfront_distribution_id" {
  description = "ID of the private content CloudFront distribution"
  value       = aws_cloudfront_distribution.private_content.id
}

output "private_content_cloudfront_domain_name" {
  description = "Domain name of the private content CloudFront distribution"
  value       = aws_cloudfront_distribution.private_content.domain_name
}

# Pre-signed URL Role Outputs
output "cloudfront_public_key_id" {
  description = "ID of the CloudFront public key for signed URLs"
  value       = local.cloudfront_public_key_id
}

output "cloudfront_key_group_id" {
  description = "ID of the CloudFront key group for signed URLs"
  value       = aws_cloudfront_key_group.private_content.id
}

output "cloudfront_public_key_name" {
  description = "Name of the CloudFront public key for signed URLs"
  value       = var.use_existing_cloudfront_public_key ? var.existing_cloudfront_public_key_id : aws_cloudfront_public_key.private_content[0].name
}

output "cloudfront_key_group_name" {
  description = "Name of the CloudFront key group for signed URLs"
  value       = aws_cloudfront_key_group.private_content.name
}

# CloudFront Key Generation Outputs (only when generating new keys)
output "cloudfront_private_key_pem" {
  description = "The CloudFront private key in PEM format"
  value       = var.use_existing_cloudfront_public_key ? null : tls_private_key.cloudfront_key[0].private_key_pem
  sensitive   = true
}

output "cloudfront_private_key_file_path" {
  description = "Path to the saved CloudFront private key file"
  value       = var.use_existing_cloudfront_public_key ? null : "${var.cloudfront_keys_directory}/${var.customer_name}/${var.environment}/${var.project_name}-${var.environment}-cloudfront-private.pem"
}

output "cloudfront_public_key_file_path" {
  description = "Path to the saved CloudFront public key file"
  value       = var.use_existing_cloudfront_public_key ? null : "${var.cloudfront_keys_directory}/${var.customer_name}/${var.environment}/${var.project_name}-${var.environment}-cloudfront-public.pem"
}

output "cloudfront_keys_directory" {
  description = "Directory where CloudFront keys are saved"
  value       = var.cloudfront_keys_directory
}

# Versioning outputs for replication
output "public_content_bucket_versioning" {
  description = "Versioning configuration of the public content bucket"
  value       = aws_s3_bucket_versioning.public_content
}

output "private_content_bucket_versioning" {
  description = "Versioning configuration of the private content bucket"
  value       = aws_s3_bucket_versioning.private_content
}

