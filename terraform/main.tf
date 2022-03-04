terraform {
  backend "s3" {
    region  = "us-east-1"
    key     = "wri__fw_mail.tfstate"
    encrypt = true
  }
}

provider "aws" {
  region = var.region
}


# Docker image for FW Template app
module "app_docker_image" {
  source     = "git::https://github.com/wri/gfw-terraform-modules.git//terraform/modules/container_registry?ref=v0.5.1"
  image_name = lower("${var.project_prefix}-docker")
  root_dir   = "${path.root}/../"
  tag        = local.container_tag
}

module "fargate_autoscaling" {
  source                       = "git::https://github.com/wri/gfw-terraform-modules.git//terraform/modules/fargate_autoscaling_v2?ref=v0.5.5"
  project                      = var.project_prefix
  tags                         = local.fargate_tags
  vpc_id                       = data.terraform_remote_state.core.outputs.vpc_id
  private_subnet_ids           = data.terraform_remote_state.core.outputs.private_subnet_ids
  public_subnet_ids            = data.terraform_remote_state.core.outputs.public_subnet_ids
  container_name               = var.project_prefix
  container_port               = var.container_port
  desired_count                = var.desired_count
  fargate_cpu                  = var.fargate_cpu
  fargate_memory               = var.fargate_memory
  auto_scaling_cooldown        = var.auto_scaling_cooldown
  auto_scaling_max_capacity    = var.auto_scaling_max_capacity
  auto_scaling_max_cpu_util    = var.auto_scaling_max_cpu_util
  auto_scaling_min_capacity    = var.auto_scaling_min_capacity
  load_balancer_arn            = data.terraform_remote_state.fw_core.outputs.lb_arn
  load_balancer_security_group = data.terraform_remote_state.fw_core.outputs.lb_security_group_id
  cluster_id                   = data.terraform_remote_state.fw_core.outputs.ecs_cluster_id
  cluster_name                 = data.terraform_remote_state.fw_core.outputs.ecs_cluster_name
  security_group_ids           = [data.terraform_remote_state.core.outputs.document_db_security_group_id, data.terraform_remote_state.core.outputs.redis_security_group_id]
  task_role_policies = [
    data.terraform_remote_state.fw_core.outputs.data_bucket_write_policy_arn
  ]
  task_execution_role_policies = [
    data.terraform_remote_state.core.outputs.document_db_secrets_policy_arn,
  ]
  container_definition = data.template_file.container_definition.rendered

  # Listener rule inputs
  lb_target_group_arn = module.fargate_autoscaling.lb_target_group_arn
  listener_arn        = data.terraform_remote_state.fw_core.outputs.lb_listener_arn
  project_prefix      = var.project_prefix
  path_pattern        = ["/v1/fw_mail/healthcheck"]
  health_check_path   = "/v1/fw_mail/healthcheck"
  priority            = 7

  depends_on = [
    module.app_docker_image
  ]
}


data "template_file" "container_definition" {
  template = file("${path.root}/templates/container_definition.json.tmpl")
  vars = {
    # Required to deploy container
    container_name = var.project_prefix
    image          = "${module.app_docker_image.repository_url}:${local.container_tag}"
    container_port = var.container_port
    log_group      = aws_cloudwatch_log_group.default.name
    aws_region     = var.region
    environment    = var.environment

    # Environment variables
    port                       = var.container_port
    node_path                  = var.node_path
    node_env                   = var.node_env
    logger_level               = var.logger_level
    suppress_no_config_warning = var.suppress_no_config_warning
    api_gateway_url            = var.api_gateway_url
    queue_url                  = "redis://${data.terraform_remote_state.core.outputs.redis_replication_group_primary_endpoint_address}"
    queue_provider             = var.queue_provider
    queue_name                 = var.queue_name
    sparkpost_api_key          = var.sparkpost_api_key

    # Secrets
    # none
  }

}


#
# CloudWatch Resources
#
resource "aws_cloudwatch_log_group" "default" {
  name              = "/aws/ecs/${var.project_prefix}-logs"
  retention_in_days = var.log_retention
}

#
# Route53 Healthcheck Resources
#
resource "aws_route53_health_check" "healthcheck" {
  fqdn              = data.terraform_remote_state.fw_core.outputs.public_url
  port              = 443
  type              = "HTTPS"
  resource_path     = "/v1/teams/healthchek"
  failure_threshold = "5"
  request_interval  = "30"

  tags = {
    Name = "${var.project_prefix}-rt53-health-check"
  }
}

resource "aws_sns_topic" "healthcheck_updates" {
  name = "${var.project_prefix}_healthcheck"
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
  count     = length(var.healthceck_sns_emails)
  topic_arn = aws_sns_topic.healthcheck_updates.arn
  protocol  = "email"
  endpoint  = var.healthceck_sns_emails[count.index]
}

resource "aws_cloudwatch_metric_alarm" "healthcheck_failed" {
  alarm_name          = "${var.project_prefix}_healthcheck_failed"
  namespace           = "AWS/Route53"
  metric_name         = "HealthCheckStatus"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  unit                = "None"
  dimensions = {
    HealthCheckId = "${aws_route53_health_check.healthcheck.id}"
  }
  alarm_description         = "This metric monitors whether the service endpoint is down or not."
  alarm_actions             = ["${aws_sns_topic.healthcheck_updates.arn}"]
  insufficient_data_actions = ["${aws_sns_topic.healthcheck_updates.arn}"]
  treat_missing_data        = "breaching"
  depends_on                = [aws_route53_health_check.healthcheck]
}