#
# Route53 Healthcheck Resources
#
resource "aws_route53_health_check" "healthcheck" {
  fqdn              = var.healthcheck_fqdn
  port              = var.healthcheck_port
  type              = var.healthcheck_protocol
  resource_path     = var.healthcheck_path
  failure_threshold = "5"
  request_interval  = "30"

  tags = {
    Name = "${var.prefix}-rt53-health_check"
  }
}

resource "aws_sns_topic" "healthcheck_updates" {
  name = "${var.prefix}_healthcheck"
  delivery_policy = jsonencode({
    "http" : {
      "defaultHealthyRetryPolicy" : {
        "minDelayTarget" : 20,
        "maxDelayTarget" : 20,
        "numRetries" : 3,
        "numMaxDelayRetries" : 0,
        "numNoDelayRetries" : 0,
        "numMinDelayRetries" : 0,
        "backoffFunction" : "linear"
      },
      "disableSubscriptionOverrides" : false,
      "defaultThrottlePolicy" : {
        "maxReceivesPerSecond" : 1
      }
    }
  })
}

resource "aws_sns_topic_subscription" "topic_email_subscription" {
  count     = length(var.forward_emails)
  topic_arn = aws_sns_topic.healthcheck_updates.arn
  protocol  = "email"
  endpoint  = var.forward_emails[count.index]
  depends_on = [
    aws_sns_topic.healthcheck_updates
  ]
}

resource "aws_cloudwatch_metric_alarm" "healthcheck_failed" {
  alarm_name          = "${var.prefix}_healthcheck_failed"
  namespace           = "AWS/Route53"
  metric_name         = "HealthCheckStatus"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  unit                = "None"
  dimensions = {
    HealthCheckId = aws_route53_health_check.healthcheck.id
  }
  alarm_description         = "This metric monitors whether the service endpoint is down or not."
  alarm_actions             = [aws_sns_topic.healthcheck_updates.arn]
  insufficient_data_actions = [aws_sns_topic.healthcheck_updates.arn]
  treat_missing_data        = "breaching"
  depends_on                = [aws_route53_health_check.healthcheck]
}