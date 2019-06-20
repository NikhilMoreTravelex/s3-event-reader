#Below module will create certificate for web.{env}.{application}.tvx-test.cloud


module "web_cert_ireland" {
  source            = "git::github.com/travelex/it-infra-modules.git//terraform_modules/acm?ref=v1.1"
  domain_name       = "${local.service_name}.${local.app_env}.${var.app_name}.${local.dns_roots[var.target_infra]}"
  validation_method = "DNS"
  r53_zone_id       = "${aws_route53_zone.primary.zone_id}"

  common_tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.service_name}.${local.app_env}.${var.app_name}.${local.dns_roots[var.target_infra]}-certificate")
  )}"
}

