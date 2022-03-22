environment               = "production"
log_level                 = "info"
desired_count             = 2
auto_scaling_min_capacity = 2
auto_scaling_max_capacity = 15

node_env                  = "production"
sparkpost_api_key         = "overridden_in_github_secrets"