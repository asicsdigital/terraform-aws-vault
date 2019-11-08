variable "alb_log_bucket" {
  description = "s3 bucket to send ALB Logs"
}

variable "vault_image" {
  description = "Image to use when deploying vault, defaults to the hashicorp vault image"
  default     = "vault:latest"
}

variable "cloudwatch_log_retention" {
  default     = "30"
  description = "Specifies the number of days you want to retain log events in the specified log group. (defaults to 30)"
}

variable "desired_count" {
  description = "Number of vaults that ECS should run."
  default     = "2"
}

variable "dns_zone" {
  description = "Zone where the Consul UI alb will be created. This should *not* be consul.example.com"
  default     = ""
}

variable "ecs_cluster_ids" {
  type        = list(string)
  description = "List of ARNs of the ECS Cluster IDs"
}

variable "env" {
}

variable "hostname" {
  description = "DNS Hostname for the bastion host. Defaults to $${VPC NAME}.$${dns_zone} if hostname is not set"
  default     = ""
}

variable "iam_path" {
  default     = "/"
  description = "IAM path, this is useful when creating resources with the same name across multiple regions. Defaults to /"
}

variable "lb_deregistration_delay" {
  default     = "300"
  description = "The amount time for Elastic Load Balancing to wait before changing the state of a deregistering target from draining to unused. The range is 0-3600 seconds. (Default: 300)"
}

variable "service_minimum_healthy_percent" {
  description = "The minimum healthy percent represents a lower limit on the number of your service's tasks that must remain in the RUNNING state during a deployment (default 50)"
  default     = "50"
}

variable "subnets" {
  type        = list(string)
  description = "List of subnets used to deploy the Consul alb"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to all resources"
  default     = {}
}

variable "unseal_keys" {
  type        = list(string)
  description = "List of 3 Vault Unseal keys"
}

variable "enable_vault_ui" {
  description = "Enables the built-in web UI, which is available on all listeners (address + port) at the /ui path. (Vault Enterprise, or Vault OSS 0.10+) Browsers accessing the standard Vault API address will automatically redirect there."
  default     = true
}

variable "vpc_id" {
}

variable "initialize" {
  type        = string
  default     = "false"
  description = "Runs a `vault operator init` command to initialize the Vault backend.  Run this once and then extract the unseal keys from the ECS task's logs."
}

variable "access_logs_enabled" {
  default = true
}
