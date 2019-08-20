resource "aws_route53_record" "dns_record" {
  count = var.dns_config != null ? count(local.dns_record_types) : 0

  name    = var.dns_config.record_name
  zone_id = var.dns_config.hosted_zone_name
  type    = local.dns_record_types[count.index]

  alias {
    evaluate_target_health = true
    name                   = aws_lb.bastion.dns_name
    zone_id                = aws_lb.bastion.zone_id
  }
}
