# =============================================================================
# ALB + ASG MODULE - Unified Application Load Balancer and Auto Scaling Group
# =============================================================================
# This module creates ALB and ASG together since they are tightly coupled
# ALB without ASG is not useful, and ASG without ALB loses load balancing

# =============================================================================
# SSH KEY MANAGEMENT (Simplified like CloudFront keys)
# =============================================================================

# Create RSA Private Key for SSH (only when not using existing key)
resource "tls_private_key" "ssh_key" {
  count     = var.ssh_key_option == "create_new" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save Private Key to Local File (only when generating new key)
resource "local_file" "ssh_private_key" {
  count    = var.ssh_key_option == "create_new" ? 1 : 0
  content  = tls_private_key.ssh_key[0].private_key_openssh
  filename = "${var.ssh_keys_directory}/${var.customer_name}/${var.environment}/${var.project_name}-${var.environment}-ssh-private.pem"
  
  file_permission = "0600"
  
  depends_on = [tls_private_key.ssh_key]
}

# Save Public Key to Local File (only when generating new key)
resource "local_file" "ssh_public_key" {
  count    = var.ssh_key_option == "create_new" ? 1 : 0
  content  = tls_private_key.ssh_key[0].public_key_openssh
  filename = "${var.ssh_keys_directory}/${var.customer_name}/${var.environment}/${var.project_name}-${var.environment}-ssh-public.pem"
  
  file_permission = "0644"
  
  depends_on = [tls_private_key.ssh_key]
}

# Create AWS Key Pair (create new or use existing)
resource "aws_key_pair" "ssh_key" {
  count      = var.ssh_key_option == "use_existing_aws" ? 0 : 1
  key_name   = var.ssh_key_option == "create_new" ? "${var.project_name}-${var.environment}-ssh-key" : var.existing_ssh_key_name
  public_key = var.ssh_key_option == "create_new" ? tls_private_key.ssh_key[0].public_key_openssh : var.existing_ssh_public_key

  tags = merge(var.common_tags, {
    Name        = var.ssh_key_option == "create_new" ? "${var.project_name}-${var.environment}-ssh-key" : var.existing_ssh_key_name
    Purpose     = "ec2-ssh-access"
    Module      = "alb_asg"
  })

  lifecycle {
    prevent_destroy = false
  }
}

# Local variable to handle SSH key name
locals {
  ssh_key_name = var.ssh_key_option == "use_existing_aws" ? var.existing_ssh_key_name : aws_key_pair.ssh_key[0].key_name
}

# =============================================================================
# APPLICATION LOAD BALANCER
# =============================================================================

# ALB Security Group
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  vpc_id      = var.vpc_id
  description = "Security group for Application Load Balancer"

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-alb-sg"
    Purpose     = "alb-security-group"
    Module      = "alb_asg"
  })
}

# ALB Logs S3 Bucket
resource "aws_s3_bucket" "alb_logs" {
  bucket        = "${var.project_name}-${var.environment}-alb-logs-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-alb-logs"
    Purpose     = "alb-access-logs"
    Module      = "alb_asg"
  })
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "alb_logs_lifecycle"
    status = "Enabled"

    expiration {
      days = 365
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }

  rule {
    id     = "delete_all_versions"
    status = "Enabled"

    expiration {
      days                         = 0
      expired_object_delete_marker = true
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.alb_logs.arn
      }
    ]
  })
}

data "aws_elb_service_account" "main" {}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.id
    prefix  = "alb-logs"
    enabled = true
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-alb"
    Purpose     = "application-load-balancer"
    Module      = "alb_asg"
  })
}

# Single Target Group for Node.js App (Optimized Approach)
resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-${var.environment}-app-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-app-tg"
    Purpose     = "nodejs-app-target-group"
    Module      = "alb_asg"
  })
}

# HTTP Listener (redirects to HTTPS)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = merge(var.common_tags, {
    Purpose = "http-listener"
    Module  = "alb_asg"
  })
}

# HTTPS Listener (when ACM certificate is available)
resource "aws_lb_listener" "https" {
  count             = var.acm_certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = merge(var.common_tags, {
    Purpose = "https-listener"
    Module  = "alb_asg"
  })
}

# =============================================================================
# AUTO SCALING GROUP
# =============================================================================

# EC2 Security Group
resource "aws_security_group" "ec2" {
  name_prefix = "${var.project_name}-${var.environment}-ec2-"
  vpc_id      = var.vpc_id
  description = "Security group for EC2 instances"

  ingress {
    description     = "HTTP from ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "HTTPS from ALB"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "SSH from user IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["49.43.1.188/32"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-ec2-sg"
    Purpose     = "ec2-security-group"
    Module      = "alb_asg"
  })
}

# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-ec2-role"
    Purpose     = "ec2-iam-role"
    Module      = "alb_asg"
  })
}

# IAM Policy for Secrets Manager access
resource "aws_iam_policy" "secrets_access" {
  name = "${var.project_name}-${var.environment}-secrets-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-secrets-access"
    Purpose     = "secrets-manager-access"
    Module      = "alb_asg"
  })
}

# Attach policies to role
resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "secrets_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-ec2-profile"
    Purpose     = "ec2-instance-profile"
    Module      = "alb_asg"
  })
}

# Launch Template
resource "aws_launch_template" "main" {
  name_prefix   = "${var.project_name}-${var.environment}-"
  image_id      = var.app_ami_id
  instance_type = var.instance_type
  key_name      = local.ssh_key_name

  vpc_security_group_ids = [aws_security_group.ec2.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name   = var.project_name
    environment    = var.environment
    customer_name  = var.customer_name
    nodejs_version = var.nodejs_version
    app_port       = var.app_port
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Name        = "${var.project_name}-${var.environment}-ec2"
      Purpose     = "ec2-instance"
      Module      = "alb_asg"
    })
  }

  tags = merge(var.common_tags, {
    Purpose = "launch-template"
    Module  = "alb_asg"
  })
}

# Auto Scaling Group
resource "aws_autoscaling_group" "main" {
  name                = "${var.project_name}-${var.environment}-asg"
  vpc_zone_identifier = length(var.private_subnet_ids) > 0 ? var.private_subnet_ids : var.public_subnet_ids
  target_group_arns   = [aws_lb_target_group.app.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 1
      on_demand_percentage_above_base_capacity = 50
      spot_allocation_strategy                 = "capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.main.id
        version            = "$Latest"
      }

      override {
        instance_type = var.instance_type
      }
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }
}

# Auto Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-${var.environment}-scale-up"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.main.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-${var.environment}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.main.name
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-high-cpu"
    Purpose     = "cpu-scaling-alarm"
    Module      = "alb_asg"
  })
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "20"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-low-cpu"
    Purpose     = "cpu-scaling-alarm"
    Module      = "alb_asg"
  })
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "alb" {
  dashboard_name = "${var.project_name}-${var.environment}-alb-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "ALB Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", aws_autoscaling_group.main.name],
            [".", "GroupInServiceInstances", ".", "."],
            [".", "GroupTotalInstances", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "ASG Metrics"
          period  = 300
        }
      }
    ]
  })

  # CloudWatch Dashboard doesn't support tags
}

# Data sources
data "aws_region" "current" {}
