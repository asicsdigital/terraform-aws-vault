variable "alb_log_bucket" {
  description = "s3 bucket to send ALB Logs"
}

variable "vault_image" {
  description = "Image to use when deploying vault, defaults to the hashicorp vault image"
  default     = "vault:latest"
}

variable "desired_count" {
  description = "Number of vaults that ECS should run."
  default     = "2"
}

variable "dns_zone" {
  description = "Zone where the Consul UI alb will be created. This should *not* be consul.example.com"
}

variable "ecs_cluster_id" {
  description = "ARN of the ECS ID"
}

variable "env" {}

variable "hostname" {
  description = "DNS Hostname for the bastion host. Defaults to ${VPC NAME}.${dns_zone} if hostname is not set"
  default     = ""
}

variable "iam_path" {
  default     = "/"
  description = "IAM path, this is useful when creating resources with the same name across multiple regions. Defaults to /"
}

variable "subnets" {
  type        = "list"
  description = "List of subnets used to deploy the Consul alb"
}

variable "region" {
  default     = "us-east-1"
  description = "AWS Region, defaults to us-east-1"
}

variable "unseal_key" {
  description = "Vault Unseal key"
}

variable "vpc_id" {}
