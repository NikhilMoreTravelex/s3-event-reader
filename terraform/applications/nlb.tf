resource "aws_lb" "rds" {
  name                             = "${local.app_env}-${var.app_parent}-${var.app_name}-rds"
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = ["${module.network_ireland.private_app_subnets}"]
  enable_cross_zone_load_balancing = "true"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.app_env}-${var.app_parent}-${var.app_name}-server"
    )
  )}"

}


resource "aws_lb_target_group" "rds" {
  name        = "${local.app_env}-${var.app_parent}-${var.app_name}-rds"
  port        = 1433
  protocol    = "TCP"
  vpc_id      = "${module.network_ireland.vpc_id}"
  target_type = "ip"

  # Ensure the NLB exists before things start referencing this target group.
  depends_on = ["aws_lb.rds"]

  # The amount time for the NLB to wait before changing the state of a
  # deregistering target from draining to unused. Default is 300 seconds.
  deregistration_delay = 90

  #  # Enable/Disable sending Proxy Protocol V2 headers
  #  # https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt
  #  proxy_protocol_v2 = "${var.enable_proxy_protocol_v2}"
  #  health_check {
  #    protocol = "${var.health_check_protocol}"
  #    port     = "${var.health_check_port}"
  #    path     = "${var.health_check_protocol == "HTTP" || var.health_check_protocol == "HTTPS" ? var.health_check_path : ""}"
  #  }

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.app_env}-${var.app_parent}-${var.app_name}-server"
    )
  )}"
}


resource "aws_lb_listener" "rds" {
  load_balancer_arn = "${aws_lb.rds.id}"
  port              = 1433
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.rds.id}"
    type             = "forward"
  }
}
/*
resource "aws_lb_target_group_attachment" "rds" {
  target_group_arn = "${aws_lb_target_group.rds.arn}"
  target_id        = "${module.rts_db_ireland.db_instance_address}"
  port             = 1433
  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${local.app_env}-${var.app_parent}-${var.app_name}-tg-attachment"
    )
  )}"
}
*/

#489510786593 for data account where endpoint is created
resource "aws_vpc_endpoint_service" "rds" {
  acceptance_required        = false
  network_load_balancer_arns = ["${aws_lb.rds.arn}"]
  allowed_principals         = ["arn:aws:iam::489510786593:root"]
  depends_on                 = ["aws_lb.rds"]
}


