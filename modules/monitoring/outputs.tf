output "main_dashboard_name" {
  description = "Name of the main CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "main_dashboard_arn" {
  description = "ARN of the main CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_arn
}

output "application_log_groups" {
  description = "Names of the application log groups"
  value       = [for group in aws_cloudwatch_log_group.application_logs : group.name]
}

output "alb_log_group_name" {
  description = "Name of the ALB log group"
  value       = aws_cloudwatch_log_group.alb_logs.name
}

output "rds_log_group_name" {
  description = "Name of the RDS log group"
  value       = aws_cloudwatch_log_group.rds_logs.name
}

output "high_error_rate_alarm_name" {
  description = "Name of the high error rate alarm"
  value       = aws_cloudwatch_metric_alarm.high_error_rate.alarm_name
}

output "high_response_time_alarm_name" {
  description = "Name of the high response time alarm"
  value       = aws_cloudwatch_metric_alarm.high_response_time.alarm_name
}

output "low_healthy_hosts_alarm_name" {
  description = "Name of the low healthy hosts alarm"
  value       = aws_cloudwatch_metric_alarm.low_healthy_hosts.alarm_name
}
