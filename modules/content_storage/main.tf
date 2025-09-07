# =============================================================================
# CONTENT STORAGE MODULE
# =============================================================================
# This module creates S3 buckets and CloudFront distributions for content storage
# with pre-signed URL support

# S3 Bucket for Public Content (with CDN)
resource "aws_s3_bucket" "public_content" {
  bucket        = "${var.project_name}-${var.environment}-public-content"
  force_destroy = true  # Allow bucket deletion even with objects

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-public-content"
    Purpose     = "public-content-storage"
    Module      = "content_storage"
    AccessType  = "public"
  })
}

# S3 Bucket for Private Content (with pre-signed URLs)
resource "aws_s3_bucket" "private_content" {
  bucket        = "${var.project_name}-${var.environment}-private-content"
  force_destroy = true  # Allow bucket deletion even with objects

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-private-content"
    Purpose     = "private-content-storage"
    Module      = "content_storage"
    AccessType  = "private"
  })
}

# S3 Bucket Versioning for Public Content
resource "aws_s3_bucket_versioning" "public_content" {
  bucket = aws_s3_bucket.public_content.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Versioning for Private Content
resource "aws_s3_bucket_versioning" "private_content" {
  bucket = aws_s3_bucket.private_content.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server Side Encryption for Public Content
resource "aws_s3_bucket_server_side_encryption_configuration" "public_content" {
  bucket = aws_s3_bucket.public_content.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Server Side Encryption for Private Content
resource "aws_s3_bucket_server_side_encryption_configuration" "private_content" {
  bucket = aws_s3_bucket.private_content.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block for Public Content
resource "aws_s3_bucket_public_access_block" "public_content" {
  bucket = aws_s3_bucket.public_content.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Public Access Block for Private Content
resource "aws_s3_bucket_public_access_block" "private_content" {
  bucket = aws_s3_bucket.private_content.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Origin Access Control for Public Content
resource "aws_cloudfront_origin_access_control" "public_content" {
  name                              = "${var.project_name}-${var.environment}-public-content-oac"
  description                       = "OAC for public content S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Origin Access Control for Private Content
resource "aws_cloudfront_origin_access_control" "private_content" {
  name                              = "${var.project_name}-${var.environment}-private-content-oac"
  description                       = "OAC for private content S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution for Public Content
resource "aws_cloudfront_distribution" "public_content" {
  origin {
    domain_name              = aws_s3_bucket.public_content.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.public_content.id
    origin_id                = "S3-${aws_s3_bucket.public_content.bucket}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${var.project_name} public content"

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.public_content.bucket}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400  # 24 hours for content
    max_ttl     = 31536000  # 1 year
  }

  price_class = var.environment == "prod" ? "PriceClass_All" : "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # HTTP/2 and HTTP/3 support
  http_version = "http2and3"

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-${var.environment}-public-content-cdn"
    Purpose = "public-content-cdn"
    Module  = "content_storage"
  })
}

# CloudFront Distribution for Private Content
resource "aws_cloudfront_distribution" "private_content" {
  origin {
    domain_name              = aws_s3_bucket.private_content.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.private_content.id
    origin_id                = "S3-${aws_s3_bucket.private_content.bucket}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${var.project_name} private content"

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.private_content.bucket}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600   # 1 hour for private content (shorter cache)
    max_ttl     = 86400  # 24 hours max

    # Restrict viewer access for signed URLs
    trusted_key_groups = [aws_cloudfront_key_group.private_content.id]
  }

  price_class = var.environment == "prod" ? "PriceClass_All" : "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # HTTP/2 and HTTP/3 support
  http_version = "http2and3"

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-${var.environment}-private-content-cdn"
    Purpose = "private-content-cdn"
    Module  = "content_storage"
  })
}

# S3 Bucket Policy for Public Content CloudFront
resource "aws_s3_bucket_policy" "public_content" {
  bucket = aws_s3_bucket.public_content.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.public_content.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.public_content.arn
          }
        }
      }
    ]
  })
}

# S3 Bucket Policy for Private Content CloudFront
resource "aws_s3_bucket_policy" "private_content" {
  bucket = aws_s3_bucket.private_content.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.private_content.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.private_content.arn
          }
        }
      }
    ]
  })
}

# Create RSA Private Key for CloudFront Signed URLs (only when not using existing key)
resource "tls_private_key" "cloudfront_key" {
  count     = var.use_existing_cloudfront_public_key ? 0 : 1
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Save Private Key to Local File (only when generating new key)
resource "local_file" "private_key" {
  count    = var.use_existing_cloudfront_public_key ? 0 : 1
  content  = tls_private_key.cloudfront_key[0].private_key_pem
  filename = "${var.cloudfront_keys_directory}/${var.customer_name}/${var.environment}/${var.project_name}-${var.environment}-cloudfront-private.pem"
  
  file_permission = "0600"
  
  depends_on = [tls_private_key.cloudfront_key]
}

# Save Public Key to Local File (only when generating new key)
resource "local_file" "public_key" {
  count    = var.use_existing_cloudfront_public_key ? 0 : 1
  content  = tls_private_key.cloudfront_key[0].public_key_pem
  filename = "${var.cloudfront_keys_directory}/${var.customer_name}/${var.environment}/${var.project_name}-${var.environment}-cloudfront-public.pem"
  
  file_permission = "0644"
  
  depends_on = [tls_private_key.cloudfront_key]
}

# CloudFront Public Key for Signed URLs (create new or use existing)
resource "aws_cloudfront_public_key" "private_content" {
  count = var.use_existing_cloudfront_public_key ? 0 : 1
  
  comment     = "Public key for ${var.project_name} private content signed URLs"
  encoded_key = var.cloudfront_public_key != "" ? var.cloudfront_public_key : tls_private_key.cloudfront_key[0].public_key_pem
  name        = "${var.project_name}-${var.environment}-private-content-key"
}

# Local variable to handle existing CloudFront public key ID
locals {
  cloudfront_public_key_id = var.use_existing_cloudfront_public_key ? var.existing_cloudfront_public_key_id : aws_cloudfront_public_key.private_content[0].id
}

# CloudFront Key Group for Signed URLs
resource "aws_cloudfront_key_group" "private_content" {
  comment = "Key group for ${var.project_name} private content signed URLs"
  items   = [local.cloudfront_public_key_id]
  name    = "${var.project_name}-${var.environment}-private-content-key-group"
}

# S3 Bucket Lifecycle Configuration for Public Content
resource "aws_s3_bucket_lifecycle_configuration" "public_content" {
  bucket = aws_s3_bucket.public_content.id

  rule {
    id     = "public_content_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 90  # Longer retention for content
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# S3 Bucket Lifecycle Configuration for Private Content
resource "aws_s3_bucket_lifecycle_configuration" "private_content" {
  bucket = aws_s3_bucket.private_content.id

  rule {
    id     = "private_content_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 365  # Longer retention for private content
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
