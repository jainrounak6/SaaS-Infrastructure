# CloudWatch Dashboard for comprehensive monitoring
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-main-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Row 1: System Overview
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name],
            [".", "NetworkIn", ".", "."],
            [".", "NetworkOut", ".", "."],
            [".", "DiskReadOps", ".", "."],
            [".", "DiskWriteOps", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "EC2 System Overview"
        }
      },

      # Row 2: Application Performance
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HealthyHostCount", ".", "."],
            [".", "UnHealthyHostCount", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Load Balancer Performance"
        }
      },

      # Row 2: Application Health
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", var.alb_arn_suffix],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."],
            [".", "HTTPCode_ELB_4XX_Count", ".", "."],
            [".", "HTTPCode_ELB_5XX_Count", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "HTTP Response Codes"
        }
      },

      # Row 3: Custom Metrics (CloudWatch Agent)
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["CWAgent", "mem_used_percent", "AutoScalingGroupName", var.asg_name],
            [".", "disk_used_percent", ".", "."],
            [".", "swap_used_percent", ".", "."],
            [".", "tcp_established", ".", "."],
            [".", "tcp_listen", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "System Resources (CloudWatch Agent)"
        }
      },

      # Row 3: Process Monitoring
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["CWAgent", "cpu_usage", "AutoScalingGroupName", var.asg_name, "procstat", "nginx"],
            [".", "memory_rss", ".", ".", ".", "."],
            [".", "num_threads", ".", ".", ".", "."],
            [".", "cpu_usage", ".", ".", "procstat", "node"],
            [".", "memory_rss", ".", ".", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Process Monitoring (Nginx + Node.js)"
        }
      },

      # Row 4: Database Performance
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_id],
            [".", "DatabaseConnections", ".", "."],
            [".", "FreeableMemory", ".", "."],
            [".", "FreeStorageSpace", ".", "."],
            [".", "ReadIOPS", ".", "."],
            [".", "WriteIOPS", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "RDS Database Performance"
        }
      },

      # Row 4: S3 and CloudFront
      {
        type   = "metric"
        x      = 12
        y      = 18
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/S3", "NumberOfObjects", "BucketName", var.frontend_bucket_name],
            [".", "BucketSizeBytes", ".", "."],
            ["AWS/CloudFront", "Requests", "DistributionId", var.cloudfront_distribution_id],
            [".", "BytesDownloaded", ".", "."],
            [".", "BytesUploaded", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = data.aws_region.current.name
          title  = "Storage and CDN Metrics"
        }
      }
    ]
  })
}

# CloudWatch Log Groups for centralized logging
resource "aws_cloudwatch_log_group" "application_logs" {
  for_each = toset([
    "/aws/ec2/${var.project_name}-${var.environment}/nginx/access",
    "/aws/ec2/${var.project_name}-${var.environment}/nginx/error",
    "/aws/ec2/${var.project_name}-${var.environment}/pm2/error",
    "/aws/ec2/${var.project_name}-${var.environment}/pm2/out",
    "/aws/ec2/${var.project_name}-${var.environment}/pm2/combined",
    "/aws/ec2/${var.project_name}-${var.environment}/application/app",
    "/aws/ec2/${var.project_name}-${var.environment}/system/syslog",
    "/aws/ec2/${var.project_name}-${var.environment}/system/auth"
  ])

  name              = each.value
  retention_in_days = 30

  tags = {
    Name        = each.value
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Group for ALB logs
resource "aws_cloudwatch_log_group" "alb_logs" {
  name              = "/aws/applicationloadbalancer/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = {
    Name        = "/aws/applicationloadbalancer/${var.project_name}-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Group for RDS logs
resource "aws_cloudwatch_log_group" "rds_logs" {
  name              = "/aws/rds/instance/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = {
    Name        = "/aws/rds/instance/${var.project_name}-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Enhanced CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${var.project_name}-${var.environment}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_description = "Alert if 5XX errors exceed 10 in 10 minutes"
  alarm_actions     = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  tags = {
    Name        = "${var.project_name}-${var.environment}-high-error-rate-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_metric_alarm" "high_response_time" {
  alarm_name          = "${var.project_name}-${var.environment}-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "2"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_description = "Alert if average response time exceeds 2 seconds"
  alarm_actions     = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  tags = {
    Name        = "${var.project_name}-${var.environment}-high-response-time-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_healthy_hosts" {
  alarm_name          = "${var.project_name}-${var.environment}-low-healthy-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_description = "Alert if healthy host count drops below 1"
  alarm_actions     = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  tags = {
    Name        = "${var.project_name}-${var.environment}-low-healthy-hosts-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Get current AWS region
data "aws_region" "current" {}
