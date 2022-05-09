environment               = "staging"
logger_level              = "info"

// Only ever have one replica running, otherwise multiple emails will be sent!
// As multiple services will subscribe to the Redis channel
desired_count             = 1
auto_scaling_min_capacity = 1
auto_scaling_max_capacity = 1

container_port=3500
node_env="staging"
suppress_no_config_warning="true"
api_gateway_url="http://192.168.99.100:8000"
# queue_url="redis://redis" # Do not set! Is set automatically from "core" remote state in main.tf
queue_provider="redis"
queue_name="mail"
sparkpost_api_key="overridden_in_github_secrets"
healthcheck_path = "/v1/fw_mail/healthcheck"
healthcheck_sns_emails = ["server@3sidedcube.com"]