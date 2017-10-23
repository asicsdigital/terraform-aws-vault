output "public_endpoint" {
  value = "${aws_route53_record.vault.fqdn}"
}

output "public_url" {
  value = "https://${aws_route53_record.vault.fqdn}"
}
