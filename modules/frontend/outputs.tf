# =============================================================================
# FRONTEND MODULE OUTPUTS
# =============================================================================

output "frontend_bucket_id" {
  description = "ID of the frontend S3 bucket"
  value       = aws_s3_bucket.frontend.id
}

output "frontend_bucket_name" {
  description = "Name of the frontend S3 bucket"
  value       = aws_s3_bucket.frontend.bucket
}

output "frontend_bucket_arn" {
  description = "ARN of the frontend S3 bucket"
  value       = aws_s3_bucket.frontend.arn
}

output "frontend_bucket_domain_name" {
  description = "Domain name of the frontend S3 bucket"
  value       = aws_s3_bucket.frontend.bucket_domain_name
}

output "frontend_bucket_regional_domain_name" {
  description = "Regional domain name of the frontend S3 bucket"
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}

output "frontend_cloudfront_distribution_id" {
  description = "ID of the frontend CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.id
}

output "frontend_cloudfront_distribution_arn" {
  description = "ARN of the frontend CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.arn
}

output "frontend_cloudfront_domain_name" {
  description = "Domain name of the frontend CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "frontend_cloudfront_hosted_zone_id" {
  description = "CloudFront Route 53 zone ID"
  value       = aws_cloudfront_distribution.frontend.hosted_zone_id
}
