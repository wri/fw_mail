variable "project_prefix" {
  type    = string
  default = "fw-mail"
}

variable "environment" {
  type        = string
  description = "An environment namespace for the infrastructure."
}

variable "region" {
  default = "us-east-1"
  type    = string
}

variable "container_port" {
  default = 80
  type    = number
}
variable "logger_level" {
  type = string
}
variable "log_retention" {
  type    = number
  default = 30
}
variable "desired_count" {
  type = number
}
variable "fargate_cpu" {
  type    = number
  default = 256
}
variable "fargate_memory" {
  type    = number
  default = 512
}
variable "auto_scaling_cooldown" {
  type    = number
  default = 300
}
variable "auto_scaling_max_capacity" {
  type = number
}
variable "auto_scaling_max_cpu_util" {
  type    = number
  default = 75
}
variable "auto_scaling_min_capacity" {
  type = number
}
variable "git_sha" {
  type = string
}

variable "node_path" {
  type    = string
  default = "app/src"
}
variable "node_env" {
  type    = string
  default = "dev"
}
variable "suppress_no_config_warning" {
  type    = string
  default = "true"
}
variable "api_gateway_url" {
  type    = string
  default = "http://192.168.99.100:8000"
}
# variable "queue_url" {
#   type    = string
#   default = "redis://redis"
# }
variable "queue_provider" {
  type    = string
  default = "redis"
}
variable "queue_name" {
  type    = string
  default = "mail"
}
variable "sparkpost_api_key" {
  type    = string
  default = "notset"
}

variable "healthceck_sns_emails" {
  type    = list(string)
  default = []
}