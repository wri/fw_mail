environment               = "dev"
logger_level              = "debug"
desired_count             = 1
auto_scaling_min_capacity = 1
auto_scaling_max_capacity = 5

container_port             = 3500
node_path                  = "app/src"
node_env                   = "dev"
suppress_no_config_warning = "true"
api_gateway_url            = "http://192.168.99.100:8000"
queue_provider             = "redis"
queue_name                 = "mail"
sparkpost_api_key          = "notset"

healthcheck_sns_emails = []

# queue_url="redis://redis" # Do not set! Is set automatically from "core" remote state in main.tf