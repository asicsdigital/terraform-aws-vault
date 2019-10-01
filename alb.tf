# Create a new load balancer

locals {
  enable_custom_domain = var.dns_zone == "" ? false : true
  custom_endpoint      = "${coalesce(var.hostname, "vault")}.${var.dns_zone}"
  vault_url_protocol   = local.enable_custom_domain ? "https" : "http"
  vault_url_hostname   = local.enable_custom_domain ? local.custom_endpoint : aws_alb.vault.dns_name
  vault_url            = "${local.vault_url_protocol}://${local.vault_url_hostname}"
}

resource "aws_alb" "vault" {
  name_prefix     = "vault-"
  security_groups = [aws_security_group.lb-vault-sg.id]
  internal        = false
  subnets         = var.subnets

  tags = {
    Environment = var.env
    VPC         = local.vpc_name
  }

  access_logs {
    bucket = var.alb_log_bucket
    prefix = "logs/elb/${local.vpc_name}/vault"
  }
}

# DNS Alias for the LB
resource "aws_route53_record" "vault" {
  count   = local.enable_custom_domain ? 1 : 0
  zone_id = data.aws_route53_zone.zone[0].zone_id
  name    = "${coalesce(var.hostname, "vault")}.${data.aws_route53_zone.zone[0].name}"
  type    = "A"

  alias {
    name                   = aws_alb.vault.dns_name
    zone_id                = aws_alb.vault.zone_id
    evaluate_target_health = false
  }
}

# Create a new target group
resource "aws_alb_target_group" "vault_ui" {
  port                 = 8200
  protocol             = "HTTP"
  deregistration_delay = var.lb_deregistration_delay
  vpc_id               = data.aws_vpc.vpc.id

  health_check {
    path    = "/v1/sys/health?standbyok=true"
    matcher = "200"
  }

  stickiness {
    type    = "lb_cookie"
    enabled = true
  }

  tags = {
    Environment = var.env
    VPC         = local.vpc_name
  }
}

# Create a new alb listener
resource "aws_alb_listener" "vault_https" {
  count             = local.enable_custom_domain ? 1 : 0
  load_balancer_arn = aws_alb.vault.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = data.aws_acm_certificate.cert[0].arn # edit needed

  default_action {
    target_group_arn = aws_alb_target_group.vault_ui.arn
    type             = "forward"
  }
}

resource "aws_alb_listener" "vault_http" {
  count             = local.enable_custom_domain ? 0 : 1
  load_balancer_arn = aws_alb.vault.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.vault_ui.arn
    type             = "forward"
  }
}

