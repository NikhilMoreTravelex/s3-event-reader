data "aws_route53_zone" "root" {
  name = "${var.app_name}.${local.dns_roots[var.target_infra]}."
}

resource "aws_route53_zone" "primary" {
  name = "${local.app_env}.${var.app_name}.${local.dns_roots[var.target_infra]}"

  tags = "${merge(
    local.common_tags,
      map(
          "Name", "${local.app_env}-${var.app_name}-zone"
        )
    )}"
}

resource "aws_route53_record" "primary_ns" {
  zone_id = "${data.aws_route53_zone.root.zone_id}"
  name    = "${local.app_env}.${var.app_name}.${local.dns_roots[var.target_infra]}"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.primary.name_servers.0}",
    "${aws_route53_zone.primary.name_servers.1}",
    "${aws_route53_zone.primary.name_servers.2}",
    "${aws_route53_zone.primary.name_servers.3}",
  ]
}
/*

resource "aws_route53_record" "region_ns" {
  count   = "${length(local.regions)}"
  zone_id = "${data.aws_route53_zone.root.zone_id}"
  name    = "${element(local.regions, count.index)}.${var.app_name}.${local.dns_roots[var.target_infra]}"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.regions.*.name_servers.0[count.index]}",
    "${aws_route53_zone.regions.*.name_servers.1[count.index]}",
    "${aws_route53_zone.regions.*.name_servers.2[count.index]}",
    "${aws_route53_zone.regions.*.name_servers.3[count.index]}",
  ]

  depends_on = ["aws_route53_zone.regions"]
}



*/


resource "aws_route53_record" "cnames" {
  zone_id = "${aws_route53_zone.primary.zone_id}"                                                                           # Replace with your zone ID
  name    = "${local.service_name}.${local.app_env}.${var.app_name}.${local.dns_roots[var.target_infra]}" # Replace with your name/domain/subdomain
  type    = "A"

  alias {
    name                   = "${local.dns_records_cname[local.service_name]}"
    zone_id                = "${module.alb_irland.zone_id}"
    evaluate_target_health = true
  }

#  depends_on = ["aws_lb.alb"] check how to pass module here
}


/*needs to be added argos
resource "aws_route53_record" "a_record" {
  zone_id = "${aws_route53_zone.subdomain.1.zone_id}"
  name    = "${local.new_service_name}.${local.app_env}.${element(local.regions, 1)}.${var.app_parent}-${var.app_name}.${local.dns_roots[var.target_infra]}"
  type    = "A"

  alias {
    name                   = "${module.alb_irland.dns_name}"
    zone_id                = "${module.alb_irland.zone_id}"
    evaluate_target_health = true
  }
}
*/
