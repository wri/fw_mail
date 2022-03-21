
variable "prefix" {
  type = string
}
variable "healthcheck_fqdn" {
  type = string
}
variable "healthcheck_path" {
  type = string
}
variable "healthcheck_port" {
  type    = number
  default = 443
}
variable "healthcheck_protocol" {
  type    = string
  default = "HTTPS"
}
variable "forward_emails" {
  type    = list(string)
  default = []
}