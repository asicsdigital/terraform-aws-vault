output "public_endpoint" {
  value = "${aws_route53_record.vault.fqdn}"
}
